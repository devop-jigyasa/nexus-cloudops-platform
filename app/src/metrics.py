from prometheus_client import Counter, Histogram, Gauge

REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total number of HTTP requests processed",
    ["method", "endpoint", "status"],
)

REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency distribution in seconds",
    ["method", "endpoint"],
    buckets=[0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0],
)

ACTIVE_CONNECTIONS = Gauge(
    "nexus_active_connections",
    "Current active client connections in process",
)

SYSTEM_INFO = Gauge(
    "nexus_app_build_info",
    "Application release metadata",
    ["version", "environment"],
)
