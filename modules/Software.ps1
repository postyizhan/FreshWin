# Software.ps1 - 软件管理

function Set-WingetChinaSource {
    Write-Host "  正在切换 winget 源..." -ForegroundColor DarkGray
    $result = Invoke-Cmd 'winget' @('source', 'list')
    if ($result.ExitCode -ne 0) {
        Write-Status 'FAIL' 'winget 换中国源 — winget 未找到'
        return
    }
    Invoke-Cmd 'winget' @('source', 'remove', 'winget') | Out-Null
    $r = Invoke-Cmd 'winget' @('source', 'add', 'winget', 'https://mirrors.ustc.edu.cn/winget-source', '--trust-level', 'trusted')
    if ($r.ExitCode -eq 0) {
        Write-Status 'OK' 'winget 换中国源 (USTC)'
    } else {
        Write-Status 'FAIL' "winget 换中国源 — $($r.Output)"
    }
}

function Remove-OneDrive {
    Write-Host "  正在卸载 OneDrive..." -ForegroundColor DarkGray
    # 先尝试终止进程
    Stop-Process -Name OneDrive -Force -ErrorAction SilentlyContinue
    $r = Invoke-Cmd 'winget' @('uninstall', '--id', 'Microsoft.OneDrive', '--silent', '--accept-source-agreements')
    if ($r.ExitCode -eq 0) {
        Write-Status 'OK' '删除 OneDrive'
    } else {
        # 尝试内置卸载程序
        $uninstaller = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
        if (-not (Test-Path $uninstaller)) {
            $uninstaller = "$env:SystemRoot\System32\OneDriveSetup.exe"
        }
        if (Test-Path $uninstaller) {
            Start-Process $uninstaller '/uninstall' -Wait
            Write-Status 'OK' '删除 OneDrive'
        } else {
            Write-Status 'SKIP' '删除 OneDrive — 未检测到安装'
        }
    }
}

function Disable-CopilotStartup {
    $runPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
    $names = @('MicrosoftEdgeAutoLaunch*', 'Copilot', 'Microsoft Copilot')
    $removed = $false
    foreach ($name in $names) {
        $props = Get-Item -Path $runPath -ErrorAction SilentlyContinue |
                 Select-Object -ExpandProperty Property |
                 Where-Object { $_ -like $name }
        foreach ($prop in $props) {
            Remove-ItemProperty -Path $runPath -Name $prop -Force -ErrorAction SilentlyContinue
            $removed = $true
        }
    }
    if ($removed) {
        Write-Status 'OK' '禁用 Copilot 自启动'
    } else {
        Write-Status 'SKIP' '禁用 Copilot 自启动'
    }
}

function Invoke-SoftwareAll {
    $actions = @(
        @{ Name = 'winget 换中国源 (USTC)'; Fn = { Set-WingetChinaSource } },
        @{ Name = '删除 OneDrive';           Fn = { Remove-OneDrive } },
        @{ Name = '禁用 Copilot 自启动';     Fn = { Disable-CopilotStartup } }
    )
    $indices = Invoke-SelectMenu '软件管理' ($actions | ForEach-Object { $_.Name })
    if ($null -eq $indices) { return }

    Clear-Host
    Write-Host ""
    Write-Host "  软件管理" -ForegroundColor Cyan
    Write-Host "  ──────────────────────────────" -ForegroundColor DarkGray
    foreach ($i in $indices) {
        & $actions[$i].Fn
    }
    Write-Host ""
}
