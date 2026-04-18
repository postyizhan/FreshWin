# FreshWin.ps1 - 入口 + 交互式菜单

#Requires -Version 5.1

# 自动提权：非管理员时以管理员身份重启自身
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]$identity
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"" -Verb RunAs
    exit
}

$ErrorActionPreference = 'Continue'
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
    $allActions = @(
        # 任务栏
        @{ Name = '[任务栏] 清空任务栏固定图标';    Fn = { Clear-TaskbarPinnedIcons }; Group = 'taskbar' },
        @{ Name = '[任务栏] 关闭虚拟桌面切换按钮';  Fn = { Disable-TaskViewButton };   Group = 'taskbar' },
        @{ Name = '[任务栏] 桌面添加"此电脑"图标';  Fn = { Add-ThisPCToDesktop };       Group = 'taskbar' },
        # 软件
        @{ Name = '[软件] winget 换中国源 (USTC)';  Fn = { Set-WingetChinaSource };     Group = 'none' },
        @{ Name = '[软件] 删除 OneDrive';            Fn = { Remove-OneDrive };           Group = 'none' },
        @{ Name = '[软件] 禁用 Copilot 自启动';      Fn = { Disable-CopilotStartup };    Group = 'none' },
        # 系统
        @{ Name = '[系统] 开启文件扩展名';                       Fn = { Enable-FileExtensions };             Group = 'explorer' },
        @{ Name = '[系统] 显示隐藏文件';                         Fn = { Enable-HiddenFiles };                Group = 'explorer' },
        @{ Name = '[系统] 开启 WSL';                             Fn = { Enable-WSL };                        Group = 'none' },
        @{ Name = '[系统] 开启 Hyper-V';                         Fn = { Enable-HyperV };                     Group = 'none' },
        @{ Name = '[系统] 设置12小时制时间格式';                 Fn = { Set-TimeFormat12H };                 Group = 'none' },
        @{ Name = '[系统] PowerShell 执行策略设为 RemoteSigned'; Fn = { Set-PSExecutionPolicy };             Group = 'none' },
        @{ Name = '[系统] 关闭右键菜单动画';                     Fn = { Disable-MenuAnimation };             Group = 'none' },
        @{ Name = '[系统] 开启长路径支持';                       Fn = { Enable-LongPaths };                  Group = 'none' },
        @{ Name = '[系统] 关闭开始菜单推荐项目';                 Fn = { Disable-StartMenuRecommendations };  Group = 'none' },
        @{ Name = '[系统] 配置 Windows Terminal 为默认终端';     Fn = { Set-WindowsTerminalDefault };        Group = 'none' },
        # 浏览器
        @{ Name = '[浏览器] Chrome 开启开发者模式';               Fn = { Set-BrowserDeveloperMode 'chrome' 'Chrome' }; Group = 'none' },
        @{ Name = '[浏览器] Edge 开启开发者模式';                 Fn = { Set-BrowserDeveloperMode 'msedge' 'Edge' };   Group = 'none' },
        @{ Name = '[浏览器] Edge 主页精简（关闭信息流/快速链接/小组件/必应热点）'; Fn = { Set-EdgeNewTabSimple };                       Group = 'none' },
        @{ Name = '[浏览器] Edge 隐藏 Copilot 侧边栏';            Fn = { Disable-EdgeCopilotSidebar };                 Group = 'none' }
    )
    $indices = Invoke-SelectMenu '一键执行全部' ($allActions | ForEach-Object { $_.Name })
    if ($null -eq $indices) { return }

    Clear-Host
    Write-Host ""
    Write-Host "  执行中..." -ForegroundColor Cyan
    Write-Host "  ──────────────────────────────" -ForegroundColor DarkGray
    $needRestartExplorer = $false
    foreach ($i in $indices) {
        & $allActions[$i].Fn
        if ($allActions[$i].Group -in 'taskbar', 'explorer') { $needRestartExplorer = $true }
    }
    if ($needRestartExplorer) {
        Write-Host ""
        Write-Host "  正在重启资源管理器..." -ForegroundColor DarkGray
        Restart-Explorer
    }
    Write-Host "  ─────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "  完成。部分设置需要重启或注销后生效。" -ForegroundColor Green
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
        '1' { Invoke-All;                              Wait-Continue }
        '2' { Invoke-TaskbarAll;                       Wait-Continue }
        '3' { Invoke-SoftwareAll;                      Wait-Continue }
        '4' { Invoke-SystemAll;                        Wait-Continue }
        '5' { Invoke-BrowserAll;                       Wait-Continue }
        '0' { Write-Host "  再见！" -ForegroundColor Cyan; Write-Host ""; exit }
        default {
            Write-Host "  无效选项，请重新输入。" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
