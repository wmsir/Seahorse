# ==============================================================================
# 海马智慧商业平台 - 本地服务一键重启脚本
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
try { $Host.UI.RawUI.WindowTitle = "Seahorse Smart Store - Restart" } catch {}

Write-Host "=====================================================================" -ForegroundColor Magenta
Write-Host "         海马智慧商业 - 正在执行一键重启..." -ForegroundColor Magenta
Write-Host "=====================================================================" -ForegroundColor Magenta
Write-Host ""

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$StopPs1 = Join-Path $ScriptDir "stop.ps1"
$StartPs1 = Join-Path $ScriptDir "start.ps1"

Write-Host "[步骤 1] 正在停止旧有服务进程..." -ForegroundColor Yellow
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$StopPs1"

Start-Sleep -Seconds 2

Write-Host ""
Write-Host "[步骤 2] 正在拉起新服务进程..." -ForegroundColor Green
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$StartPs1"
