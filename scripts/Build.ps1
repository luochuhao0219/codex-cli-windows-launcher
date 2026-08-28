[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$dist = Join-Path $root 'dist'
$staging = Join-Path $root ('.build-' + [guid]::NewGuid().ToString('N'))
try {
    if ($env:OS -ne 'Windows_NT') { throw '此发行包只能在 Windows 上构建。' }
    $version = (Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim()
    if ($version -notmatch '^\d+\.\d+\.\d+$') { throw 'VERSION 必须为语义化版本号。' }
    foreach ($required in @('src\Start-Codex.ps1','src\proxy-server.js','src\modules\ProxyDetection.psm1','installer\Install.ps1','entry\Codex终端版.cmd.template','package.json','package-lock.json','LICENSE','README.md')) {
        if (-not (Test-Path -LiteralPath (Join-Path $root $required))) { throw "缺少必要文件：$required" }
    }
    Push-Location $root
    try {
        & npm.cmd ci
        if ($LASTEXITCODE -ne 0) { throw 'npm ci 失败。' }
        & npm.cmd audit --omit=dev
        if ($LASTEXITCODE -ne 0) { Write-Warning 'npm audit 报告了依赖问题；构建继续，请在发布前审查报告。' }
    } finally { Pop-Location }
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts\Test.ps1')
    if ($LASTEXITCODE -ne 0) { throw '自动化测试失败，已停止构建。' }
    $releaseName = "CodexLauncher-v$version"
    $release = Join-Path $staging $releaseName
    $runtime = Join-Path $release 'runtime'
    New-Item -ItemType Directory -Path $runtime -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $root 'src\Start-Codex.ps1') -Destination $runtime
    Copy-Item -LiteralPath (Join-Path $root 'src\proxy-server.js') -Destination $runtime
    Copy-Item -LiteralPath (Join-Path $root 'src\modules') -Destination $runtime -Recurse
    foreach ($file in @('package.json','package-lock.json','VERSION')) { Copy-Item -LiteralPath (Join-Path $root $file) -Destination $runtime }
    Copy-Item -LiteralPath (Join-Path $root 'installer\Install.cmd') -Destination $release
    Copy-Item -LiteralPath (Join-Path $root 'installer\Install.ps1') -Destination $release
    Copy-Item -LiteralPath (Join-Path $root 'installer\Uninstall.cmd') -Destination $release
    Copy-Item -LiteralPath (Join-Path $root 'installer\Uninstall.ps1') -Destination $release
    Copy-Item -LiteralPath (Join-Path $root 'entry\Codex终端版.cmd.template') -Destination (Join-Path $release 'Codex终端版.cmd')
    Copy-Item -LiteralPath (Join-Path $root 'LICENSE') -Destination $release
    Get-Content -LiteralPath (Join-Path $root 'README.zh-CN.md') | Set-Content -LiteralPath (Join-Path $release 'README.txt') -Encoding UTF8
    $thirdParty = Join-Path $root 'node_modules\proxy-chain\LICENSE'
    if (Test-Path -LiteralPath $thirdParty) { Get-Content $thirdParty | Set-Content -LiteralPath (Join-Path $release 'THIRD_PARTY_LICENSES.txt') -Encoding UTF8 } else { 'proxy-chain：请参阅其 npm 包中的许可证信息。' | Set-Content (Join-Path $release 'THIRD_PARTY_LICENSES.txt') -Encoding UTF8 }
    if (Test-Path -LiteralPath $dist) { Remove-Item -LiteralPath $dist -Recurse -Force }
    New-Item -ItemType Directory -Path $dist -Force | Out-Null
    Move-Item -LiteralPath $release -Destination $dist
    $zip = Join-Path $dist "$releaseName.zip"
    Compress-Archive -LiteralPath (Join-Path $dist $releaseName) -DestinationPath $zip -Force
    $hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
    "SHA256  $releaseName.zip  $hash" | Set-Content -LiteralPath (Join-Path $dist "$releaseName.sha256") -Encoding ASCII
    Write-Host "构建成功：$zip" -ForegroundColor Green
    Write-Host "SHA-256：$hash"
} catch {
    if (Test-Path -LiteralPath $dist) { Remove-Item -LiteralPath $dist -Recurse -Force -ErrorAction SilentlyContinue }
    Write-Error "构建失败：$($_.Exception.Message)"
    exit 1
} finally { if (Test-Path -LiteralPath $staging) { Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue } }
