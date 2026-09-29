# Automated Smoke Test Script
Write-Host "Running Nexus Smoke Tests..." -ForegroundColor Cyan

$endpoints = @(
    "http://localhost:8000/healthz",
    "http://localhost:8000/readyz",
    "http://localhost:8000/metrics",
    "http://localhost:8000/api/v1/info"
)

foreach ($ep in $endpoints) {
    try {
        $res = Invoke-WebRequest -Uri $ep -UseBasicParsing -TimeoutSec 5
        Write-Host "[PASS] $ep (Status: $($res.StatusCode))" -ForegroundColor Green
    } catch {
        Write-Host "[FAIL] $ep" -ForegroundColor Red
    }
}
