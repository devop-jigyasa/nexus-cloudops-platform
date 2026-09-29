#!/bin/bash
echo "Running Nexus Smoke Tests..."
endpoints=(
  "http://localhost:8000/healthz"
  "http://localhost:8000/readyz"
  "http://localhost:8000/metrics"
  "http://localhost:8000/api/v1/info"
)

for ep in "${endpoints[@]}"; do
  status=$(curl -s -o /dev/null -w "%{http_code}" "$ep")
  if [ "$status" == "200" ]; then
    echo "[PASS] $ep (Status: 200)"
  else
    echo "[FAIL] $ep (Status: $status)"
  fi
done
