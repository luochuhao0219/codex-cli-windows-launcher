[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$runtimeRoot = $PSScriptRoot
Import-Module (Join-Path $runtimeRoot 'modules\Logging.psm1') -Force
Import-Module (Join-Path $runtimeRoot 'modules\EnvironmentCheck.psm1') -Force
Import-Module (Join-Path $runtimeRoot 'modules\ProxyDetection.psm1') -Force
Import-Module (Join-Path $runtimeRoot 'modules\ProxyConversion.psm1') -Force
Import-Module (Join-Path $runtimeRoot 'modules\ProxyProcess.psm1') -Force
Import-Module (Join-Path $runtimeRoot 'modules\ProjectSelector.psm1') -Force

$createdProxyRecord = $null
$originalLocation = Get-Location
try {
    $logPath = Initialize-CodexLauncherLog
    Write-LauncherLog "Codex Launcher version $(Get-Content (Join-Path $runtimeRoot 'VERSION') -Raw). Starting."
    $environment = Test-CodexLauncherEnvironment -RuntimeRoot $runtimeRoot
    # PowerShell unwraps an empty array returned from a function to $null.
    # Preserve an array so the following Count check works under StrictMode.
    $problems = @(Get-EnvironmentProblems $environment -SkipCodex)
    if ($problems.Count -gt 0) {
        $problems | ForEach-Object { Write-Host $_ -ForegroundColor Red; Write-LauncherLog $_ 'ERROR' }
        throw '启动前环境检查失败。'
    }
    $defaultProjects = Get-DefaultCodexProjectsPath
    New-Item -ItemType Directory -Path $defaultProjects -Force | Out-Null
    $configuration = Get-WindowsProxyConfiguration
    $endpoint = Get-PreferredProxyEndpoint $configuration
    if (-not $endpoint) { $endpoint = Read-ManualProxyEndpoint }
    $proxyUrl = $null
    if ($endpoint) {
        if (-not (Test-ProxyPort $endpoint)) { throw '检测到代理配置，但代理端口不可用。请确认 Anycast 已连接，然后重新启动。' }
        Write-LauncherLog ("Detected proxy {0}://{1}" -f $endpoint.Protocol,$endpoint.Address)
        if ($endpoint.Protocol -eq 'socks5') {
            $conversion = Start-SocksToHttpProxy -SocksEndpoint $endpoint -RuntimeRoot $runtimeRoot -LogDirectory (Get-CodexLauncherLogDirectory)
            $createdProxyRecord = New-CodexLauncherProcessRecord -Process $conversion.Process -Port $conversion.Port -LogPath $logPath
            Save-CodexLauncherProcessRecord $createdProxyRecord | Out-Null
            $proxyUrl = $conversion.Url
            if (-not (Test-HttpProxyConnectivity -ProxyUrl $proxyUrl)) { throw '本地 HTTP 转换代理无法连接 auth.openai.com。请确认 Anycast 节点可用后重试。' }
            Write-LauncherLog "Started local loopback conversion proxy on $proxyUrl."
        } else {
            $proxyUrl = 'http://{0}' -f $endpoint.Address
            if (-not (Test-HttpProxyConnectivity -ProxyUrl $proxyUrl)) { throw '检测到 HTTP/HTTPS 代理，但无法连接 auth.openai.com。请确认代理可用后重试。' }
        }
    } else { Write-LauncherLog 'No proxy selected; Codex will use direct networking.' 'WARN' }
    if ($proxyUrl) { $env:HTTP_PROXY = $proxyUrl; $env:HTTPS_PROXY = $proxyUrl; $env:NO_PROXY = 'localhost,127.0.0.1' }
    if (-not $environment.Codex) {
        [void](Install-CodexCli)
        $environment = Test-CodexLauncherEnvironment -RuntimeRoot $runtimeRoot
    }
    $problems = @(Get-EnvironmentProblems $environment)
    if ($problems.Count -gt 0) {
        $problems | ForEach-Object { Write-Host $_ -ForegroundColor Red; Write-LauncherLog $_ 'ERROR' }
        throw '启动前环境检查失败。'
    }
    if ($environment.LoginChecked -and -not $environment.LoggedIn) {
        Write-Host '未能确认 Codex CLI 登录状态。首次使用时请按 Codex 提示完成登录。' -ForegroundColor Yellow
        Write-LauncherLog 'Codex login status was not confirmed.' 'WARN'
    }
    $launchMode = Select-CodexLaunchMode
    $codex = (Get-Command 'codex.cmd' -ErrorAction Stop).Source
    if ($launchMode -eq 'Resume') {
        Write-LauncherLog 'Opening Codex history session picker.'
        & $codex resume
    } else {
        $projectDirectory = Select-CodexProjectDirectory -DefaultPath $defaultProjects
        Set-Location -LiteralPath $projectDirectory
        Write-LauncherLog "Launching new Codex session in project directory: $projectDirectory"
        & $codex
    }
    $exitCode = $LASTEXITCODE
    Write-LauncherLog "Codex exited with code $exitCode."
    exit $exitCode
} catch {
    $message = $_.Exception.Message
    Write-Host "`n启动失败：$message" -ForegroundColor Red
    Write-Host '请按任意键关闭窗口并查看日志。' -ForegroundColor Yellow
    try { Write-LauncherLog $message 'ERROR' } catch { }
    [void][Console]::ReadKey($true)
    exit 1
} finally {
    Set-Location $originalLocation
    if ($createdProxyRecord) {
        $cleaned = Stop-CodexLauncherProxyProcess -Record $createdProxyRecord
        try { Write-LauncherLog "Conversion proxy cleanup result: $cleaned" } catch { }
    }
}
