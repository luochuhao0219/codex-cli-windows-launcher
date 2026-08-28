$root = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $root 'src\modules\ProxyDetection.psm1') -Force
Describe 'ProxyServer parsing' {
    It 'parses SOCKS with dynamic port' {
        $proxy = @(ConvertFrom-ProxyServerString ' socks=127.0.0.1:1089 ')
        $proxy.Count | Should Be 1
        $proxy[0].Protocol | Should Be 'socks5'
        $proxy[0].Port | Should Be 1089
    }
    It 'parses mixed protocols in any order' {
        $proxy = @(ConvertFrom-ProxyServerString ' HTTPS = proxy.example:8443 ; socks5=localhost:1080; http=proxy.example:8080 ')
        $proxy.Count | Should Be 3
        $proxy[0].Protocol | Should Be 'https'
        $proxy[2].Protocol | Should Be 'http'
    }
    It 'treats a bare endpoint as HTTP' {
        $proxy = @(ConvertFrom-ProxyServerString 'host.local:3128')
        $proxy[0].Protocol | Should Be 'http'
        $proxy[0].Host | Should Be 'host.local'
    }
    It 'rejects invalid ports' { @(ConvertFrom-ProxyServerString 'socks=127.0.0.1:70000').Count | Should Be 0 }
}
