Set-StrictMode -Version Latest

function ConvertTo-ProxyEndpoint {
    param([Parameter(Mandatory)][string]$Value, [Parameter(Mandatory)][string]$Protocol)
    $text = $Value.Trim() -replace '^\\w+://', ''
    if ($text -notmatch '^(?<host>\[[^\]]+\]|[^:;\s]+):(?<port>\d{1,5})$') { return $null }
    $port = [int]$Matches.port
    if ($port -lt 1 -or $port -gt 65535) { return $null }
    [pscustomobject]@{ Protocol = $Protocol.ToLowerInvariant(); Host = $Matches.host; Port = $port; Address = $text }
}

function ConvertFrom-ProxyServerString {
    param([AllowEmptyString()][string]$ProxyServer)
    $result = @()
    if ([string]::IsNullOrWhiteSpace($ProxyServer)) { return $result }
    $parts = $ProxyServer -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    foreach ($part in $parts) {
        if ($part -match '^(?<scheme>https?|socks5?|socks)\s*=\s*(?<value>.+)$') {
            $protocol = $Matches.scheme.ToLowerInvariant()
            if ($protocol -eq 'socks') { $protocol = 'socks5' }
            $endpoint = ConvertTo-ProxyEndpoint -Value $Matches.value -Protocol $protocol
        } else { $endpoint = ConvertTo-ProxyEndpoint -Value $part -Protocol 'http' }
        if ($endpoint) { $result += $endpoint }
    }
    return $result
}

function Get-WindowsProxyConfiguration {
    $settings = Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -ErrorAction SilentlyContinue
    $enabled = $settings -and $settings.PSObject.Properties['ProxyEnable'] -and [int]$settings.ProxyEnable -eq 1
    $proxyServer = if ($settings -and $settings.PSObject.Properties['ProxyServer']) { [string]$settings.ProxyServer } else { '' }
    $autoConfigUrl = if ($settings -and $settings.PSObject.Properties['AutoConfigURL']) { [string]$settings.AutoConfigURL } else { '' }
    $endpoints = if ($enabled) { ConvertFrom-ProxyServerString $proxyServer } else { @() }
    $winHttp = (& netsh winhttp show proxy 2>$null | Out-String).Trim()
    [pscustomobject]@{ ProxyEnabled = [bool]$enabled; ProxyServer = $proxyServer; AutoConfigURL = $autoConfigUrl; Endpoints = @($endpoints); WinHttp = $winHttp }
}

function Get-PreferredProxyEndpoint {
    param([Parameter(Mandatory)]$Configuration)
    $http = @($Configuration.Endpoints | Where-Object { $_.Protocol -in @('http','https') })
    if ($http.Count -gt 0) { return $http[0] }
    $socks = @($Configuration.Endpoints | Where-Object { $_.Protocol -eq 'socks5' })
    if ($socks.Count -gt 0) { return $socks[0] }
    return $null
}

function Test-ProxyPort {
    param([Parameter(Mandatory)]$Endpoint, [int]$TimeoutMilliseconds = 2500)
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $task = $client.ConnectAsync($Endpoint.Host.Trim('[',']'), $Endpoint.Port)
        if (-not $task.Wait($TimeoutMilliseconds)) { $client.Dispose(); return $false }
        $client.Dispose(); return $true
    } catch { return $false }
}

function Read-ManualProxyEndpoint {
    Write-Host '未能自动读取有效代理。仅本次运行可手动指定代理。'
    $type = Read-Host '代理类型 [HTTP/HTTPS/SOCKS5/NONE]'
    if ([string]::IsNullOrWhiteSpace($type) -or $type -match '^(none|n|不使用)$') { return $null }
    $hostName = Read-Host '代理地址'
    $port = Read-Host '代理端口'
    $protocol = $type.Trim().ToLowerInvariant(); if ($protocol -eq 'socks') { $protocol = 'socks5' }
    return ConvertTo-ProxyEndpoint -Value ("{0}:{1}" -f $hostName,$port) -Protocol $protocol
}

Export-ModuleMember -Function ConvertFrom-ProxyServerString,Get-WindowsProxyConfiguration,Get-PreferredProxyEndpoint,Test-ProxyPort,Read-ManualProxyEndpoint
