@echo off
where wt.exe >nul 2>&1
if %errorlevel% == 0 (
    wt.exe powershell.exe -ExecutionPolicy Bypass -File "%~dp0FreshWin.ps1"
) else (
    PowerShell -ExecutionPolicy Bypass -File "%~dp0FreshWin.ps1"
)
