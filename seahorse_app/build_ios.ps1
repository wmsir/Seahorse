[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$Host.UI.RawUI.WindowTitle = "海马连锁门店管家 - iOS 构建与环境准备"

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "       🍏 海马连锁门店管家 - iOS (苹果) 运行环境与打包指引" -ForegroundColor Cyan
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

# 1. 检查 Flutter 环境
Write-Host "[1/3] 检查并获取 Flutter 依赖包..." -ForegroundColor Yellow
$flutterCmd = Get-Command "flutter" -ErrorAction SilentlyContinue
if (-not $flutterCmd) {
    Write-Host "[错误] 系统未检测到 flutter 命令。" -ForegroundColor Red
    Write-Host "提示: 您可以双击同目录下的【install_flutter.bat】自动极速安装 Flutter SDK！" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "按 Enter 键退出"
    exit 1
}

try {
    flutter pub get
    if ($LASTEXITCODE -ne 0) {
        throw "flutter pub get 执行失败，退出码: $LASTEXITCODE"
    }
    Write-Host "  -> Flutter 依赖包获取成功！" -ForegroundColor Green
} catch {
    Write-Host "[错误] $_" -ForegroundColor Red
    Write-Host ""
    Read-Host "按 Enter 键退出"
    exit 1
}

Write-Host ""
# 2. 检查 iOS 宿主工程完整性
Write-Host "[2/3] 检查 iOS 原生工程与 Podfile 依赖..." -ForegroundColor Yellow
$iosDir = Join-Path $ScriptDir "ios"
if (Test-Path $iosDir) {
    Write-Host "  -> 检测到完整 iOS 宿主工程 (Podfile, Info.plist, AppDelegate.swift)" -ForegroundColor Green
} else {
    Write-Host "  -> 正在生成 iOS 宿主结构..." -ForegroundColor Gray
    flutter create . --platforms=ios | Out-Null
}

Write-Host ""
# 3. 跨平台打包与运行指引
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "  【Apple 官方平台编译要求】" -ForegroundColor White
Write-Host "  由于 Apple 官方生态限制，最终的 iOS 真机包 (.ipa / Runner.app) 必须在" -ForegroundColor Gray
Write-Host "  macOS 系统或配备 Xcode 编译环境的机器上完成签名与归档。" -ForegroundColor Gray
Write-Host ""
Write-Host "  【方案 1: 在 Mac 电脑上直接一键打包】" -ForegroundColor Yellow
Write-Host "    终端运行同目录下的 Shell 脚本:" -ForegroundColor Gray
Write-Host "    chmod +x build_ios.sh && ./build_ios.sh" -ForegroundColor Cyan
Write-Host ""
Write-Host "  【方案 2: 使用 Xcode 连接真机可视化调试】" -ForegroundColor Yellow
Write-Host "    在 Mac 上双击打开: $(Join-Path $iosDir 'Runner.xcworkspace')" -ForegroundColor Cyan
Write-Host ""
Write-Host "  【方案 3: 云端 CI/CD 自动化构建】" -ForegroundColor Yellow
Write-Host "    代码提交至 GitHub / Gitee 后，可直接通过 macOS Runner 自动运行:" -ForegroundColor Gray
Write-Host "    flutter build ipa --release" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan

Write-Host ""
Read-Host "环境自检完成，按 Enter 键退出..."
