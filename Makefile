.PHONY: help app-install app-test app-lint docker-build local-up local-down tf-init tf-plan k8s-apply clean

help:
	@echo "Available commands:"
	@echo "  make app-install   Install application dependencies"
	@echo "  make app-test      Run unit tests with pytest"
	@echo "  make app-lint      Lint Python code with flake8 and black"
	@echo "  make docker-build  Build container image"
	@echo "  make local-up      Start local stack (Docker Compose)"
	@echo "  make local-down    Tear down local stack"
	@echo "  make tf-init       Initialize Terraform for LocalStack"
	@echo "  make tf-plan       Run Terraform plan on LocalStack"
	@echo "  make k8s-apply     Apply Kubernetes manifests"
	@echo "  make clean         Remove build artifacts and caches"

app-install:
	pip install -r app/requirements.txt -r app/requirements-dev.txt

app-test:
	pytest app/tests/ -v --cov=app/src

app-lint:
	flake8 app/src app/tests --max-line-length=100
	black --check app/src app/tests

docker-build:
	docker build -t nexus-cloudops:latest ./app

local-up:
	docker-compose up -d --build

local-down:
	docker-compose down -v

tf-init:
	cd terraform/environments/local && terraform init

tf-plan:
	cd terraform/environments/local && terraform plan

k8s-apply:
	kubectl apply -f k8s/

clean:
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	rm -rf .pytest_cache .coverage htmlcov
