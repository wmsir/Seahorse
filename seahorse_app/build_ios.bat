@echo off
rem ====================================================================
rem Seahorse Store Manager - iOS Build Guide Launcher
rem ====================================================================
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build_ios.ps1"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Build exited with code %ERRORLEVEL%.
    pause
)
