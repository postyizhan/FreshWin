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

function Test-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Set-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        [object]$Value,
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

function Invoke-Cmd {
    param([string]$Command, [string[]]$Arguments)
    $result = & $Command @Arguments 2>&1
    return @{ ExitCode = $LASTEXITCODE; Output = $result }
}

function Restart-Explorer {
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500
    Start-Process explorer
}
