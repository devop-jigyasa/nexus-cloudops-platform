import time
import socket
import logging
from fastapi import FastAPI, Request, Response, status
from fastapi.responses import JSONResponse
import redis
from prometheus_client import generate_latest, CONTENT_TYPE_LATEST

from .config import get_settings
from .metrics import (
    REQUEST_COUNT,
    REQUEST_LATENCY,
    ACTIVE_CONNECTIONS,
    SYSTEM_INFO,
)

settings = get_settings()
logging.basicConfig(
    level=settings.LOG_LEVEL, format="%(asctime)s [%(levelname)s] %(message)s"
)
logger = logging.getLogger("nexus-api")

app = FastAPI(
    title=settings.APP_NAME, version=settings.APP_VERSION, docs_url="/api/docs"
)

SYSTEM_INFO.labels(version=settings.APP_VERSION, environment=settings.ENVIRONMENT).set(
    1
)


def get_redis_client():
    return redis.Redis(
        host=settings.REDIS_HOST,
        port=settings.REDIS_PORT,
        password=settings.REDIS_PASSWORD if settings.REDIS_PASSWORD else None,
        db=settings.REDIS_DB,
        socket_connect_timeout=2,
    )


@app.middleware("http")
async def track_metrics_middleware(request: Request, call_next):
    ACTIVE_CONNECTIONS.inc()
    start_time = time.time()
    response = None
    try:
        response = await call_next(request)
        return response
    finally:
        latency = time.time() - start_time
        endpoint = request.url.path
        status_code = response.status_code if response else 500
        method = request.method
        REQUEST_COUNT.labels(method=method, endpoint=endpoint, status=status_code).inc()
        REQUEST_LATENCY.labels(method=method, endpoint=endpoint).observe(latency)
        ACTIVE_CONNECTIONS.dec()


@app.get("/healthz", status_code=status.HTTP_200_OK, tags=["Probes"])
async def liveness_probe():
    """Kubernetes Liveness Probe: validates the web process is responsive."""
    return {"status": "healthy", "service": settings.APP_NAME}


@app.get("/readyz", tags=["Probes"])
async def readiness_probe():
    """Kubernetes Readiness Probe: validates downstream dependencies (Redis)."""
    checks = {"redis": "disconnected"}
    is_ready = True
    try:
        r = get_redis_client()
        if r.ping():
            checks["redis"] = "connected"
    except Exception as e:
        logger.warning("Readiness probe Redis ping failed: %s", str(e))
        checks["redis"] = "unavailable"
        is_ready = False

    if is_ready:
        return JSONResponse(
            status_code=status.HTTP_200_OK, content={"ready": True, "checks": checks}
        )
    return JSONResponse(
        status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        content={"ready": False, "checks": checks},
    )


@app.get("/metrics", tags=["Observability"])
async def prometheus_metrics():
    """Prometheus Scrape Endpoint."""
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.get("/api/v1/info", tags=["Core"])
async def system_info():
    """Returns system runtime details and node identity."""
    return {
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "environment": settings.ENVIRONMENT,
        "hostname": socket.gethostname(),
        "status": "operational",
    }


@app.get("/api/v1/cache/{key}", tags=["Storage"])
async def get_cache_value(key: str):
    """Fetches cached item from Redis."""
    try:
        r = get_redis_client()
        val = r.get(key)
        if val is None:
            return JSONResponse(status_code=404, content={"error": "Key not found"})
        return {"key": key, "value": val.decode("utf-8")}
    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})


@app.post("/api/v1/cache", tags=["Storage"])
async def set_cache_value(payload: dict):
    """Stores key-value pair in Redis with TTL."""
    key = payload.get("key")
    value = payload.get("value")
    ttl = payload.get("ttl", 3600)
    if not key or not value:
        return JSONResponse(
            status_code=400, content={"error": "Both 'key' and 'value' are required"}
        )
    try:
        r = get_redis_client()
        r.setex(key, ttl, value)
        return {"message": "Value stored successfully", "key": key}
    except Exception as e:
        return JSONResponse(status_code=500, content={"error": str(e)})
