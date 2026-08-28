$root = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $root 'src\modules\EnvironmentCheck.psm1') -Force
Describe 'Environment guidance' {
    It 'reports missing Node with Chinese guidance' {
        $check = [pscustomobject]@{ PowerShell=$true; Node=$false; Npm=$true; Codex=$true; LocalDependency=$true }
        (Get-EnvironmentProblems $check) | Should Match 'Node.js'
    }
    It 'reports missing local dependency' {
        $check = [pscustomobject]@{ PowerShell=$true; Node=$true; Npm=$true; Codex=$true; LocalDependency=$false }
        (Get-EnvironmentProblems $check) | Should Match 'proxy-chain'
    }
    It 'can defer the Codex CLI requirement during bootstrap' {
        $check = [pscustomobject]@{ PowerShell = $true; Node = $true; Npm = $true; Codex = $false; LocalDependency = $true }
        @(Get-EnvironmentProblems $check -SkipCodex).Count | Should Be 0
    }
}
