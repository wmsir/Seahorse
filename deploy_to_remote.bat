@echo off
chcp 65001 >nul
title 海马智慧商业平台 - 远程一键部署 Docker
call "%~dp0ops\02_远程Docker部署\deploy_all.bat"
