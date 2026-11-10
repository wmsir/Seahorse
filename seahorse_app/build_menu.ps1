[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$Host.UI.RawUI.WindowTitle = "海马连锁门店管家 - 多端 APP 构建控制台"

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

while ($true) {
    Clear-Host
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host "         🚀 海马连锁门店管家 APP 多端一键构建控制台" -ForegroundColor Cyan
    Write-Host "====================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   [1] 📱 构建 Android (安卓) APK 生产安装包" -ForegroundColor Green
    Write-Host "   [2] 🔷 构建 HarmonyOS NEXT (鸿蒙) HAP 原生安装包" -ForegroundColor Blue
    Write-Host "   [3] 🍏 构建 iOS (苹果) 运行环境与打包指引" -ForegroundColor Magenta
    Write-Host "   [4] 🧹 全平台依赖深度清理与重装 (flutter clean + pub get)" -ForegroundColor Yellow
    Write-Host "   [0] 📥 自动化极速安装 Flutter 3.x SDK 及依赖" -ForegroundColor White
    Write-Host "   [5] 🚪 退出控制台" -ForegroundColor Gray
    Write-Host ""
    Write-Host "====================================================================" -ForegroundColor Cyan
    
    $choice = Read-Host "请输入序号 [0-5]"
    
    switch ($choice) {
        "1" {
            & (Join-Path $ScriptDir "build_android.ps1")
        }
        "2" {
            & (Join-Path $ScriptDir "build_harmonyos.ps1")
        }
        "3" {
            & (Join-Path $ScriptDir "build_ios.ps1")
        }
        "4" {
            Write-Host ""
            Write-Host "正在清理构建缓存与重新获取依赖..." -ForegroundColor Yellow
            flutter clean
            flutter pub get
            Write-Host "依赖重置完成！" -ForegroundColor Green
            Start-Sleep -Seconds 2
        }
        "0" {
            & (Join-Path $ScriptDir "setup_flutter.ps1")
        }
        "5" {
            Write-Host "感谢使用，再见！" -ForegroundColor Gray
            exit 0
        }
        default {
            Write-Host "输入无效，请输入 0 到 5 之间的数字。" -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
