# System.ps1 - 系统功能设置

function Enable-FileExtensions {
    $current = Get-RegistryValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'HideFileExt'
    if ($current -eq 0) {
        Write-Status 'SKIP' '开启文件扩展名'
    } else {
        $r = Set-RegistryValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'HideFileExt' 0
        if ($r -eq $true) { Write-Status 'OK' '开启文件扩展名' } else { Write-Status 'FAIL' "开启文件扩展名 — $r" }
    }
}

function Enable-HiddenFiles {
    $current = Get-RegistryValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Hidden'
    if ($current -eq 1) {
        Write-Status 'SKIP' '显示隐藏文件'
    } else {
        $r = Set-RegistryValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Hidden' 1
        if ($r -eq $true) { Write-Status 'OK' '显示隐藏文件' } else { Write-Status 'FAIL' "显示隐藏文件 — $r" }
    }
}

function Enable-WSL {
    $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName 'Microsoft-Windows-Subsystem-Linux' -ErrorAction SilentlyContinue
    $vmFeature  = Get-WindowsOptionalFeature -Online -FeatureName 'VirtualMachinePlatform' -ErrorAction SilentlyContinue
    if ($wslFeature -and $wslFeature.State -eq 'Enabled' -and $vmFeature -and $vmFeature.State -eq 'Enabled') {
        Write-Status 'SKIP' '开启 WSL'
    } else {
        Write-Host "  正在开启 WSL..." -ForegroundColor DarkGray
        $results = @()
        if (-not ($wslFeature -and $wslFeature.State -eq 'Enabled')) {
            $results += Invoke-Cmd 'dism' @('/online', '/enable-feature', '/featurename:Microsoft-Windows-Subsystem-Linux', '/all', '/norestart')
        }
        if (-not ($vmFeature -and $vmFeature.State -eq 'Enabled')) {
            $results += Invoke-Cmd 'dism' @('/online', '/enable-feature', '/featurename:VirtualMachinePlatform', '/all', '/norestart')
        }

        $failed = $results | Where-Object { $_.ExitCode -notin 0, 3010 }
        if (-not $failed) {
            Write-Status 'OK' '开启 WSL/WSL2 组件（需重启生效）'
        } else {
            Write-Status 'FAIL' "开启 WSL — 退出码 $($failed[0].ExitCode) $($failed[0].Output)"
        }
    }
}

function Enable-HyperV {
    $feature = Get-WindowsOptionalFeature -Online -FeatureName 'Microsoft-Hyper-V' -ErrorAction SilentlyContinue
    if ($feature -and $feature.State -eq 'Enabled') {
        Write-Status 'SKIP' '开启 Hyper-V'
    } else {
        Write-Host "  正在开启 Hyper-V..." -ForegroundColor DarkGray
        $r = Invoke-Cmd 'dism' @('/online', '/enable-feature', '/featurename:Microsoft-Hyper-V', '/all', '/norestart')
        if ($r.ExitCode -eq 0 -or $r.ExitCode -eq 3010) {
            Write-Status 'OK' '开启 Hyper-V（需重启生效）'
        } else {
            Write-Status 'FAIL' "开启 Hyper-V — 退出码 $($r.ExitCode)"
        }
    }
}

function Set-TimeFormat12H {
    $longTarget  = 'tt h:mm:ss'
    $shortTarget = 'tt h:mm'
    $currentLong  = Get-RegistryValue 'HKCU:\Control Panel\International' 'sTimeFormat'
    $currentShort = Get-RegistryValue 'HKCU:\Control Panel\International' 'sShortTime'
    if ($currentLong -eq $longTarget -and $currentShort -eq $shortTarget) {
        Write-Status 'SKIP' '设置12小时制时间格式'
    } else {
        $r1 = Set-RegistryValue 'HKCU:\Control Panel\International' 'sTimeFormat' $longTarget 'String'
        $r2 = Set-RegistryValue 'HKCU:\Control Panel\International' 'sShortTime'  $shortTarget 'String'
        if ($r1 -eq $true -and $r2 -eq $true) {
            # 广播设置变更，任务栏时间立即刷新
            if (-not ([System.Management.Automation.PSTypeName]'NativeMethods.WinAPI').Type) {
                $code = @'
[DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Auto)]
public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
'@
                Add-Type -MemberDefinition $code -Name 'WinAPI' -Namespace 'NativeMethods' -ErrorAction SilentlyContinue
            }
            $result = [UIntPtr]::Zero
            [NativeMethods.WinAPI]::SendMessageTimeout([IntPtr]0xffff, 0x001A, [UIntPtr]::Zero, 'intl', 0, 1000, [ref]$result) | Out-Null
            Write-Status 'OK' '设置12小时制时间格式'
        } else {
            Write-Status 'FAIL' "设置时间格式 — $r1 $r2"
        }
    }
}

function Set-PSExecutionPolicy {
    $userScope = Get-ExecutionPolicy -Scope CurrentUser
    if ($userScope -in 'Bypass', 'Unrestricted', 'RemoteSigned') {
        Write-Status 'SKIP' "PowerShell 执行策略（CurrentUser: $userScope）"
        return
    }
    # 直接写注册表，绕过组策略对 Set-ExecutionPolicy 的限制
    $r = Set-RegistryValue 'HKCU:\Software\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell' 'ExecutionPolicy' 'RemoteSigned' 'String'
    if ($r -eq $true) { Write-Status 'OK' 'PowerShell 执行策略设为 RemoteSigned' } else { Write-Status 'FAIL' "PowerShell 执行策略 — $r" }
}

function Disable-MenuAnimation {
    $current = Get-RegistryValue 'HKCU:\Control Panel\Desktop' 'MenuShowDelay'
    if ($current -eq '0') {
        Write-Status 'SKIP' '关闭右键菜单动画'
    } else {
        $r = Set-RegistryValue 'HKCU:\Control Panel\Desktop' 'MenuShowDelay' '0' 'String'
        if ($r -eq $true) { Write-Status 'OK' '关闭右键菜单动画' } else { Write-Status 'FAIL' "关闭右键菜单动画 — $r" }
    }
}

function Enable-LongPaths {
    $current = Get-RegistryValue 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' 'LongPathsEnabled'
    if ($current -eq 1) {
        Write-Status 'SKIP' '开启长路径支持'
    } else {
        $r = Set-RegistryValue 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' 'LongPathsEnabled' 1
        if ($r -eq $true) { Write-Status 'OK' '开启长路径支持' } else { Write-Status 'FAIL' "开启长路径支持 — $r" }
    }
}

function Disable-StartMenuRecommendations {
    $current = Get-RegistryValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_IrisRecommendations'
    if ($current -eq 0) {
        Write-Status 'SKIP' '关闭开始菜单推荐项目'
    } else {
        $r = Set-RegistryValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_IrisRecommendations' 0
        if ($r -eq $true) { Write-Status 'OK' '关闭开始菜单推荐项目' } else { Write-Status 'FAIL' "关闭开始菜单推荐项目 — $r" }
    }
}

function Disable-SmartAppControl {
    $path = 'HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy'
    $name = 'VerifiedAndReputablePolicyState'
    $current = Get-RegistryValue $path $name
    if ($current -eq 0) {
        Write-Status 'SKIP' '关闭 Windows 智能应用控制'
    } else {
        $r = Set-RegistryValue $path $name 0
        if ($r -eq $true) {
            Write-Status 'OK' '关闭 Windows 智能应用控制（需重启生效，关闭后通常只能重置或重装系统才能重新开启）'
        } else {
            Write-Status 'FAIL' "关闭 Windows 智能应用控制 — $r"
        }
    }
}

function Set-WindowsTerminalDefault {
    $wtConsoleGuid = '{2EACA947-7F5F-4CFA-BA87-8F7FBEEFBE69}'
    $wtTerminalGuid = '{E12CFF52-A866-4C77-9A90-F570A7AA2C6B}'
    $path = 'HKCU:\Console\%%Startup'
    $currentConsole = Get-RegistryValue $path 'DelegationConsole'
    $currentTerminal = Get-RegistryValue $path 'DelegationTerminal'
    if ($currentConsole -eq $wtConsoleGuid -and $currentTerminal -eq $wtTerminalGuid) {
        Write-Status 'SKIP' '配置 Windows Terminal 为默认终端'
    } else {
        $wt = Get-Command 'wt.exe' -ErrorAction SilentlyContinue
        if (-not $wt) {
            Write-Status 'FAIL' '配置 Windows Terminal 为默认终端 — 未检测到安装'
            return
        }
        $r1 = Set-RegistryValue $path 'DelegationConsole' $wtConsoleGuid 'String'
        $r2 = Set-RegistryValue $path 'DelegationTerminal' $wtTerminalGuid 'String'
        if ($r1 -eq $true -and $r2 -eq $true) { Write-Status 'OK' '配置 Windows Terminal 为默认终端' } else { Write-Status 'FAIL' "配置 Windows Terminal — $r1 $r2" }
    }
}

function Invoke-SystemAll {
    $actions = @(
        @{ Name = '开启文件扩展名';                    Fn = { Enable-FileExtensions };    Group = 'explorer' },
        @{ Name = '显示隐藏文件';                      Fn = { Enable-HiddenFiles };        Group = 'explorer' },
        @{ Name = '开启 WSL';                          Fn = { Enable-WSL };                Group = 'none' },
        @{ Name = '开启 Hyper-V';                      Fn = { Enable-HyperV };             Group = 'none' },
        @{ Name = '设置12小时制时间格式';              Fn = { Set-TimeFormat12H };          Group = 'none' },
        @{ Name = 'PowerShell 执行策略设为 RemoteSigned'; Fn = { Set-PSExecutionPolicy };  Group = 'none' },
        @{ Name = '关闭右键菜单动画';                  Fn = { Disable-MenuAnimation };     Group = 'none' },
        @{ Name = '开启长路径支持';                    Fn = { Enable-LongPaths };          Group = 'none' },
        @{ Name = '关闭开始菜单推荐项目';              Fn = { Disable-StartMenuRecommendations }; Group = 'none' },
        @{ Name = '关闭 Windows 智能应用控制';          Fn = { Disable-SmartAppControl };     Group = 'none' },
        @{ Name = '配置 Windows Terminal 为默认终端';  Fn = { Set-WindowsTerminalDefault }; Group = 'none' }
    )
    $indices = Invoke-SelectMenu '系统功能' ($actions | ForEach-Object { $_.Name })
    if ($null -eq $indices) { return }

    Clear-Host
    Write-Host ""
    Write-Host "  系统功能" -ForegroundColor Cyan
    Write-Host "  ──────────────────────────────" -ForegroundColor DarkGray
    $needRestartExplorer = $false
    foreach ($i in $indices) {
        & $actions[$i].Fn
        if ($actions[$i].Group -eq 'explorer') { $needRestartExplorer = $true }
    }
    if ($needRestartExplorer) {
        Write-Host ""
        Write-Host "  正在重启资源管理器..." -ForegroundColor DarkGray
        Restart-Explorer
    }
    Write-Host ""
}
