# Common.ps1 - 公共工具函数

function Write-Status {
    param(
        [string]$Status,  # OK, SKIP, FAIL
        [string]$Message
    )
    switch ($Status) {
        'OK'   { Write-Host "  " -NoNewline; Write-Host "✓" -ForegroundColor Green -NoNewline; Write-Host "  $Message" }
        'SKIP' { Write-Host "  " -NoNewline; Write-Host "~" -ForegroundColor Yellow -NoNewline; Write-Host "  $Message (跳过)" }
        'FAIL' { Write-Host "  " -NoNewline; Write-Host "✗" -ForegroundColor Red -NoNewline; Write-Host "  $Message" }
    }
}

function Set-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [ValidateSet('String', 'ExpandString', 'Binary', 'DWord', 'MultiString', 'QWord')]
        [string]$Type = 'DWord'
    )
    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force
        return $true
    } catch {
        return $_.Exception.Message
    }
}

function Remove-RegistryValue {
    param(
        [string]$Path,
        [string]$Name
    )
    if (Test-Path $Path) {
        Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
    }
}

function Get-RegistryValue {
    param(
        [string]$Path,
        [string]$Name
    )
    try {
        return (Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop).$Name
    } catch {
        return $null
    }
}

function Test-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-Cmd {
    param(
        [string]$Command,
        [string[]]$Arguments = @()
    )

    if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
        return @{ ExitCode = -1; Output = "命令未找到：$Command" }
    }

    try {
        $result = & $Command @Arguments 2>&1
        $output = ($result | Out-String).Trim()
        return @{ ExitCode = $LASTEXITCODE; Output = $output }
    } catch {
        return @{ ExitCode = -1; Output = $_.Exception.Message }
    }
}

function Restart-Explorer {
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500
    Start-Process explorer
}

# 交互式复选菜单
# $Title   : 标题文字
# $Items   : 字符串数组，每项的显示名称
# 返回值   : 用户选中的索引数组（0-based），若取消则返回 $null
function Invoke-SelectMenu {
    param(
        [string]$Title,
        [string[]]$Items
    )
    $selected = @($Items | ForEach-Object { $true })  # 默认全选

    while ($true) {
        Clear-Host
        Write-Host ""
        Write-Host "  $Title" -ForegroundColor Cyan
        Write-Host "  ──────────────────────────────" -ForegroundColor DarkGray
        Write-Host ""
        for ($i = 0; $i -lt $Items.Count; $i++) {
            $mark = if ($selected[$i]) { "[✓]" } else { "[ ]" }
            $color = if ($selected[$i]) { 'White' } else { 'DarkGray' }
            Write-Host "  [$($i+1)] $mark $($Items[$i])" -ForegroundColor $color
        }
        Write-Host ""
        Write-Host "  [A] 全选  [N] 全不选  [Enter] 执行选中项  [0] 取消" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host -NoNewline "  > "
        $input = Read-Host

        switch ($input.Trim().ToUpper()) {
            'A' { $selected = @($Items | ForEach-Object { $true }) }
            'N' { $selected = @($Items | ForEach-Object { $false }) }
            '0' { return $null }
            ''  {
                $indices = @()
                for ($i = 0; $i -lt $Items.Count; $i++) {
                    if ($selected[$i]) { $indices += $i }
                }
                return $indices
            }
            default {
                if ($input -match '^\d+$') {
                    $idx = [int]$input - 1
                    if ($idx -ge 0 -and $idx -lt $Items.Count) {
                        $selected[$idx] = -not $selected[$idx]
                    }
                }
            }
        }
    }
}
