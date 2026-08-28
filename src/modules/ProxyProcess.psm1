Set-StrictMode -Version Latest

function New-CodexLauncherProcessRecord {
    param([Parameter(Mandatory)][System.Diagnostics.Process]$Process, [Parameter(Mandatory)][int]$Port, [Parameter(Mandatory)][string]$LogPath)
    [pscustomobject]@{ Pid = $Process.Id; Port = $Port; StartedAt = (Get-Date).ToUniversalTime().ToString('o'); LogPath = $LogPath; Marker = 'CodexLauncher proxy-server.js' }
}

function Save-CodexLauncherProcessRecord {
    param([Parameter(Mandatory)]$Record)
    $base = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { [Environment]::GetFolderPath('LocalApplicationData') }
    $path = Join-Path $base 'CodexLauncher\proxy-process.json'
    $Record | ConvertTo-Json | Set-Content -LiteralPath $path -Encoding UTF8
    return $path
}

function Stop-CodexLauncherProxyProcess {
    param([Parameter(Mandatory)]$Record, [switch]$KeepRecord)
    $stopped = $false
    try {
        $process = Get-CimInstance Win32_Process -Filter ("ProcessId = {0}" -f [int]$Record.Pid) -ErrorAction SilentlyContinue
        if ($process -and $process.Name -match 'node(\.exe)?' -and $process.CommandLine -match [regex]::Escape('proxy-server.js') -and $process.CommandLine -match [regex]::Escape("--port=$($Record.Port)")) {
            Stop-Process -Id ([int]$Record.Pid) -Force -ErrorAction Stop
            $stopped = $true
        }
    } catch { $stopped = $false }
    if (-not $KeepRecord) {
        $base = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { [Environment]::GetFolderPath('LocalApplicationData') }
        Remove-Item -LiteralPath (Join-Path $base 'CodexLauncher\proxy-process.json') -Force -ErrorAction SilentlyContinue
    }
    return $stopped
}

function Stop-RecordedCodexLauncherProxy {
    $base = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { [Environment]::GetFolderPath('LocalApplicationData') }
    $path = Join-Path $base 'CodexLauncher\proxy-process.json'
    if (-not (Test-Path -LiteralPath $path)) { return $false }
    try { $record = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json; return Stop-CodexLauncherProxyProcess -Record $record } catch { return $false }
}

Export-ModuleMember -Function New-CodexLauncherProcessRecord,Save-CodexLauncherProcessRecord,Stop-CodexLauncherProxyProcess,Stop-RecordedCodexLauncherProxy
