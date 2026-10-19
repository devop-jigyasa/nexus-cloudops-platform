from fastapi import status


def test_liveness_probe(client):
    response = client.get("/healthz")
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["status"] == "healthy"
    assert "service" in data


def test_readiness_probe_healthy(client, mock_redis):
    response = client.get("/readyz")
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["ready"] is True
    assert data["checks"]["redis"] == "connected"


def test_readiness_probe_unhealthy(client, monkeypatch):
    def fail_redis():
        raise ConnectionError("Redis is unreachable")

    monkeypatch.setattr("app.src.main.get_redis_client", fail_redis)
    response = client.get("/readyz")
    assert response.status_code == status.HTTP_503_SERVICE_UNAVAILABLE
    data = response.json()
    assert data["ready"] is False
    assert data["checks"]["redis"] == "unavailable"


def test_prometheus_metrics(client):
    response = client.get("/metrics")
    assert response.status_code == status.HTTP_200_OK
    assert b"http_requests_total" in response.content


def test_system_info(client):
    response = client.get("/api/v1/info")
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["status"] == "operational"
    assert "version" in data
    assert "hostname" in data


def test_cache_get_success(client, mock_redis):
    response = client.get("/api/v1/cache/demo-key")
    assert response.status_code == status.HTTP_200_OK
    assert response.json()["value"] == "sample_cache_value"


def test_cache_post_success(client, mock_redis):
    payload = {"key": "test_key", "value": "test_val", "ttl": 60}
    response = client.post("/api/v1/cache", json=payload)
    assert response.status_code == status.HTTP_200_OK
    assert response.json()["message"] == "Value stored successfully"


def test_root_redirect(client):
    response = client.get("/", follow_redirects=False)
    assert response.status_code == status.HTTP_307_TEMPORARY_REDIRECT
    assert response.headers["location"] == "/api/docs"
