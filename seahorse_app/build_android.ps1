param(
    [switch]$BumpVersion,
    [switch]$SyncDistApps,
    [switch]$SkipDistApps,
    [switch]$NonInteractive
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$isHeadless = $NonInteractive.IsPresent -or ($env:SEAHORSE_NON_INTERACTIVE -eq '1') -or (-not [string]::IsNullOrEmpty($env:CI)) -or [Console]::IsInputRedirected
$skipGlobalDist = $SkipDistApps.IsPresent -or ($env:SEAHORSE_SKIP_DIST_APPS -eq '1') -or (-not $SyncDistApps.IsPresent)

if (-not $isHeadless) {
    try { $Host.UI.RawUI.WindowTitle = "海马智慧门店 - Android APK 一键构建" } catch {}
}

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "         📱 海马智慧门店 - Android (安卓) APK 一键构建" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# 自动配置国内加速镜像
if (-not $env:PUB_HOSTED_URL) { $env:PUB_HOSTED_URL = "https://pub.flutter-io.cn" }
if (-not $env:FLUTTER_STORAGE_BASE_URL) { $env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn" }

# 自动探测 JDK 路径
if (-not $env:JAVA_HOME -and (Test-Path "C:\Program Files\Java\jdk-17")) {
    $env:JAVA_HOME = "C:\Program Files\Java\jdk-17"
}

# 自动探测常见 Flutter 安装路径
$candidatePaths = @("C:\src\flutter\bin", "C:\flutter\bin", "D:\src\flutter\bin", "D:\flutter\bin")
foreach ($p in $candidatePaths) {
    if (Test-Path (Join-Path $p "flutter.bat")) {
        if ($env:Path -notlike "*$p*") {
            $env:Path = "$p;$env:Path"
        }
        break
    }
}

# 自动探测 Android SDK 路径
$androidSdkCandidates = @(
    "$env:LOCALAPPDATA\Android\Sdk",
    "C:\Users\Administrator\AppData\Local\Android\Sdk",
    "C:\Android\sdk",
    "D:\Android\sdk",
    "D:\Android\Sdk"
)
foreach ($sdk in $androidSdkCandidates) {
    if ($sdk -and (Test-Path $sdk)) {
        $platforms = Get-ChildItem (Join-Path $sdk "platforms") -Filter "android-*" -Directory -ErrorAction SilentlyContinue
        if ($platforms) {
            $env:ANDROID_HOME = $sdk
            $env:ANDROID_SDK_ROOT = $sdk
            $cmdlineBin = Join-Path $sdk "cmdline-tools\latest\bin"
            $platformTools = Join-Path $sdk "platform-tools"
            if (Test-Path $cmdlineBin) { $env:Path = "$cmdlineBin;$env:Path" }
            if (Test-Path $platformTools) { $env:Path = "$platformTools;$env:Path" }
            break
        }
    }
}

# 1. 检查 Flutter 环境
Write-Host "[1/3] 检查并获取 Flutter 依赖包..." -ForegroundColor Yellow
$flutterCmd = Get-Command "flutter" -ErrorAction SilentlyContinue
if (-not $flutterCmd) {
    Write-Host "[错误] 系统未检测到 flutter 命令。" -ForegroundColor Red
    Write-Host "提示: 您可以双击同目录下的【install_flutter.bat】自动极速安装 Flutter SDK！" -ForegroundColor Yellow
    Write-Host "官方安装参考: https://docs.flutter.dev/get-started/install" -ForegroundColor Gray
    Write-Host ""
    if (-not $isHeadless) { Read-Host "按 Enter 键退出" }
    exit 1
}

# 优先离线极速模式检查依赖，若已存在则秒级通过
$packageConfig = Join-Path $ScriptDir ".dart_tool\package_config.json"
if (Test-Path $packageConfig) {
    flutter pub get --offline 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  -> Flutter 依赖包校验通过 (本地高速缓存)！" -ForegroundColor Green
    } else {
        flutter pub get
        Write-Host "  -> Flutter 依赖包网络拉取成功！" -ForegroundColor Green
    }
} else {
    flutter pub get
    Write-Host "  -> Flutter 依赖包获取成功！" -ForegroundColor Green
}

# 检查 Android SDK 完整性
$hasValidSdk = $false
if ($env:ANDROID_HOME -and (Test-Path $env:ANDROID_HOME)) {
    $platforms = Get-ChildItem (Join-Path $env:ANDROID_HOME "platforms") -Filter "android-*" -Directory -ErrorAction SilentlyContinue
    if ($platforms) {
        $hasValidSdk = $true
    }
}

if (-not $hasValidSdk) {
    Write-Host ""
    Write-Host "====================================================================" -ForegroundColor Yellow
    Write-Host "  ⚠️  【未检测到完整的 Android SDK 平台环境】" -ForegroundColor Yellow
    Write-Host "====================================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  构建 Android APK 需要本地 Android SDK 平台编译支持 (Android 34)。" -ForegroundColor White
    Write-Host "  请在命令行执行: flutter config --android-sdk `"您的SDK路径`"" -ForegroundColor Yellow
    Write-Host "====================================================================" -ForegroundColor Yellow
    Write-Host ""
    if (-not $isHeadless) { Read-Host "按 Enter 键退出..." }
    exit 1
}

# 读取当前版本号（默认不污染 git 追踪的 pubspec.yaml；仅在显式传入 -BumpVersion 时递增）
$pubspecPath = Join-Path $ScriptDir "pubspec.yaml"
$appVersion = "1.0.0"
if (Test-Path $pubspecPath) {
    $content = Get-Content $pubspecPath -Raw -Encoding UTF8
    if ($content -match 'version:\s*(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?') {
        $major = [int]$matches[1]
        $minor = [int]$matches[2]
        $patch = [int]$matches[3]
        if ($BumpVersion.IsPresent -and ($env:SEAHORSE_SKIP_DIST_APPS -ne '1')) {
            $patch = $patch + 1
            $appVersion = "$major.$minor.$patch"
            $newBuildNumber = [int](Get-Date -Format "MMddHHmm")
            $newContent = $content -replace 'version:\s*(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?', "version: $appVersion+$newBuildNumber"
            [System.IO.File]::WriteAllText($pubspecPath, $newContent, [System.Text.UTF8Encoding]::new($false))
            Write-Host "  -> [版本递增] 已更新版本号至: v$appVersion (Build $newBuildNumber)" -ForegroundColor Green
        } else {
            $appVersion = "$major.$minor.$patch"
            Write-Host "  -> [版本保持] 当前构建版本: v$appVersion (如需递增请传 -BumpVersion)" -ForegroundColor Cyan
        }
    }
}

Write-Host ""
# 2. 构建 Android Release APK
Write-Host "[2/3] 开始编译 Android Release APK 安装包..." -ForegroundColor Yellow
Write-Host "  -> 执行命令: flutter build apk --release" -ForegroundColor Gray
try {
    flutter build apk --release
    if ($LASTEXITCODE -ne 0) {
        throw "flutter build apk 编译失败，退出码: $LASTEXITCODE"
    }
} catch {
    Write-Host "[错误] $_" -ForegroundColor Red
    Write-Host "请检查上述 Gradle 编译日志以排查错误。" -ForegroundColor Red
    Write-Host ""
    if (-not $isHeadless) { Read-Host "按 Enter 键退出" }
    exit 1
}

Write-Host ""
# 3. 定位产物与自动多端分发
$ApkPath = Join-Path $ScriptDir "build\app\outputs\flutter-apk\app-release.apk"
Write-Host "====================================================================" -ForegroundColor Green
Write-Host "  🎉 Android (安卓) 生产安装包构建成功！" -ForegroundColor Green
Write-Host "  📁 安装包位置: $ApkPath" -ForegroundColor White
Write-Host "====================================================================" -ForegroundColor Green

if (Test-Path $ApkPath) {
    $seahorseRoot = (Resolve-Path (Join-Path $ScriptDir "..")).Path
    $globalDistAppsCandidate = Join-Path $ScriptDir "..\..\dist_apps"

    $localTarget = Join-Path $seahorseRoot "seahorse_app_latest.apk"
    $localVerTarget = Join-Path $seahorseRoot "seahorse_app-v$appVersion.apk"
    Copy-Item $ApkPath -Destination $localTarget -Force
    Copy-Item $ApkPath -Destination $localVerTarget -Force

    if ((-not $skipGlobalDist) -and (Test-Path $globalDistAppsCandidate)) {
        $globalDistApps = (Resolve-Path $globalDistAppsCandidate).Path
        $globalTarget = Join-Path $globalDistApps "seahorse_app-v$appVersion.apk"
        Copy-Item $ApkPath -Destination $globalTarget -Force
        Write-Host "  🚀 已同步分发至全局安装包中心: $globalTarget" -ForegroundColor Yellow
    }

    $fileItem = Get-Item $ApkPath
    $fileSizeMB = [math]::Round($fileItem.Length / 1MB, 2)
    Write-Host "  📦 安装包大小: ${fileSizeMB} MB" -ForegroundColor Cyan
    if (-not $isHeadless) {
        Write-Host "  正在为您在资源管理器中高亮定位安装包..." -ForegroundColor Gray
        Start-Process "explorer.exe" -ArgumentList "/select,`"$ApkPath`""
    }
} elseif (-not $isHeadless) {
    $OutputDir = Join-Path $ScriptDir "build\app\outputs\flutter-apk\"
    if (Test-Path $OutputDir) {
        Start-Process "explorer.exe" -ArgumentList "`"$OutputDir`""
    }
}

Write-Host ""
if (-not $isHeadless) {
    Read-Host "构建流程已完成，按 Enter 键退出..."
}
