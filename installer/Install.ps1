[CmdletBinding()]
param([switch]$LaunchAfterInstall)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$packageRoot = if (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'runtime')) { $PSScriptRoot } else { Split-Path -Parent $PSScriptRoot }
$runtimeSource = Join-Path $packageRoot 'runtime'
$localAppData = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { [Environment]::GetFolderPath('LocalApplicationData') }
$target = Join-Path $localAppData 'CodexLauncher'
$desktop = [Environment]::GetFolderPath('Desktop')
$desktopEntry = Join-Path $desktop 'Codex终端版.cmd'
$backup = $null
$staging = $null

function Require-Command([string]$name, [string]$help) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) { throw $help }
}
try {
    Require-Command node '未检测到 Node.js。请先安装 Node.js LTS。'
    Require-Command 'npm.cmd' '未检测到 npm。请重新安装 Node.js LTS。'
    Require-Command 'codex.cmd' '未检测到 Codex CLI。请执行 npm.cmd install -g @openai/codex 后重试。'
    if (-not (Test-Path -LiteralPath $runtimeSource)) { throw '发行包不完整：缺少 runtime 目录。' }
    Write-Host "将安装到：$target"
    Write-Host "桌面入口：$desktopEntry"
    if (Test-Path -LiteralPath $desktopEntry) {
        $backup = "$desktopEntry.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item -LiteralPath $desktopEntry -Destination $backup -Force
    }
    $staging = "$target.staging-$PID"
    Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $staging -Force | Out-Null
    Copy-Item -Path (Join-Path $runtimeSource '*') -Destination $staging -Recurse -Force
    Push-Location $staging
    try { & npm.cmd ci --omit=dev; if ($LASTEXITCODE -ne 0) { throw 'npm ci 安装本地运行依赖失败。' } } finally { Pop-Location }
    if (Test-Path -LiteralPath $target) { Rename-Item -LiteralPath $target -NewName ('CodexLauncher.previous-{0}' -f (Get-Date -Format 'yyyyMMdd-HHmmss')) }
    Rename-Item -LiteralPath $staging -NewName 'CodexLauncher'
    $entrySource = Join-Path $packageRoot 'Codex终端版.cmd'
    if (-not (Test-Path -LiteralPath $entrySource)) { throw '发行包不完整：缺少桌面入口模板。' }
    Copy-Item -LiteralPath $entrySource -Destination $desktopEntry -Force
    New-Item -ItemType Directory -Path (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'CodexProjects') -Force | Out-Null
    if (-not (Test-Path -LiteralPath (Join-Path $target 'Start-Codex.ps1')) -or -not (Test-Path -LiteralPath $desktopEntry)) { throw '安装验证失败。' }
    Write-Host '安装完成。桌面已创建 Codex终端版.cmd。' -ForegroundColor Green
    if ($LaunchAfterInstall) { & $desktopEntry }
} catch {
    Write-Host "安装失败：$($_.Exception.Message)" -ForegroundColor Red
    if ($staging -and (Test-Path -LiteralPath $staging)) { Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue }
    if ($backup -and -not (Test-Path -LiteralPath $desktopEntry)) { Move-Item -LiteralPath $backup -Destination $desktopEntry -Force }
    exit 1
}
