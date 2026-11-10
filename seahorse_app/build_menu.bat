@echo off
rem ====================================================================
rem Seahorse Store Manager - Multiplatform Build Menu Launcher
rem ====================================================================
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build_menu.ps1"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Exited with code %ERRORLEVEL%.
    pause
)
