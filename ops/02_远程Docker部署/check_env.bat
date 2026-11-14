@echo off
chcp 65001 >nul
title 海马智慧商业 - 全栈环境变量与云端容器安全审计
echo ===============================================================================
echo        海马智慧商业平台 - 全栈环境变量与云端 Node 2 容器安全审计
echo ===============================================================================
echo.
python "%~dp0..\..\scripts\check_seahorse_env.py" %*
set "EXIT_CODE=%errorlevel%"
echo.
if not defined SEAHORSE_NO_PAUSE pause
exit /b %EXIT_CODE%
