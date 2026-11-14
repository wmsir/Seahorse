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
        $pids = @($conns | Where-Object { $_.State -eq 'Listen' -and $_.OwningProcess -gt 4 } | Select-Object -ExpandProperty OwningProcess -Unique)
        if ($pids.Count -gt 0) {
            foreach ($pidToKill in $pids) {
                Write-Host "正在终止 $serviceName 进程 (PID: $pidToKill, 端口: $port)..." -ForegroundColor Cyan
                try {
                    & taskkill.exe /F /T /PID $pidToKill 2>$null
                } catch {
                    Stop-Process -Id $pidToKill -Force -ErrorAction SilentlyContinue
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

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DotEnvFile = Join-Path (Resolve-Path (Join-Path $ScriptDir "..\..")).Path ".env"
$BackendPort = 8082
if (-not [string]::IsNullOrWhiteSpace($env:SERVER_PORT)) {
    [void][int]::TryParse($env:SERVER_PORT.Trim(), [ref]$BackendPort)
} elseif (Test-Path $DotEnvFile) {
    foreach ($rawLine in (Get-Content -Path $DotEnvFile -Encoding UTF8)) {
        $line = $rawLine.Trim()
        if ($line -match "^SERVER_PORT\s*=\s*(\d+)") {
            $BackendPort = [int]$Matches[1]
        }
    }
}

Stop-PortProcess -port $BackendPort -serviceName "后端微服务 (Spring Boot: $BackendPort)"
Stop-PortProcess -port 3000 -serviceName "前端Web服务 (Vite: 3000)"

Write-Host ""
Write-Host "=====================================================================" -ForegroundColor Green
Write-Host " 本地所有相关服务进程已安全停止完毕。" -ForegroundColor Green
Write-Host "=====================================================================" -ForegroundColor Green
Start-Sleep -Seconds 1
