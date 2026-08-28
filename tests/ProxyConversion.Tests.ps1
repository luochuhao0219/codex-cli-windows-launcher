$root = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $root 'src\modules\ProxyConversion.psm1') -Force
Describe 'Loopback conversion port selection' {
    It 'returns a bindable local port' {
        $port = Get-FreeLoopbackPort -StartPort 18080 -Attempts 5
        $port | Should BeGreaterThan 0
        ($port -le 18084) | Should Be $true
    }
}
