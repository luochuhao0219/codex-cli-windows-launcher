Set-StrictMode -Version Latest

function Get-DefaultCodexProjectsPath {
    return (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'CodexProjects')
}

function Select-CodexProjectDirectory {
    param([string]$DefaultPath = (Get-DefaultCodexProjectsPath))
    New-Item -ItemType Directory -Force -Path $DefaultPath | Out-Null
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = '选择 Codex 要操作的项目文件夹（可新建文件夹）'
        $dialog.SelectedPath = $DefaultPath
        $dialog.ShowNewFolderButton = $true
        $result = $dialog.ShowDialog()
        if ($result -eq [System.Windows.Forms.DialogResult]::OK -and -not [string]::IsNullOrWhiteSpace($dialog.SelectedPath)) { return $dialog.SelectedPath }
    } catch { Write-Host '无法显示文件夹选择窗口，将使用默认 CodexProjects 目录。' -ForegroundColor Yellow }
    return $DefaultPath
}

Export-ModuleMember -Function Get-DefaultCodexProjectsPath,Select-CodexProjectDirectory
