@echo off
title 海马智慧商业 - 后端微服务 (Spring Boot: 8082)
cd /d "%~dp0..\..\seahorse_back"

set "JAVA_HOME=C:\Program Files\Java\jdk-17"
set "PATH=C:\meng\software\apache-maven-3.9.11\bin;C:\Program Files\Java\jdk-17\bin;%PATH%"

echo =====================================================================
echo  正在启动海马智慧商业后端服务 (Spring Boot: 8082)...
echo  工作目录: %CD%
echo  JAVA_HOME: %JAVA_HOME%
echo =====================================================================

call "C:\meng\software\apache-maven-3.9.11\bin\mvn.cmd" spring-boot:run
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] 后端服务异常退出，退出码: %errorlevel%
    pause
)
