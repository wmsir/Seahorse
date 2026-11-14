@echo off
chcp 65001 >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0trigger_github_build.ps1" %*
if %errorlevel% neq 0 exit /b %errorlevel%
