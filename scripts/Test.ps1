[CmdletBinding()]
param([switch]$SkipPester)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$sourceFiles = @(Get-ChildItem -LiteralPath (Join-Path $root 'src') -Recurse -File -Filter '*.ps1')
$sourceFiles += Get-ChildItem -LiteralPath (Join-Path $root 'src\modules') -File -Filter '*.psm1'
$sourceFiles += Get-ChildItem -LiteralPath (Join-Path $root 'installer') -File -Filter '*.ps1'
$sourceFiles += Get-ChildItem -LiteralPath (Join-Path $root 'scripts') -File -Filter '*.ps1'
foreach ($file in $sourceFiles) {
    $tokens = $null; $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)
    if ($errors.Count -gt 0) { throw "PowerShell 语法错误：$($file.FullName) - $($errors[0].Message)" }
}
& node --check (Join-Path $root 'src\proxy-server.js')
if ($LASTEXITCODE -ne 0) { throw 'proxy-server.js 静态检查失败。' }
if (-not $SkipPester) {
    $pester = Get-Module -ListAvailable Pester | Sort-Object Version -Descending | Select-Object -First 1
    if (-not $pester) { throw '未检测到 Pester，无法执行自动化测试。' }
    Import-Module $pester.Path -Force
    $result = Invoke-Pester -Path (Join-Path $root 'tests') -PassThru
    if ($result.FailedCount -gt 0) { throw "Pester 测试失败：$($result.FailedCount) 项。" }
}
Write-Host '静态检查和自动化测试通过。' -ForegroundColor Green
