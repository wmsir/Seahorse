@echo off
chcp 65001 >nul
title 海马智慧商业 - 前端工程 (Vue 3 + Vite: 3000)
set "SEAHORSE_ENV_FILE=%~dp0..\..\.env"
if exist "%SEAHORSE_ENV_FILE%" (
    echo [INFO] 检测到本地配置文件 .env，正在自动加载非空环境变量...
    for /f "usebackq eol=# tokens=1,* delims==" %%A in ("%SEAHORSE_ENV_FILE%") do (
        if not "%%~B"=="" set "%%A=%%~B"
    )
)
cd /d "%~dp0..\..\seahorse_web_front"

if exist "C:\Program Files\nodejs\npm.cmd" (
    set "PATH=C:\Program Files\nodejs;%PATH%"
)

where npm.cmd >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] 未找到 Node.js ^(npm.cmd^)，请安装 Node.js 18+ 并配置至 PATH 环境变量。
    pause
    exit /b 1
)

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
