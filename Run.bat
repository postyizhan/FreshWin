@echo off
where wt.exe >nul 2>&1
if %errorlevel% == 0 (
    wt.exe powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0FreshWin.ps1"
) else (
    PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0FreshWin.ps1"
)
