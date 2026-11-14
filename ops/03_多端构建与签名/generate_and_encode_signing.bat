@echo off
chcp 65001 >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0generate_and_encode_signing.ps1" %*
if %errorlevel% neq 0 exit /b %errorlevel%
