Set-StrictMode -Version Latest

function Test-LauncherCommand {
    param([Parameter(Mandatory)][string]$Command, [string[]]$Arguments = @('--version'))
    $candidate = Get-Command $Command -ErrorAction SilentlyContinue
    if (-not $candidate) { return [pscustomobject]@{ Available = $false; Output = '' } }
    try {
        $output = & $candidate.Source @Arguments 2>&1 | Out-String
        return [pscustomobject]@{ Available = ($LASTEXITCODE -eq 0); Output = $output.Trim() }
    } catch { return [pscustomobject]@{ Available = $false; Output = $_.Exception.Message } }
}

function Test-CodexLauncherEnvironment {
    param([Parameter(Mandatory)][string]$RuntimeRoot, [switch]$SkipLoginCheck)
    $node = Test-LauncherCommand node @('-v')
    $npm = Test-LauncherCommand 'npm.cmd' @('-v')
    $codex = Test-LauncherCommand 'codex.cmd' @('--version')
    $dependency = Test-Path -LiteralPath (Join-Path $RuntimeRoot 'node_modules\proxy-chain\dist\index.js')
    $projectRoot = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'CodexProjects'
    $login = $null
    if (-not $SkipLoginCheck -and $codex.Available) { $login = Test-LauncherCommand 'codex.cmd' @('login','status') }
    [pscustomobject]@{
        PowerShell = $PSVersionTable.PSVersion.Major -ge 5
        Node = $node.Available; NodeOutput = $node.Output
        Npm = $npm.Available; NpmOutput = $npm.Output
        Codex = $codex.Available; CodexOutput = $codex.Output
        LocalDependency = $dependency
        ProjectRoot = $projectRoot
        LoginChecked = ($null -ne $login); LoggedIn = if ($null -eq $login) { $null } else { $login.Available }
    }
}

function Get-EnvironmentProblems {
    param([Parameter(Mandatory)]$Check)
    $problems = @()
    if (-not $Check.PowerShell) { $problems += '未检测到 Windows PowerShell 5.1 或更高版本。' }
    if (-not $Check.Node) { $problems += '未检测到 Node.js。请先安装 Node.js LTS，然后重新运行启动器。' }
    if (-not $Check.Npm) { $problems += '未检测到 npm。请重新安装 Node.js LTS，然后重试。' }
    if (-not $Check.Codex) { $problems += '未检测到 Codex CLI。请执行 npm.cmd install -g @openai/codex 后重试。' }
    if (-not $Check.LocalDependency) { $problems += '本地 proxy-chain 依赖不完整。请重新运行安装程序。' }
    return $problems
}

Export-ModuleMember -Function Test-LauncherCommand,Test-CodexLauncherEnvironment,Get-EnvironmentProblems
