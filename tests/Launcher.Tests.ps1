$root = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $root 'src\modules\ProjectSelector.psm1') -Force
Import-Module (Join-Path $root 'src\modules\ProxyProcess.psm1') -Force
Describe 'Launcher support functions' {
    It 'builds a redirected Documents default project path' {
        $path = Get-DefaultCodexProjectsPath
        $path | Should Match 'CodexProjects$'
    }
    It 'stores only PID and process marker in a record' {
        $process = Get-Process -Id $PID
        $record = New-CodexLauncherProcessRecord -Process $process -Port 18080 -LogPath 'C:\test.log'
        $record.Pid | Should Be $PID
        $record.Marker | Should Match 'proxy-server'
    }
}
