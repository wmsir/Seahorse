[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$Host.UI.RawUI.WindowTitle = "海马门店管家 - Android SDK 自动化极速安装"

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "         📱 Android SDK & 命令行编译工具链自动化安装助手" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. 设置 JAVA_HOME
$jdkPath = "C:\Program Files\Java\jdk-17"
if (Test-Path $jdkPath) {
    $env:JAVA_HOME = $jdkPath
    [Environment]::SetEnvironmentVariable("JAVA_HOME", $jdkPath, "User")
    Write-Host "[1/6] 绑定 JAVA_HOME: $jdkPath" -ForegroundColor Green
}

# 2. 准备目录
$AndroidRoot = "C:\Android"
$SdkDir = "C:\Android\sdk"
$CmdlineDir = Join-Path $SdkDir "cmdline-tools"
$LatestDir = Join-Path $CmdlineDir "latest"
$ZipFile = Join-Path $AndroidRoot "commandlinetools.zip"

if (-not (Test-Path $CmdlineDir)) {
    New-Item -ItemType Directory -Path $CmdlineDir -Force | Out-Null
}

Write-Host "[2/6] 准备 Android SDK 目标目录: $SdkDir" -ForegroundColor Yellow

# 3. 下载 Command-line Tools
$downloadUrl = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"

if (-not (Test-Path (Join-Path $LatestDir "bin\sdkmanager.bat"))) {
    Write-Host "[3/6] 正在高速下载 Google Android 命令行工具链 (~146MB)..." -ForegroundColor Yellow
    
    $curlCmd = Get-Command "curl.exe" -ErrorAction SilentlyContinue
    if ($curlCmd) {
        & curl.exe -C - -L -o $ZipFile $downloadUrl --progress-bar
    } else {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $ZipFile
    }

    if (-not (Test-Path $ZipFile)) {
        Write-Host "[错误] 命令行工具下载失败，请检查网络。" -ForegroundColor Red
        exit 1
    }

    Write-Host "  -> 正在解压命令行工具..." -ForegroundColor Yellow
    & tar.exe -xf $ZipFile -C $CmdlineDir

    # Google zip 解压后为 cmdline-tools 目录，需重命名为 latest
    $extractedFolder = Join-Path $CmdlineDir "cmdline-tools"
    if (Test-Path $extractedFolder) {
        if (Test-Path $LatestDir) {
            Remove-Item -Path $LatestDir -Recurse -Force
        }
        Move-Item -Path $extractedFolder -Destination $LatestDir -Force
    }

    if (Test-Path $ZipFile) {
        Remove-Item -Path $ZipFile -Force -ErrorAction SilentlyContinue
    }
    Write-Host "  -> 命令行工具就绪: $LatestDir" -ForegroundColor Green
} else {
    Write-Host "[3/6] 检测到已有命令行工具: $LatestDir" -ForegroundColor Green
}

# 4. 配置环境变量与 Flutter 配置
Write-Host "[4/6] 配置 ANDROID_HOME 与系统环境变量..." -ForegroundColor Yellow
$env:ANDROID_HOME = $SdkDir
$env:ANDROID_SDK_ROOT = $SdkDir
[Environment]::SetEnvironmentVariable("ANDROID_HOME", $SdkDir, "User")
[Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $SdkDir, "User")

$binPath = Join-Path $LatestDir "bin"
$platformToolsPath = Join-Path $SdkDir "platform-tools"
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$binPath*") {
    $userPath = "$binPath;$platformToolsPath;$userPath"
    [Environment]::SetEnvironmentVariable("Path", $userPath, "User")
}
$env:Path = "$binPath;$platformToolsPath;$env:Path"

# 绑定 Flutter Android SDK 路径
$flutterBat = "C:\src\flutter\bin\flutter.bat"
if (Test-Path $flutterBat) {
    & $flutterBat config --android-sdk "$SdkDir" | Out-Null
    Write-Host "  -> Flutter Android SDK 路径已绑定为: $SdkDir" -ForegroundColor Green
}

# 5. 自动接受 Android SDK 协议 License
Write-Host "[5/6] 自动写入 Android SDK 商业与开发者授权协议 (Licenses)..." -ForegroundColor Yellow
$licenseDir = Join-Path $SdkDir "licenses"
if (-not (Test-Path $licenseDir)) {
    New-Item -ItemType Directory -Path $licenseDir -Force | Out-Null
}

$sdkLicense = @"
8933bad161af4178b1185d1a37fbf41ea5269c55
d56f5187479451eabf01fb78af6dfcb131a6481e
24333f8a63b6825ea9c5514f83c2829b004d1fee
"@
$previewLicense = "84831b9409646a2010144d1abe2417a896803029"
$gdkLicense = "33b6a2b64900ae7b172a392b45070f6f4d02334f"

[System.IO.File]::WriteAllText((Join-Path $licenseDir "android-sdk-license"), $sdkLicense)
[System.IO.File]::WriteAllText((Join-Path $licenseDir "android-sdk-preview-license"), $previewLicense)
[System.IO.File]::WriteAllText((Join-Path $licenseDir "google-gdk-license"), $gdkLicense)
Write-Host "  -> 授权协议已全部自动接受完成！" -ForegroundColor Green

# 6. 安装平台组件: platform-tools, platforms;android-34, build-tools;34.0.0
Write-Host "[6/6] 正在下载并安装 Android 34 构建工具包 (build-tools & platform-34)..." -ForegroundColor Yellow
$sdkManagerBat = Join-Path $binPath "sdkmanager.bat"
if (Test-Path $sdkManagerBat) {
    & $sdkManagerBat --sdk_root="$SdkDir" "platform-tools" "platforms;android-34" "build-tools;34.0.0"
}

Write-Host ""
Write-Host "====================================================================" -ForegroundColor Green
Write-Host "  🎉 Android SDK 完整编译工具链安装成功！" -ForegroundColor Green
Write-Host "  现在可以直接运行 build_android.bat 构建 APK 安装包了！" -ForegroundColor Green
Write-Host "====================================================================" -ForegroundColor Green

if ([Environment]::UserInteractive -and -not [Console]::IsInputRedirected) {
    try {
        Read-Host "安装完成，按 Enter 键退出..."
    } catch {}
}
