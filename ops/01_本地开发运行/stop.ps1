# ==============================================================================
# 海马智慧商业平台 - 本地服务一键停止脚本
# ==============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
try { $Host.UI.RawUI.WindowTitle = "Seahorse Smart Store - Stopper" } catch {}

Write-Host "=====================================================================" -ForegroundColor Yellow
Write-Host "         海马智慧商业 - 正在停止后端与前端服务..." -ForegroundColor Yellow
Write-Host "=====================================================================" -ForegroundColor Yellow
Write-Host ""

function Stop-PortProcess([int]$port, [string]$serviceName) {
    try {
        $conns = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
        if ($conns) {
            foreach ($c in $conns) {
                $pidToKill = $c.OwningProcess
                if ($pidToKill -gt 0) {
                    Write-Host "正在终止 $serviceName 进程 (PID: $pidToKill, 端口: $port)..." -ForegroundColor Cyan
                    try {
                        & taskkill.exe /F /T /PID $pidToKill 2>$null
                    } catch {
                        Stop-Process -Id $pidToKill -Force -ErrorAction SilentlyContinue
                    }
                }
            }
            Write-Host "[完成] $serviceName 已成功停止！" -ForegroundColor Green
        } else {
            Write-Host "[提示] $serviceName (端口: $port) 未运行。" -ForegroundColor Gray
        }
    } catch {
        Write-Host "[警告] 停止 $serviceName 时发生错误: $_" -ForegroundColor Red
    }
}

Stop-PortProcess -port 8082 -serviceName "后端微服务 (Spring Boot: 8082)"
Stop-PortProcess -port 3000 -serviceName "前端Web服务 (Vite: 3000)"

Write-Host ""
Write-Host "=====================================================================" -ForegroundColor Green
Write-Host " 本地所有相关服务进程已安全停止完毕。" -ForegroundColor Green
Write-Host "=====================================================================" -ForegroundColor Green
Start-Sleep -Seconds 1
