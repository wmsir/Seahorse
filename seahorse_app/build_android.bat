@echo off
rem ====================================================================
rem Seahorse Store Manager - Android APK Build Launcher
rem ====================================================================
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build_android.ps1"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Build exited with code %ERRORLEVEL%.
    pause
)