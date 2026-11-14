// Nexus CloudOps Platform // Client-Side Engine

// Dynamically resolve API Base for Decoupled Vercel Edge Frontend & Render Backend
const API_BASE = (window.location.hostname.includes("vercel.app") || window.location.hostname === "localhost") && window.location.port !== "8000"
    ? (window.location.hostname === "localhost" ? "http://localhost:8000" : "https://nexus-cloudops-platform.onrender.com")
    : "";

let retryInterval = null;
let retryCountDown = 5;
let isBackendAwake = false;

// --- Helper: Fetch with Timeout ---
async function fetchWithTimeout(resource, options = {}) {
    const { timeout = 4000 } = options;
    const controller = new AbortController();
    const id = setTimeout(() => controller.abort(), timeout);
    try {
        const response = await fetch(resource, {
            ...options,
            signal: controller.signal
        });
        clearTimeout(id);
        return response;
    } catch (err) {
        clearTimeout(id);
        throw err;
    }
}

// --- Check Backend Health (Cold Start Detector & Telemetry Sync) ---
async function checkBackendHealth(manual = false) {
    const banner = document.getElementById("cold-start-banner");
    const dot = document.getElementById("backend-dot");
    const label = document.getElementById("backend-label");
    const latencyElem = document.getElementById("backend-latency");

    const tStart = performance.now();
    try {
        const res = await fetchWithTimeout(`${API_BASE}/healthz`, { timeout: 4500 });
        const tDuration = Math.round(performance.now() - tStart);

        if (res.ok) {
            const data = await res.json();
            isBackendAwake = true;

            // Update status badges
            if (banner) banner.style.display = "none";
            if (dot) dot.className = "dot-pulse online";
            if (label) label.innerText = "RENDER ONLINE";
            if (latencyElem) latencyElem.innerText = `${tDuration} ms`;

            // Update telemetry cards
            document.getElementById("liveness-badge").innerText = "200 OK";
            document.getElementById("liveness-badge").className = "card-status-badge badge-green";
            document.getElementById("liveness-metric").innerText = "HEALTHY";
            if (data.service) {
                document.getElementById("liveness-service").innerText = data.service;
            }
            document.getElementById("rtt-metric").innerText = `${tDuration} ms`;

            // Stop auto-retries once awake
            if (retryInterval) {
                clearInterval(retryInterval);
                retryInterval = null;
            }

            // Sync downstream probes
            syncReadinessProbe();
            syncSystemInfo();
            return;
        }
        throw new Error("HTTP " + res.status);
    } catch (err) {
        // Backend is sleeping on Render Free Tier or network error
        isBackendAwake = false;
        if (banner) banner.style.display = "block";
        if (dot) dot.className = "dot-pulse";
        if (label) label.innerText = "RENDER WAKING UP...";
        if (latencyElem) latencyElem.innerText = "Cold Start";

        document.getElementById("liveness-badge").innerText = "503 SLEEP";
        document.getElementById("liveness-badge").className = "card-status-badge badge-amber";
        document.getElementById("liveness-metric").innerText = "WAKING UP";

        // Start countdown to retry
        startRetryCycle();
    }
}

// --- Readiness Probe Sync ---
async function syncReadinessProbe() {
    try {
        const res = await fetch(`${API_BASE}/readyz`);
        const data = await res.json();
        const rBadge = document.getElementById("readiness-badge");
        const rMetric = document.getElementById("readiness-metric");
        const rStatus = document.getElementById("redis-status");

        if (data.ready) {
            rBadge.innerText = "READY";
            rBadge.className = "card-status-badge badge-green";
            rMetric.innerText = "CONNECTED";
            rStatus.innerText = "CONNECTED";
            rStatus.className = "mono text-green";
        } else {
            rBadge.innerText = "PARTIAL";
            rBadge.className = "card-status-badge badge-amber";
            rMetric.innerText = "IN-MEMORY";
            rStatus.innerText = data.checks && data.checks.redis ? data.checks.redis : "in-memory fallback";
            rStatus.className = "mono text-amber";
        }
    } catch (e) {
        console.warn("Readiness probe check failed:", e);
    }
}

// --- System Info Sync ---
async function syncSystemInfo() {
    try {
        const res = await fetch(`${API_BASE}/api/v1/info`);
        if (res.ok) {
            const data = await res.json();
            if (data.hostname) document.getElementById("hostname-metric").innerText = data.hostname;
            if (data.environment) document.getElementById("env-metric").innerText = data.environment;
            if (data.version) document.getElementById("version-badge").innerText = `v${data.version}`;
        }
    } catch (e) {
        console.warn("System info sync failed:", e);
    }
}

// --- Retry Loop for Cold Start Wake-Up ---
function startRetryCycle() {
    if (retryInterval) return;
    retryCountDown = 5;
    const timerElem = document.getElementById("retry-timer");
    const bar = document.getElementById("cold-start-progress-bar");

    retryInterval = setInterval(() => {
        retryCountDown--;
        if (timerElem) timerElem.innerText = `${retryCountDown}s`;
        if (bar) bar.style.width = `${((5 - retryCountDown) / 5) * 100}%`;

        if (retryCountDown <= 0) {
            retryCountDown = 5;
            checkBackendHealth();
        }
    }, 1000);
}

// --- Preset Scenario Loader ---
function loadPreset(key, val) {
    document.getElementById("cache-key-input").value = key;
    document.getElementById("cache-val-input").value = val;
    document.getElementById("read-key-input").value = key;
}

// --- Write to Redis Cache ---
async function handleWriteCache(e) {
    e.preventDefault();
    const key = document.getElementById("cache-key-input").value.trim();
    const value = document.getElementById("cache-val-input").value.trim();
    const ttl = parseInt(document.getElementById("cache-ttl-input").value, 10) || 3600;
    const btn = document.getElementById("write-btn");
    const out = document.getElementById("bench-output");
    const rtt = document.getElementById("bench-rtt");

    if (!key || !value) return;

    btn.disabled = true;
    btn.innerText = "Storing...";
    out.innerText = "// Sending POST request to /api/v1/cache...";

    const tStart = performance.now();
    try {
        const res = await fetch(`${API_BASE}/api/v1/cache`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ key, value, ttl })
        });
        const duration = Math.round(performance.now() - tStart);
        const data = await res.json();

        rtt.innerText = `Round-trip: ${duration} ms (HTTP ${res.status})`;
        out.innerText = JSON.stringify(data, null, 2);

        // Pre-fill read key for verification
        document.getElementById("read-key-input").value = key;
    } catch (err) {
        out.innerText = `// Connection error: ${err.message}\nMake sure Render backend is awake!`;
        rtt.innerText = "Request Failed";
    } finally {
        btn.disabled = false;
        btn.innerText = "Set Cache Item";
    }
}

// --- Read from Redis Cache ---
async function handleReadCache(e) {
    e.preventDefault();
    const key = document.getElementById("read-key-input").value.trim();
    const btn = document.getElementById("read-btn");
    const out = document.getElementById("bench-output");
    const rtt = document.getElementById("bench-rtt");

    if (!key) return;

    btn.disabled = true;
    btn.innerText = "Querying...";
    out.innerText = `// Sending GET request to /api/v1/cache/${key}...`;

    const tStart = performance.now();
    try {
        const res = await fetch(`${API_BASE}/api/v1/cache/${encodeURIComponent(key)}`);
        const duration = Math.round(performance.now() - tStart);
        const data = await res.json();

        rtt.innerText = `Sub-ms Query: ${duration} ms (HTTP ${res.status})`;
        out.innerText = JSON.stringify(data, null, 2);
    } catch (err) {
        out.innerText = `// Connection error: ${err.message}\nMake sure Render backend is awake!`;
        rtt.innerText = "Query Failed";
    } finally {
        btn.disabled = false;
        btn.innerText = "Query Redis";
    }
}

// --- Tab Switcher ---
function switchTab(tabId) {
    document.querySelectorAll(".tab-btn").forEach(btn => btn.classList.remove("active"));
    document.querySelectorAll(".tab-content").forEach(c => c.classList.remove("active"));

    const activeContent = document.getElementById(`tab-${tabId}`);
    if (activeContent) activeContent.classList.add("active");

    // Activate matching button
    const buttons = document.querySelectorAll(".tab-btn");
    if (tabId === "arch") buttons[0].classList.add("active");
    if (tabId === "pipeline") buttons[1].classList.add("active");
    if (tabId === "reports") buttons[2].classList.add("active");
}

// Initialize on page load
window.addEventListener("DOMContentLoaded", () => {
    checkBackendHealth();
    // Poll every 30s to keep fresh telemetry
    setInterval(() => {
        if (isBackendAwake) {
            checkBackendHealth();
        }
    }, 30000);
});
