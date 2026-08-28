Set-StrictMode -Version Latest

function Get-FreeLoopbackPort {
    param([int]$StartPort = 8080, [int]$Attempts = 20)
    for ($port = $StartPort; $port -lt ($StartPort + $Attempts); $port++) {
        $listener = $null
        try {
            $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Parse('127.0.0.1'), $port)
            $listener.Start(); return $port
        } catch { } finally { if ($listener) { $listener.Stop() } }
    }
    throw "无法在 127.0.0.1:$StartPort 起找到可用的本地转换端口。"
}

function Start-SocksToHttpProxy {
    param([Parameter(Mandatory)]$SocksEndpoint, [Parameter(Mandatory)][string]$RuntimeRoot, [Parameter(Mandatory)][string]$LogDirectory)
    $node = (Get-Command node -ErrorAction Stop).Source
    $scriptPath = Join-Path $RuntimeRoot 'proxy-server.js'
    if (-not (Test-Path -LiteralPath $scriptPath)) { throw '缺少 proxy-server.js。请重新安装启动器。' }
    $port = Get-FreeLoopbackPort
    $upstream = 'socks5://{0}:{1}' -f $SocksEndpoint.Host, $SocksEndpoint.Port
    $outLog = Join-Path $LogDirectory ('proxy-{0}.out.log' -f $port)
    $errLog = Join-Path $LogDirectory ('proxy-{0}.err.log' -f $port)
    $args = @(('"{0}"' -f $scriptPath), "--port=$port", "--upstream=$upstream")
    $process = Start-Process -FilePath $node -ArgumentList $args -WorkingDirectory $RuntimeRoot -RedirectStandardOutput $outLog -RedirectStandardError $errLog -WindowStyle Hidden -PassThru
    $deadline = (Get-Date).AddSeconds(8)
    do { Start-Sleep -Milliseconds 150; $ready = Test-NetConnection -ComputerName '127.0.0.1' -Port $port -InformationLevel Quiet -WarningAction SilentlyContinue } while (-not $ready -and (Get-Date) -lt $deadline -and -not $process.HasExited)
    if (-not $ready) { if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force }; throw "SOCKS5 转 HTTP 代理未能在 127.0.0.1:$port 启动。" }
    return [pscustomobject]@{ Process = $process; Host = '127.0.0.1'; Port = $port; Url = "http://127.0.0.1:$port"; Upstream = $upstream }
}

function Test-HttpProxyConnectivity {
    param([Parameter(Mandatory)][string]$ProxyUrl, [int]$TimeoutSeconds = 20)
    try {
        $response = Invoke-WebRequest -Uri 'https://auth.openai.com' -Proxy $ProxyUrl -UseBasicParsing -TimeoutSec $TimeoutSeconds -MaximumRedirection 0 -ErrorAction Stop
        return @('200','302','401','403') -contains [string][int]$response.StatusCode
    } catch {
        $webResponse = $_.Exception.Response
        if ($webResponse -and $webResponse.StatusCode) { return @('200','302','401','403') -contains [string][int]$webResponse.StatusCode }
        return $false
    }
}

Export-ModuleMember -Function Get-FreeLoopbackPort,Start-SocksToHttpProxy,Test-HttpProxyConnectivity
