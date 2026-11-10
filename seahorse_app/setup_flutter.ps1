[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$Host.UI.RawUI.WindowTitle = "海马连锁门店管家 - Flutter SDK 自动化极速安装"

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "         🚀 Flutter 3.x SDK 自动化极速安装与环境配置助手" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. 设置中国特化镜像加速环境变量
Write-Host "[1/5] 配置 Flutter & Pub 国内高速镜像环境变量..." -ForegroundColor Yellow
$pubUrl = "https://pub.flutter-io.cn"
$storageUrl = "https://storage.flutter-io.cn"

$env:PUB_HOSTED_URL = $pubUrl
$env:FLUTTER_STORAGE_BASE_URL = $storageUrl

[Environment]::SetEnvironmentVariable("PUB_HOSTED_URL", $pubUrl, "User")
[Environment]::SetEnvironmentVariable("FLUTTER_STORAGE_BASE_URL", $storageUrl, "User")
Write-Host "  -> 已配置 PUB_HOSTED_URL = $pubUrl" -ForegroundColor Green
Write-Host "  -> 已配置 FLUTTER_STORAGE_BASE_URL = $storageUrl" -ForegroundColor Green

Write-Host ""
# 2. 准备安装目录
$InstallDir = "C:\src"
$FlutterDir = Join-Path $InstallDir "flutter"
$FlutterBin = Join-Path $FlutterDir "bin"
$ZipFile = Join-Path $InstallDir "flutter_windows_stable.zip"

if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

Write-Host "[2/5] 准备 Flutter 安装目录: $FlutterDir" -ForegroundColor Yellow

# 3. 下载 Flutter 稳定版 SDK
$downloadUrl = "https://storage.flutter-io.cn/flutter_infra_release/releases/stable/windows/flutter_windows_3.27.0-stable.zip"

if (-not (Test-Path (Join-Path $FlutterBin "flutter.bat"))) {
    Write-Host "[3/5] 正在从官方镜像源高速下载 Flutter 3.27.0 Stable SDK (~1GB)..." -ForegroundColor Yellow
    Write-Host "  下载链接: $downloadUrl" -ForegroundColor Gray
    
    # 使用 curl.exe 下载，支持断点续传和进度显示
    $curlCmd = Get-Command "curl.exe" -ErrorAction SilentlyContinue
    if ($curlCmd) {
        & curl.exe -C - -L -o $ZipFile $downloadUrl --progress-bar
    } else {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $ZipFile
    }

    if (-not (Test-Path $ZipFile)) {
        Write-Host "[错误] 安装包下载失败，请检查网络连接。" -ForegroundColor Red
        exit 1
    }

    Write-Host ""
    Write-Host "  -> 安装包下载完毕，正在极速解压至 C:\src\flutter ..." -ForegroundColor Yellow
    & tar.exe -xf $ZipFile -C $InstallDir
    
    # 解压后删除压缩包节省磁盘空间
    if (Test-Path $ZipFile) {
        Remove-Item -Path $ZipFile -Force -ErrorAction SilentlyContinue
    }
    Write-Host "  -> 解压完成！" -ForegroundColor Green
} else {
    Write-Host "[3/5] 检测到已存在 Flutter SDK: $FlutterDir，跳过下载。" -ForegroundColor Green
}

Write-Host ""
# 4. 配置系统环境变量 PATH
Write-Host "[4/5] 注册 Flutter 环境变量 PATH..." -ForegroundColor Yellow
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$FlutterBin*") {
    $newUserPath = "$FlutterBin;$userPath"
    [Environment]::SetEnvironmentVariable("Path", $newUserPath, "User")
    Write-Host "  -> 已将 $FlutterBin 永久注册至当前用户 PATH！" -ForegroundColor Green
} else {
    Write-Host "  -> 用户 PATH 已包含 $FlutterBin" -ForegroundColor Green
}

$env:Path = "$FlutterBin;$env:Path"

Write-Host ""
# 5. 初始化 Flutter 与拉取项目依赖
Write-Host "[5/5] 初始化 Flutter 引擎并拉取项目依赖..." -ForegroundColor Yellow
$flutterBat = Join-Path $FlutterBin "flutter.bat"
& $flutterBat --version

$AppDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (Test-Path (Join-Path $AppDir "pubspec.yaml")) {
    Push-Location $AppDir
    Write-Host ""
    Write-Host "  -> 正在为 seahorse_app 执行 flutter pub get..." -ForegroundColor Yellow
    & $flutterBat pub get
    Pop-Location
}

Write-Host ""
Write-Host "====================================================================" -ForegroundColor Green
Write-Host "  🎉 Flutter SDK 及项目依赖全部安装与配置完成！" -ForegroundColor Green
Write-Host "  现在您可以直接运行 build_android.bat / build_menu.bat 打包 APP 了！" -ForegroundColor Green
Write-Host "====================================================================" -ForegroundColor Green

if ([Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
    try {
        Read-Host "全部完成，按 Enter 键退出..."
    } catch {}
}

