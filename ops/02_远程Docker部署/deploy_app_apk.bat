@echo off
chcp 65001 >nul
title 海马智慧商业 - 本地编译最新 Release APK
echo ===============================================================================
echo        海马智慧商业平台 - 本地编译生成最新 Flutter Release APK (无需上传服务器)
echo        说明: 本地直接调用 Flutter 打包，产物输出至根目录 seahorse_app_latest.apk
echo ===============================================================================
echo.
python "%~dp0deploy_engine.py" --build-apk
echo.
pause
