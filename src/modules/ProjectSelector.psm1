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

function Select-CodexLaunchMode {
    Write-Host ''
    Write-Host '请选择启动方式：' -ForegroundColor Cyan
    Write-Host '  1. 新建会话（选择工作文件夹）'
    Write-Host '  2. 恢复历史会话'
    $choice = Read-Host '输入 1 或 2（直接回车默认为 1）'
    if ($choice -eq '2') { return 'Resume' }
    if ($choice -and $choice -ne '1') { Write-Host '输入无效，已按“新建会话”启动。' -ForegroundColor Yellow }
    return 'New'
}

Export-ModuleMember -Function Get-DefaultCodexProjectsPath,Select-CodexProjectDirectory,Select-CodexLaunchMode
