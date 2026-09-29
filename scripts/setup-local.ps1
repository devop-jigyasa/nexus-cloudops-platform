# PowerShell Local Environment Orchestrator
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Starting Nexus CloudOps Local Platform  " -ForegroundColor Cyan
Write-Host " Cost: $0.00 (LocalStack + Docker + K8s) " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan

# 1. Start Docker Compose Stack
Write-Host "`n[1/3] Spinning up App, Redis & LocalStack..." -ForegroundColor Yellow
docker-compose up -d --build

# 2. Verify Endpoints
Write-Host "`n[2/3] Verifying endpoints..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

try {
    $res = Invoke-RestMethod -Uri "http://localhost:8000/healthz" -TimeoutSec 5
    Write-Host ">> Nexus App Health: OK" -ForegroundColor Green
} catch {
    Write-Host ">> Waiting for Nexus App container..." -ForegroundColor Red
}

Write-Host "`n[3/3] Ready! Access services at:" -ForegroundColor Yellow
Write-Host "  * App API:        http://localhost:8000" -ForegroundColor Cyan
Write-Host "  * API Docs:       http://localhost:8000/api/docs" -ForegroundColor Cyan
Write-Host "  * Metrics:        http://localhost:8000/metrics" -ForegroundColor Cyan
Write-Host "  * LocalStack AWS: http://localhost:4566" -ForegroundColor Cyan
