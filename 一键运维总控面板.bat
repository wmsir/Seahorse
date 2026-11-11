@echo off
chcp 65001 >nul
title 海马智慧商业平台 - 一键运维总控面板
:MENU
cls
echo ===============================================================================
echo                海马智慧商业平台 - 一键运维总控面板
echo                Slogan: 海马会员，记住每位好客。
echo                云端主机: 39.97.158.22  [服务运行端口: 80 / 8082]
echo ===============================================================================
echo.
echo   【本地开发与调试】
echo     [1] 一键启动本地全部服务 (Spring Boot + Vite + 自动打开浏览器)
echo     [2] 一键重启本地全部服务
echo     [3] 一键安全停止本地全部服务
echo.
echo   【云端 Docker 打包与发布】
echo     [4] 一键全量发布 (编译发布前后端至云端 + 本地打最新APK，不上传云端)
echo     [5] 仅打包发布 Web 前端工程 (Vue 3 生产构建至云端 Nginx)
echo     [6] 仅打包发布 Java 后端微服务 (Spring Boot 容器热重载至云端)
echo     [7] 仅在本地打包最新 Release APK (Flutter APK 本地直接安装，无需上传)
echo     [8] 执行云端全系统链路健康巡检 (HTTP 状态码 + 预约数据纯净度)
echo.
echo   【退出】
echo     [0] 退出控制台
echo.
echo ===============================================================================
set "choice="
set /p "choice=请输入操作编号并按回车 (0-8): "

if "%choice%"=="" exit /b 0
if "%choice%"=="0" exit /b 0
if "%choice%"=="1" goto LOCAL_START
if "%choice%"=="2" goto LOCAL_RESTART
if "%choice%"=="3" goto LOCAL_STOP
if "%choice%"=="4" goto DEPLOY_ALL
if "%choice%"=="5" goto DEPLOY_FRONT
if "%choice%"=="6" goto DEPLOY_BACK
if "%choice%"=="7" goto DEPLOY_APK
if "%choice%"=="8" goto HEALTH_CHECK
echo 输入无效，请重新输入...
timeout /t 2 >nul
goto MENU

:LOCAL_START
call "%~dp0ops\01_本地开发运行\start.bat"
goto MENU

:LOCAL_RESTART
call "%~dp0ops\01_本地开发运行\restart.bat"
goto MENU

:LOCAL_STOP
call "%~dp0ops\01_本地开发运行\stop.bat"
goto MENU

:DEPLOY_ALL
call "%~dp0ops\02_远程Docker部署\deploy_all.bat"
goto MENU

:DEPLOY_FRONT
call "%~dp0ops\02_远程Docker部署\deploy_frontend_only.bat"
goto MENU

:DEPLOY_BACK
call "%~dp0ops\02_远程Docker部署\deploy_backend_only.bat"
goto MENU

:DEPLOY_APK
call "%~dp0ops\02_远程Docker部署\deploy_app_apk.bat"
goto MENU

:HEALTH_CHECK
call "%~dp0ops\02_远程Docker部署\health_check.bat"
goto MENU
