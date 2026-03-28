# Browser.ps1 - 浏览器配置

function Get-BrowserPrefsPath {
    param([string]$Browser)
    switch ($Browser) {
        'chrome'  { return "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Preferences" }
        'msedge'  { return "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Preferences" }
        'edge'    { return "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Preferences" }
    }
}

function Stop-BrowserProcesses {
    param([string]$ProcessName, [string]$DisplayName)
    $procs = Get-Process $ProcessName -ErrorAction SilentlyContinue
    if ($procs) {
        Write-Host "  正在关闭 $DisplayName 进程..." -ForegroundColor DarkGray
        $procs | Stop-Process -Force
        Start-Sleep -Milliseconds 800
    }
}

function Set-BrowserDeveloperMode {
    param([string]$Browser, [string]$DisplayName)
    $prefsPath = Get-BrowserPrefsPath $Browser
    if (-not (Test-Path $prefsPath)) {
        Write-Status 'SKIP' "$DisplayName 开启开发者模式 — 未检测到安装"
        return
    }
    Stop-BrowserProcesses $Browser $DisplayName
    try {
        $prefs = Get-Content $prefsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($prefs.extensions.ui.developer_mode -eq $true) {
            Write-Status 'SKIP' "$DisplayName 开启开发者模式"
            return
        }
        if (-not $prefs.extensions) { $prefs | Add-Member -NotePropertyName 'extensions' -NotePropertyValue ([PSCustomObject]@{}) }
        if (-not $prefs.extensions.ui) { $prefs.extensions | Add-Member -NotePropertyName 'ui' -NotePropertyValue ([PSCustomObject]@{}) }
        $prefs.extensions.ui | Add-Member -NotePropertyName 'developer_mode' -NotePropertyValue $true -Force
        $prefs | ConvertTo-Json -Depth 100 | Set-Content $prefsPath -Encoding UTF8
        Write-Status 'OK' "$DisplayName 开启开发者模式"
    } catch {
        Write-Status 'FAIL' "$DisplayName 开启开发者模式 — $($_.Exception.Message)"
    }
}

function Set-EdgeNewTabSimple {
    if (-not (Test-Admin)) {
        Write-Status 'FAIL' 'Edge 主页精简 — 需要管理员权限'
        return
    }
    $policyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
    $r1 = Set-RegistryValue $policyPath 'NewTabPageContentEnabled'         0
    $r2 = Set-RegistryValue $policyPath 'NewTabPageQuickLinksEnabled'      0
    $r3 = Set-RegistryValue $policyPath 'NewTabPageHideDefaultTopSites'    1
    $r4 = Set-RegistryValue $policyPath 'NewTabPageAllowedBackgroundTypes' 3
    if ($r1 -ne $true -or $r2 -ne $true -or $r3 -ne $true -or $r4 -ne $true) {
        Write-Status 'FAIL' "Edge 主页精简 — $r1 $r2 $r3 $r4"
        return
    }

    # 修改 Preferences JSON，先强制关闭 Edge
    $prefsPath = Get-BrowserPrefsPath 'msedge'
    if (Test-Path $prefsPath) {
        Stop-BrowserProcesses 'msedge' 'Edge'
        try {
            $prefs = Get-Content $prefsPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if (-not $prefs.ntp) { $prefs | Add-Member -NotePropertyName 'ntp' -NotePropertyValue ([PSCustomObject]@{}) }
            $prefs.ntp | Add-Member -NotePropertyName 'show_content'     -NotePropertyValue $false -Force
            $prefs.ntp | Add-Member -NotePropertyName 'show_quick_links' -NotePropertyValue $false -Force
            $prefs.ntp | Add-Member -NotePropertyName 'show_cards'       -NotePropertyValue $false -Force
            $prefs | ConvertTo-Json -Depth 100 | Set-Content $prefsPath -Encoding UTF8
        } catch { <# 策略注册表已生效，JSON 失败不影响 #> }
    }
    Write-Status 'OK' 'Edge 主页精简（关闭信息流/快速链接/小组件/网站导航）'
}

function Disable-EdgeCopilotSidebar {
    if (-not (Test-Admin)) {
        Write-Status 'FAIL' 'Edge 隐藏 Copilot 侧边栏 — 需要管理员权限'
        return
    }
    $policyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
    $current = Get-RegistryValue $policyPath 'HubsSidebarEnabled'
    if ($current -eq 0) {
        Write-Status 'SKIP' 'Edge 隐藏 Copilot 侧边栏'
    } else {
        $r = Set-RegistryValue $policyPath 'HubsSidebarEnabled' 0
        if ($r -eq $true) { Write-Status 'OK' 'Edge 隐藏 Copilot 侧边栏（策略级，不随账号同步）' } else { Write-Status 'FAIL' "Edge 隐藏 Copilot 侧边栏 — $r" }
    }
}

function Invoke-BrowserAll {
    Write-Host ""
    Write-Host "  浏览器配置" -ForegroundColor Cyan
    Write-Host "  ──────────────────────────────" -ForegroundColor DarkGray
    Set-BrowserDeveloperMode 'chrome'  'Chrome'
    Set-BrowserDeveloperMode 'msedge'  'Edge'
    Set-EdgeNewTabSimple
    Disable-EdgeCopilotSidebar
    Write-Host ""
}
