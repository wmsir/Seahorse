@echo off
chcp 65001 >nul
title 海马智慧商业 - 后端微服务 (Spring Boot)
set "SEAHORSE_ENV_FILE=%~dp0..\..\.env"
if exist "%SEAHORSE_ENV_FILE%" (
    echo [INFO] 检测到本地配置文件 .env，正在自动加载非空环境变量...
    for /f "usebackq eol=# tokens=1,* delims==" %%A in ("%SEAHORSE_ENV_FILE%") do (
        if not "%%~B"=="" set "%%A=%%~B"
    )
)
if not defined SERVER_PORT set "SERVER_PORT=8082"
cd /d "%~dp0..\..\seahorse_back"

if exist "C:\Program Files\Java\jdk-17\bin\java.exe" (
    set "JAVA_HOME=C:\Program Files\Java\jdk-17"
)
if defined JAVA_HOME (
    set "PATH=%JAVA_HOME%\bin;%PATH%"
)
if exist "C:\meng\software\apache-maven-3.9.11\bin\mvn.cmd" (
    set "PATH=C:\meng\software\apache-maven-3.9.11\bin;%PATH%"
)

where mvn.cmd >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] 未找到 Maven ^(mvn.cmd^)，请安装 Maven 3.8+ 并配置至 PATH 环境变量。
    pause
    exit /b 1
)

echo =====================================================================
echo  正在启动海马智慧商业后端服务 (Spring Boot: %SERVER_PORT%)...
echo  工作目录: %CD%
echo  JAVA_HOME: %JAVA_HOME%
echo =====================================================================

call mvn.cmd spring-boot:run
if %errorlevel% neq 0 (
    echo.
    echo [ERROR] 后端服务异常退出，退出码: %errorlevel%
    pause
)
