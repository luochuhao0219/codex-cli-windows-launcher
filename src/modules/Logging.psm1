Set-StrictMode -Version Latest

function Get-CodexLauncherLogDirectory {
    $base = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { [Environment]::GetFolderPath('LocalApplicationData') }
    $path = Join-Path $base 'CodexLauncher\logs'
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    return $path
}

function Initialize-CodexLauncherLog {
    $path = Join-Path (Get-CodexLauncherLogDirectory) ('launcher-{0:yyyyMMdd-HHmmss}.log' -f (Get-Date))
    $script:CodexLauncherLogPath = $path
    Get-ChildItem (Split-Path $path) -Filter '*.log' -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -Skip 10 | Remove-Item -Force -ErrorAction SilentlyContinue
    return $path
}

function Write-LauncherLog {
    param([Parameter(Mandatory)][string]$Message, [ValidateSet('INFO','WARN','ERROR')][string]$Level = 'INFO')
    if (-not $script:CodexLauncherLogPath) { Initialize-CodexLauncherLog | Out-Null }
    $safe = $Message -replace '(?i)(authorization|token|api[_ -]?key|cookie|password)\\s*[:=].*', '$1=[REDACTED]'
    Add-Content -LiteralPath $script:CodexLauncherLogPath -Value ('{0:o} [{1}] {2}' -f (Get-Date), $Level, $safe) -Encoding UTF8
}

Export-ModuleMember -Function Get-CodexLauncherLogDirectory,Initialize-CodexLauncherLog,Write-LauncherLog
