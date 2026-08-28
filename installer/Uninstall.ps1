[CmdletBinding()]
param([switch]$Force)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$localAppData = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { [Environment]::GetFolderPath('LocalApplicationData') }
$target = Join-Path $localAppData 'CodexLauncher'
$desktopEntry = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Codex终端版.cmd'
Write-Host "将删除程序目录：$target"
Write-Host "将删除桌面入口：$desktopEntry"
if (-not $Force) { $answer = Read-Host '确认卸载？输入 Y 继续'; if ($answer -notmatch '^[Yy]$') { Write-Host '已取消。'; exit 0 } }
try {
    $processModule = Join-Path $target 'modules\ProxyProcess.psm1'
    if (Test-Path -LiteralPath $processModule) { Import-Module $processModule -Force; Stop-RecordedCodexLauncherProxy | Out-Null }
    if (Test-Path -LiteralPath $desktopEntry) { Remove-Item -LiteralPath $desktopEntry -Force }
    if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force }
    Write-Host '卸载完成。用户项目、Codex CLI 和登录状态均未改动。' -ForegroundColor Green
} catch { Write-Host "卸载部分失败：$($_.Exception.Message)" -ForegroundColor Red; exit 1 }
