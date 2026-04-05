# Taskbar.ps1 - 任务栏相关设置

function Clear-TaskbarPinnedIcons {
    $path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband'
    if (Test-Path $path) {
        Remove-Item -Path $path -Recurse -Force
        Write-Status 'OK' '清空任务栏固定图标'
    } else {
        Write-Status 'SKIP' '清空任务栏固定图标'
    }
}

function Disable-TaskViewButton {
    $current = Get-RegistryValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowTaskViewButton'
    if ($current -eq 0) {
        Write-Status 'SKIP' '关闭虚拟桌面切换按钮'
    } else {
        $r = Set-RegistryValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowTaskViewButton' 0
        if ($r -eq $true) { Write-Status 'OK' '关闭虚拟桌面切换按钮' } else { Write-Status 'FAIL' "关闭虚拟桌面切换按钮 — $r" }
    }
}

function Add-ThisPCToDesktop {
    $path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel'
    $guid = '{20D04FE0-3AEA-1069-A2D8-08002B30309D}'
    $current = Get-RegistryValue $path $guid
    if ($current -eq 0) {
        Write-Status 'SKIP' '桌面添加"此电脑"图标'
    } else {
        $r = Set-RegistryValue $path $guid 0
        if ($r -eq $true) { Write-Status 'OK' '桌面添加"此电脑"图标' } else { Write-Status 'FAIL' "桌面添加此电脑图标 — $r" }
    }
}

function Invoke-TaskbarAll {
    $actions = @(
        @{ Name = '清空任务栏固定图标';    Fn = { Clear-TaskbarPinnedIcons } },
        @{ Name = '关闭虚拟桌面切换按钮';  Fn = { Disable-TaskViewButton } },
        @{ Name = '桌面添加"此电脑"图标';  Fn = { Add-ThisPCToDesktop } }
    )
    $indices = Invoke-SelectMenu '任务栏设置' ($actions | ForEach-Object { $_.Name })
    if ($null -eq $indices) { return }

    Clear-Host
    Write-Host ""
    Write-Host "  任务栏设置" -ForegroundColor Cyan
    Write-Host "  ──────────────────────────────" -ForegroundColor DarkGray
    $needRestart = $false
    foreach ($i in $indices) {
        & $actions[$i].Fn
        $needRestart = $true
    }
    if ($needRestart -and $indices.Count -gt 0) {
        Write-Host ""
        Write-Host "  正在重启资源管理器..." -ForegroundColor DarkGray
        Restart-Explorer
    }
    Write-Host ""
}
