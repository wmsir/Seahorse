@echo off
title 海马智慧商业 - 前端工程 (Vue 3 + Vite: 3000)
cd /d "%~dp0..\..\seahorse_web_front"

set "PATH=C:\Program Files\nodejs;%PATH%"

echo =====================================================================
echo  正在启动海马智慧商业 Web 前端 (Vite: 3000)...
echo  工作目录: %CD%
echo =====================================================================

call npm.cmd run dev
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] 前端工程异常退出，退出码: %errorlevel%
    pause
)
