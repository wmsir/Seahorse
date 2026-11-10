# ==============================================================================
# 海马智慧商业平台 - 本地全栈一键启动器
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
try { $Host.UI.RawUI.WindowTitle = "Seahorse Smart Store - Launcher" } catch {}

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "          海马智慧门店 (Seahorse Smart Store) 本地一键启动器" -ForegroundColor Cyan
Write-Host "          Slogan: 海马会员，记住每位好客。" -ForegroundColor Yellow
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host ""

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BackendBat = Join-Path $ScriptDir "run-backend.bat"
$FrontendBat = Join-Path $ScriptDir "run-frontend.bat"

if (-not (Test-Path $BackendBat)) {
    Write-Host "[错误] 未找到后端启动脚本: $BackendBat" -ForegroundColor Red
    Read-Host "按回车键退出..."
    exit 1
}

if (-not (Test-Path $FrontendBat)) {
    Write-Host "[错误] 未找到前端启动脚本: $FrontendBat" -ForegroundColor Red
    Read-Host "按回车键退出..."
    exit 1
}

# 1. 启动后端服务 (独立终端窗口)
Write-Host "[1/3] 正在拉起后端服务 (Spring Boot - 端口 8082)..." -ForegroundColor Green
Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "`"$BackendBat`""

# 2. 轮询等待后端健康接口响应 HTTP 200
Write-Host "[2/3] 正在检测后端服务健康状态，等待后端启动就绪..." -ForegroundColor Yellow
$backendReady = $false
$maxRetries = 60

for ($i = 1; $i -le $maxRetries; $i++) {
    Start-Sleep -Seconds 2
    try {
        $res = Invoke-RestMethod -Uri "http://localhost:8082/api/dashboard/stats" -Method Get -TimeoutSec 2 -ErrorAction Stop
        if ($res.code -eq 200 -or $res.data) {
            $backendReady = $true
            break
        }
    } catch {
        Write-Host "." -NoNewline -ForegroundColor Gray
    }
}

Write-Host ""
if ($backendReady) {
    Write-Host "[成功] 后端服务已成功启动并就绪 (端口 8082)！" -ForegroundColor Green
} else {
    Write-Host "[提示] 后端初始化尚未完全响应，继续拉起前端工程..." -ForegroundColor Yellow
}

# 3. 启动前端开发服务器 (独立终端窗口)
Write-Host "[3/3] 正在拉起 Web 前端工程 (Vite - 端口 3000)..." -ForegroundColor Green
Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "`"$FrontendBat`""

# 等待前端端口监听
Start-Sleep -Seconds 3

Write-Host ""
Write-Host "=====================================================================" -ForegroundColor Green
Write-Host " [全部启动完毕] 海马智慧门店系统全栈已在后台运行！" -ForegroundColor Green
Write-Host "  - 前端工作台访问地址: http://localhost:3000" -ForegroundColor Cyan
Write-Host "  - 后端微服务接口文档: http://localhost:8082/api" -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Green
Write-Host ""

try {
    Start-Process "http://localhost:3000"
} catch {
    Write-Host "请手动打开浏览器访问: http://localhost:3000" -ForegroundColor Yellow
}
