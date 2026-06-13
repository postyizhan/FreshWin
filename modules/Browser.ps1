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

function Backup-BrowserPrefs {
    param([string]$PrefsPath)
    $backupPath = "$PrefsPath.freshwin.bak"
    if (-not (Test-Path $backupPath)) {
        Copy-Item -Path $PrefsPath -Destination $backupPath -Force
    }
}

function Save-BrowserPrefs {
    param(
        [object]$Prefs,
        [string]$PrefsPath
    )
    Backup-BrowserPrefs $PrefsPath
    $Prefs | ConvertTo-Json -Depth 100 | Set-Content $PrefsPath -Encoding UTF8
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
        Save-BrowserPrefs $prefs $prefsPath
        Write-Status 'OK' "$DisplayName 开启开发者模式"
    } catch {
        Write-Status 'FAIL' "$DisplayName 开启开发者模式 — $($_.Exception.Message)"
    }
}

function Set-EdgeNewTabSimple {
    $prefsPath = Get-BrowserPrefsPath 'msedge'
    if (-not (Test-Path $prefsPath)) {
        Write-Status 'SKIP' 'Edge 主页精简 — 未检测到安装'
        return
    }
    Stop-BrowserProcesses 'msedge' 'Edge'
    try {
        $prefs = Get-Content $prefsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $already = $prefs.ntp.show_content -eq $false -and
                   $prefs.ntp.show_quick_links -eq $false -and
                   $prefs.ntp.show_cards -eq $false -and
                   $prefs.ntp.background_image_type -eq 0
        if ($already) {
            Write-Status 'SKIP' 'Edge 主页精简'
            return
        }
        if (-not $prefs.ntp) { $prefs | Add-Member -NotePropertyName 'ntp' -NotePropertyValue ([PSCustomObject]@{}) }
        $prefs.ntp | Add-Member -NotePropertyName 'show_content'          -NotePropertyValue $false -Force
        $prefs.ntp | Add-Member -NotePropertyName 'show_quick_links'      -NotePropertyValue $false -Force
        $prefs.ntp | Add-Member -NotePropertyName 'show_cards'            -NotePropertyValue $false -Force
        $prefs.ntp | Add-Member -NotePropertyName 'background_image_type' -NotePropertyValue 0      -Force  # 0=纯色, 1=自定义, 2=必应热点
        Save-BrowserPrefs $prefs $prefsPath
        Write-Status 'OK' 'Edge 主页精简（关闭信息流/快速链接/小组件/必应热点）'
    } catch {
        Write-Status 'FAIL' "Edge 主页精简 — $($_.Exception.Message)"
    }
}

function Disable-EdgeCopilotSidebar {
    $prefsPath = Get-BrowserPrefsPath 'msedge'
    if (-not (Test-Path $prefsPath)) {
        Write-Status 'SKIP' 'Edge 隐藏 Copilot 侧边栏 — 未检测到安装'
        return
    }
    Stop-BrowserProcesses 'msedge' 'Edge'
    try {
        $prefs = Get-Content $prefsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($prefs.edge_sidebar.enabled -eq $false) {
            Write-Status 'SKIP' 'Edge 隐藏 Copilot 侧边栏'
            return
        }
        if (-not $prefs.edge_sidebar) { $prefs | Add-Member -NotePropertyName 'edge_sidebar' -NotePropertyValue ([PSCustomObject]@{}) }
        $prefs.edge_sidebar | Add-Member -NotePropertyName 'enabled' -NotePropertyValue $false -Force
        Save-BrowserPrefs $prefs $prefsPath
        Write-Status 'OK' 'Edge 隐藏 Copilot 侧边栏'
    } catch {
        Write-Status 'FAIL' "Edge 隐藏 Copilot 侧边栏 — $($_.Exception.Message)"
    }
}

function Invoke-BrowserAll {
    $actions = @(
        @{ Name = 'Chrome 开启开发者模式';              Fn = { Set-BrowserDeveloperMode 'chrome' 'Chrome' } },
        @{ Name = 'Edge 开启开发者模式';                Fn = { Set-BrowserDeveloperMode 'msedge' 'Edge' } },
        @{ Name = 'Edge 主页精简（关闭信息流/快速链接/小组件/必应热点）'; Fn = { Set-EdgeNewTabSimple } },
        @{ Name = 'Edge 隐藏 Copilot 侧边栏';           Fn = { Disable-EdgeCopilotSidebar } }
    )
    $indices = Invoke-SelectMenu '浏览器配置' ($actions | ForEach-Object { $_.Name })
    if ($null -eq $indices) { return }

    Clear-Host
    Write-Host ""
    Write-Host "  浏览器配置" -ForegroundColor Cyan
    Write-Host "  ──────────────────────────────" -ForegroundColor DarkGray
    foreach ($i in $indices) {
        & $actions[$i].Fn
    }
    Write-Host ""
}
