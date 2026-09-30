# Nexus CloudOps Platform 🚀
> **Enterprise-Grade Cloud Infrastructure, DevSecOps CI/CD, Kubernetes Orchestration & Observability Platform**

[![CI Pipeline](https://img.shields.io/badge/CI%2FCD-GitHub_Actions-blue?logo=github-actions)](.github/workflows/ci.yml)
[![Terraform](https://img.shields.io/badge/IaC-Terraform_1.5+-purple?logo=terraform)](terraform/)
[![Kubernetes](https://img.shields.io/badge/Orchestration-Kubernetes_%26_Helm-326CE5?logo=kubernetes)](k8s/)
[![Security](https://img.shields.io/badge/DevSecOps-Trivy_Hardened-orange?logo=aqua)](.github/workflows/ci.yml)
[![LocalStack](https://img.shields.io/badge/Zero_Cost-LocalStack_AWS-00D2B4?logo=amazonaws)](terraform/environments/local/)
[![Observability](https://img.shields.io/badge/Metrics-Prometheus_%26_Grafana-E6522C?logo=prometheus)](observability/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 🌟 Overview & Engineering Highlights

**Nexus CloudOps** is an end-to-end cloud platform engineering project demonstrating real-world production DevOps practices without incurring paid cloud costs. 

Traditional cloud architectures often introduce unnecessary friction and significant cloud bills during local development and testing. **Nexus CloudOps solves this through complete Environment Parity**:
* **$0.00 Cloud Spend:** Uses **LocalStack** to emulate AWS VPC, Subnets, IAM, and S3 locally, allowing 100% of the Terraform infrastructure code to be planned, applied, and verified locally for free.
* **Dual-Target IaC:** The exact same Terraform code switches between LocalStack (`terraform/environments/local`) and live AWS (`terraform/environments/aws`) with clean modular separation.
* **Container Hardening & DevSecOps:** Multi-stage Docker builds creating minimal attack surface with non-root security contexts (`UID 10001`), integrated with **Aqua Security Trivy** vulnerability scanning.
* **Production Kubernetes Delivery:** Native manifests and a parameterized **Helm chart** with Horizontal Pod Autoscaler (HPA), rolling updates (`maxSurge: 1`, `maxUnavailable: 0`), and HTTP liveness/readiness probes.
* **Complete Observability:** Prometheus metric scrapers collecting custom service counters, latency histograms, and alert rules integrated with pre-provisioned Grafana telemetry dashboards.

---

## 🏗️ Architecture Blueprint

```mermaid
graph TD
    subgraph Client & Ingress
        Users([HTTP Traffic]) --> Ingress[NGINX Ingress Controller]
    end

    subgraph Kubernetes Cluster (Minikube / Kind / EKS)
        Ingress --> K8sSvc[Service: nexus-app-service:80]
        K8sSvc --> HPA[Horizontal Pod Autoscaler (2-10 pods)]
        HPA --> Pod1[Nexus Pod 1]
        HPA --> Pod2[Nexus Pod 2]
        HPA --> Pod3[Nexus Pod N]
    end

    subgraph Caching & Persistence
        Pod1 & Pod2 & Pod3 --> Redis[(Redis 7 Cluster)]
        Pod1 & Pod2 & Pod3 --> LocalStack[(LocalStack / AWS S3 & DynamoDB)]
    end

    subgraph Telemetry & DevSecOps
        Prometheus[Prometheus Monitoring] -.->|Scrapes /metrics| Pod1 & Pod2 & Pod3
        Prometheus --> Alertmanager[Alertmanager Notification Engine]
        Grafana[Grafana Dashboards] -->|Queries| Prometheus
        Trivy[Trivy DevSecOps] -.->|Vulnerability Gate| Pod1
    end
```

---

## 📂 Repository Structure

```
nexus-cloudops-platform/
├── .github/workflows/
│   └── ci.yml                     # Multi-stage DevSecOps pipeline
├── app/
│   ├── src/
│   │   ├── main.py                # FastAPI microservice with probes & metrics
│   │   ├── config.py              # Environment configuration loader
│   │   └── metrics.py             # Prometheus metrics definitions
│   ├── tests/
│   │   ├── test_api.py            # Automated Pytest test suite
│   │   └── conftest.py            # Test fixtures and Redis mocks
│   ├── Dockerfile                 # Hardened multi-stage build (non-root)
│   └── requirements.txt
├── terraform/
│   ├── modules/
│   │   ├── vpc/                   # VPC, Subnets, IGW, Route tables
│   │   ├── security/              # Fine-grained security groups
│   │   ├── s3/                    # S3 bucket with encryption & versioning
│   │   └── iam/                   # Least-privilege IAM roles and policies
│   └── environments/
│       ├── local/                 # LocalStack provider config ($0 cost)
│       └── aws/                   # Production AWS provider config
├── k8s/
│   ├── 00-namespace.yaml          # Isolated namespace
│   ├── 01-configmap.yaml          # ConfigMap
│   ├── 02-secrets.yaml            # Secret management
│   ├── 03-deployment.yaml         # App deployment with probes & limits
│   ├── 04-service.yaml            # ClusterIP service
│   ├── 05-ingress.yaml            # Ingress rules
│   └── 06-hpa.yaml                # Autoscaling policy
├── charts/
│   └── nexus-platform/            # Production Helm Chart
├── observability/
│   ├── prometheus/                # Scrape configs and alert rules
│   ├── alertmanager/              # Alert routing configuration
│   └── grafana/                   # Provisioned telemetry dashboards
├── scripts/
│   ├── setup-local.ps1            # Windows automated launch script
│   └── setup-local.sh             # Linux/macOS launch script
├── docker-compose.yml             # Local orchestration stack
├── Makefile                       # Developer command shortcuts
└── README.md
```

---

## ⚡ Quickstart (100% Free Local Run)

### Prerequisites
* Docker Desktop & Docker Compose
* Git

### 1. Launch the Stack
Clone the repository and run the setup script:

```bash
# Windows PowerShell
.\scripts\setup-local.ps1

# Linux / macOS
./scripts/setup-local.sh
```

Or using Docker Compose directly:
```bash
docker-compose up -d --build
```

### 2. Verify Endpoints
| Component | Local URL | Description |
| :--- | :--- | :--- |
| **Microservice API** | http://localhost:8000 | Core REST Service |
| **Interactive API Docs**| http://localhost:8000/api/docs | Swagger UI Documentation |
| **Liveness Probe** | http://localhost:8000/healthz | Kubernetes Health Check |
| **Readiness Probe** | http://localhost:8000/readyz | Checks Redis Dependency |
| **Prometheus Metrics**| http://localhost:8000/metrics | Scraped by Prometheus |
| **LocalStack AWS** | http://localhost:4566 | Mocked AWS Services |

---

## ☁️ Zero-Cost Infrastructure as Code (Terraform)

Deploy the AWS VPC, S3, and IAM architecture to LocalStack without generating cloud bills:

```bash
cd terraform/environments/local
terraform init
terraform plan
terraform apply -auto-approve
```

To switch to production AWS, simply navigate to `terraform/environments/aws` and configure your AWS credentials.

---

## ☸️ Kubernetes & Helm Deployment

Deploy to Minikube, Kind, or Docker Desktop Kubernetes:

```bash
# Apply raw Kubernetes manifests
kubectl apply -f k8s/

# Or deploy using the Helm chart
helm upgrade --install nexus-release charts/nexus-platform \
  --namespace nexus-cloudops \
  --create-namespace
```

---

## 🛡️ DevSecOps CI/CD Pipeline

The `.github/workflows/ci.yml` pipeline runs automatically on pull requests and pushes to `main`:
1. **Code Quality:** Flake8 and Black code formatting checks.
2. **Automated Testing:** Pytest unit and integration test coverage.
3. **Security Vulnerability Scanning:** Aqua Security Trivy scans the repo and IaC for CVEs, exposed credentials, and misconfigurations.
4. **Container Build & Security:** Builds multi-stage Docker image and executes image vulnerability inspection.
5. **Helm Validation:** `helm lint` and `helm template` dry-run validation.

---

## 🚀 Key Architecture & Production Capabilities

* **Environment Parity & Zero Cost:** Modular Terraform supporting LocalStack for $0 local emulation and seamless transition to production AWS (VPC, Subnets, IAM, S3).
* **Production Kubernetes Orchestration:** Native manifests and parameterized Helm chart featuring Horizontal Pod Autoscaling (HPA), zero-downtime rolling updates (`maxSurge: 1`, `maxUnavailable: 0`), and separate `/healthz` and `/readyz` probes.
* **Hardened DevSecOps Automation:** GitHub Actions CI/CD integrating automated unit testing, Aqua Security Trivy vulnerability scanning, and Docker multi-stage builds.
* **Telemetry & Observability:** Prometheus metric scrapers capturing service throughput, p95 latency histograms, custom error alerts, and Grafana telemetry dashboards.

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
