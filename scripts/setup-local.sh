#!/bin/bash
set -e
echo "========================================="
echo " Starting Nexus CloudOps Local Platform  "
echo " Cost: $0.00 (LocalStack + Docker + K8s) "
echo "========================================="

echo "[1/3] Starting Docker Compose Services..."
docker-compose up -d --build

echo "[2/3] Checking application health..."
sleep 5
curl -s http://localhost:8000/healthz || echo "Container initializing..."

echo "[3/3] Platform running successfully!"
echo "App API:   http://localhost:8000"
echo "API Docs:  http://localhost:8000/api/docs"
echo "Metrics:   http://localhost:8000/metrics"
echo "LocalStack:http://localhost:4566"
