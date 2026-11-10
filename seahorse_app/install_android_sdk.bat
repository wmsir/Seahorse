@echo off
rem ====================================================================
rem Seahorse Store Manager - Automated Android SDK Installer
rem ====================================================================
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_android_sdk.ps1"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Installation failed with code %ERRORLEVEL%.
    pause
)
