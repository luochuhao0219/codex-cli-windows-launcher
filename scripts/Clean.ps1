[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$dist = Join-Path $root 'dist'
if (Test-Path -LiteralPath $dist) { Remove-Item -LiteralPath $dist -Recurse -Force }
Get-ChildItem -LiteralPath $root -Directory -Filter '.build-*' -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
Write-Host '已清理 dist 和临时构建目录。'
