import pytest
from unittest.mock import MagicMock
from fastapi.testclient import TestClient
from app.src.main import app


@pytest.fixture
def mock_redis(monkeypatch):
    mock = MagicMock()
    mock.ping.return_value = True
    mock.get.return_value = b"sample_cache_value"
    mock.setex.return_value = True
    monkeypatch.setattr("app.src.main.get_redis_client", lambda: mock)
    return mock


@pytest.fixture
def client():
    return TestClient(app)
