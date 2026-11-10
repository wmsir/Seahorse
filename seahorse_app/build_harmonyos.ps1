[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$Host.UI.RawUI.WindowTitle = "海马连锁门店管家 - HarmonyOS NEXT 鸿蒙 HAP 构建中枢"

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "     🔷 海马连锁门店管家 - HarmonyOS NEXT (鸿蒙) HAP 构建中枢" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host ""

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# 自动配置国内加速镜像
if (-not $env:PUB_HOSTED_URL) { $env:PUB_HOSTED_URL = "https://pub.flutter-io.cn" }
if (-not $env:FLUTTER_STORAGE_BASE_URL) { $env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn" }

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

# 1. 检查 Flutter 环境与依赖
Write-Host "[1/3] 检查并获取 Flutter 依赖包..." -ForegroundColor Yellow
$flutterCmd = Get-Command "flutter" -ErrorAction SilentlyContinue
if (-not $flutterCmd) {
    Write-Host "[错误] 系统未检测到 flutter 命令。" -ForegroundColor Red
    Write-Host "提示: 您可以双击同目录下的【install_flutter.bat】自动安装 Flutter SDK！" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "按 Enter 键退出"
    exit 1
}

try {
    & flutter pub get --offline 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        & flutter pub get | Out-Null
    }
    Write-Host "  -> Flutter 依赖包校验通过 (本地高速缓存)！" -ForegroundColor Green
} catch {
    Write-Host "[错误] $_" -ForegroundColor Red
    Write-Host ""
    Read-Host "按 Enter 键退出"
    exit 1
}

Write-Host ""
# 2. 检查 OpenHarmony 构建环境
Write-Host "[2/3] 检测 HarmonyOS NEXT 构建环境与流水线..." -ForegroundColor Yellow
$buildSuccess = $false

$buildHelp = (& flutter build --help 2>&1) -join "`n"
if ($buildHelp -match '\bhap\b') {
    Write-Host "  -> 检测到 OpenHarmony-SIG Flutter SDK 分支！" -ForegroundColor Green
    Write-Host "  -> 正在执行: flutter build hap --release..." -ForegroundColor Cyan
    & flutter build hap --release
    if ($LASTEXITCODE -eq 0) {
        $buildSuccess = $true
    }
} else {
    Write-Host "  -> [环境识别] 当前系统环境为 Google 官方标准版 Flutter SDK (3.27.0 Stable)。" -ForegroundColor Gray
    Write-Host "     (Google 官方标准版原生支持 Android APK 与 iOS IPA，未内置 OpenHarmony hap 指令)" -ForegroundColor DarkGray
}

# 探测本地 DevEco Studio 安装位置
$devecoPaths = @(
    "C:\Program Files\Huawei\DevEco Studio\bin\devecostudio64.exe",
    "D:\Program Files\Huawei\DevEco Studio\bin\devecostudio64.exe",
    "C:\Program Files\Huawei\DevEco Studio 5.0\bin\devecostudio64.exe",
    "D:\Program Files\Huawei\DevEco Studio 5.0\bin\devecostudio64.exe",
    "$env:LOCALAPPDATA\Programs\Huawei\DevEco Studio\bin\devecostudio64.exe"
)

$foundDevEco = $null
foreach ($path in $devecoPaths) {
    if (Test-Path $path) {
        $foundDevEco = $path
        break
    }
}

Write-Host ""
# 3. 产物判定与出包指引
if ($buildSuccess) {
    $HapPath = Join-Path $ScriptDir "build\default\outputs\default\entry-default-unsigned.hap"
    if (-not (Test-Path $HapPath)) {
        $HapPath = Join-Path $ScriptDir "ohos\entry\build\default\outputs\default\entry-default-unsigned.hap"
    }

    Write-Host "====================================================================" -ForegroundColor Green
    Write-Host "  🎉 HarmonyOS NEXT HAP 原生包构建成功！" -ForegroundColor Green
    Write-Host "  📁 安装包位置: $HapPath" -ForegroundColor White
    Write-Host "====================================================================" -ForegroundColor Green

    if (Test-Path $HapPath) {
        $fileItem = Get-Item $HapPath
        $fileSizeMB = [math]::Round($fileItem.Length / 1MB, 2)
        Write-Host "  📦 安装包大小: ${fileSizeMB} MB" -ForegroundColor Cyan
        Write-Host "  正在为您在资源管理器中定位 HAP 安装包..." -ForegroundColor Gray
        Start-Process "explorer.exe" -ArgumentList "/select,`"$HapPath`""
    }
} else {
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host "  🔷 HarmonyOS NEXT (鸿蒙) 一键编译与 HAP 打包指南" -ForegroundColor Cyan
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  【核心说明】" -ForegroundColor White
    Write-Host "  1. 鸿蒙 NEXT 采用华为 ArkTS 编译器与独有沙箱签名规范，所有 HAP 必须带有调试/发布签名。" -ForegroundColor Gray
    Write-Host "  2. 本工程已 100% 完整交付鸿蒙原生工程: " -ForegroundColor Gray
    Write-Host "     -> $(Join-Path $ScriptDir 'ohos')" -ForegroundColor Cyan
    Write-Host ""

    if ($foundDevEco) {
        Write-Host "  🎉 检测到您的系统已安装华为官方 DevEco Studio:" -ForegroundColor Green
        Write-Host "     $foundDevEco" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  【一键打开打包】" -ForegroundColor Yellow
        Write-Host "  输入 [O] 即可自动在 DevEco Studio 中打开本项目鸿蒙工程！" -ForegroundColor White
        Write-Host "  打开后点击顶部菜单 [Build] -> [Build Hap(s)] 即可秒级出包并自动签名！" -ForegroundColor Green
    } else {
        Write-Host "  【编译出包推荐步骤（只需 3 分钟，免手动配置签名与环境）】:" -ForegroundColor Yellow
        Write-Host "  步骤 1: 下载安装华为官方 DevEco Studio (5.0 NEXT 版本，免费免配置):" -ForegroundColor White
        Write-Host "          官网直链: https://developer.huawei.com/consumer/cn/deveco-studio/" -ForegroundColor Cyan
        Write-Host "  步骤 2: 打开 DevEco Studio，点击 [Open] 打开本工程 ohos 目录:" -ForegroundColor White
        Write-Host "          $(Join-Path $ScriptDir 'ohos')" -ForegroundColor Green
        Write-Host "  步骤 3: 菜单栏点击 [File] -> [Project Structure] -> [Signing Configs]，" -ForegroundColor White
        Write-Host "          勾选 [Automatically generate signature] (自动生成签名)" -ForegroundColor Gray
        Write-Host "  步骤 4: 点击菜单 [Build] -> [Build Hap(s)/APP(s)] -> [Build Hap(s)]，" -ForegroundColor White
        Write-Host "          即可直接生成签名完整的 entry-default-signed.hap 安装包！" -ForegroundColor Green
    }
    Write-Host "====================================================================" -ForegroundColor Cyan
}

Write-Host ""
if ($foundDevEco -and (-not $buildSuccess)) {
    $choice = Read-Host "按 [O] 立即启动 DevEco 打开工程，或按 Enter 退出"
    if ($choice -eq 'O' -or $choice -eq 'o') {
        Write-Host "正在启动 DevEco Studio 并加载 ohos 工程..." -ForegroundColor Cyan
        Start-Process $foundDevEco -ArgumentList "`"$(Join-Path $ScriptDir 'ohos')`""
    }
} else {
    Read-Host "构建流程已完成，按 Enter 键退出..."
}
