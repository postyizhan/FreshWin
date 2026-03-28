# FreshWin.ps1 - 入口 + 交互式菜单

#Requires -Version 5.1

$ErrorActionPreference = 'Stop'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# 加载模块
. "$scriptRoot\utils\Common.ps1"
. "$scriptRoot\modules\Taskbar.ps1"
. "$scriptRoot\modules\Software.ps1"
. "$scriptRoot\modules\System.ps1"
. "$scriptRoot\modules\Browser.ps1"

$VERSION = '1.0.0'
$REPO    = 'https://github.com/postyizhan/FreshWin'

function Show-Banner {
    Clear-Host
    Write-Host ""
    Write-Host "   ___              _     __        ___  " -ForegroundColor Cyan
    Write-Host "  | __| _ _  ___  | |_  | |       / __|  _ _ " -ForegroundColor Cyan
    Write-Host "  | _| | '_|/ -_) |  _| | |      | (__| | ' \" -ForegroundColor Cyan
    Write-Host "  |_|  |_|  \___|  \__| |_|       \___| |_||_|" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  v$VERSION  Windows 初始化工具" -ForegroundColor White
    Write-Host "  $REPO" -ForegroundColor DarkGray
    if (Test-Admin) {
        Write-Host "  [管理员模式]" -ForegroundColor Green
    } else {
        Write-Host "  [普通模式 - 部分功能需要管理员权限]" -ForegroundColor Yellow
    }
    Write-Host "  ─────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""
}

function Show-Menu {
    Write-Host "  请选择操作：" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1] 一键执行全部"
    Write-Host "  ─────────────────" -ForegroundColor DarkGray
    Write-Host "  [2] 任务栏设置"
    Write-Host "  [3] 软件管理"
    Write-Host "  [4] 系统功能"
    Write-Host "  [5] 浏览器配置"
    Write-Host "  ─────────────────" -ForegroundColor DarkGray
    Write-Host "  [0] 退出"
    Write-Host ""
    Write-Host -NoNewline "  > "
}

function Invoke-All {
    Invoke-TaskbarAll
    Invoke-SoftwareAll
    Invoke-SystemAll
    Invoke-BrowserAll
    Write-Host "  ─────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "  全部完成。部分设置需要重启或注销后生效。" -ForegroundColor Green
    Write-Host ""
}

function Wait-Continue {
    Write-Host "  按任意键返回菜单..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}

# 主循环
while ($true) {
    Show-Banner
    Show-Menu
    $choice = Read-Host

    switch ($choice.Trim()) {
        '1' { Show-Banner; Invoke-All;         Wait-Continue }
        '2' { Show-Banner; Invoke-TaskbarAll;  Wait-Continue }
        '3' { Show-Banner; Invoke-SoftwareAll; Wait-Continue }
        '4' { Show-Banner; Invoke-SystemAll;   Wait-Continue }
        '5' { Show-Banner; Invoke-BrowserAll;  Wait-Continue }
        '0' { Write-Host "  再见！" -ForegroundColor Cyan; Write-Host ""; exit }
        default {
            Write-Host "  无效选项，请重新输入。" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
