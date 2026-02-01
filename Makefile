.PHONY: help install up down restart logs clean pre-commit-install pre-commit-update pre-commit-run generate-self-signed-certs

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## Install pre-commit hooks
	@if command -v pipx >/dev/null 2>&1; then \
		echo "Installing pre-commit using pipx..."; \
		pipx install pre-commit; \
	elif command -v brew >/dev/null 2>&1; then \
		echo "Installing pre-commit using Homebrew..."; \
		brew install pre-commit; \
	else \
		echo "Neither pipx nor brew found. Please install pre-commit manually."; \
		exit 1; \
	fi
	@pre-commit install
	@echo "Pre-commit hooks installed successfully!"

pre-commit-install: install ## Alias for install

pre-commit-update: ## Update pre-commit hooks to latest versions
	@if command -v pipx >/dev/null 2>&1; then \
		echo "Updating pre-commit using pipx..."; \
		pipx upgrade pre-commit; \
	elif command -v brew >/dev/null 2>&1; then \
		echo "Updating pre-commit using Homebrew..."; \
		brew upgrade pre-commit; \
	else \
		echo "Neither pipx nor brew found. Please update pre-commit manually."; \
		exit 1; \
	fi
	@pre-commit autoupdate
	@echo "Pre-commit hooks updated successfully!"

pre-commit: ## Run pre-commit checks on all files
	@pre-commit run --all-files

pre-commit-all: ## Run pre-commit checks on all files
	@pre-commit run --all-files

up: ## Start all services
	docker compose up -d

down: ## Stop all services
	docker compose down

restart: ## Restart all services
	docker compose restart

logs: ## Follow logs from all services
	docker compose logs -f

logs-grafana: ## Follow Grafana logs
	docker compose logs -f grafana

logs-loki: ## Follow Loki logs
	docker compose logs -f loki

logs-prometheus: ## Follow Prometheus logs
	docker compose logs -f prometheus

logs-promtail: ## Follow Promtail logs
	docker compose logs -f promtail

logs-tempo: ## Follow Tempo logs
	docker compose logs -f tempo

ps: ## Show running containers
	docker compose ps

clean: ## Stop and remove all containers, networks, and volumes
	docker compose down -v

rebuild: ## Rebuild and restart all services
	docker compose up -d --build

validate: ## Validate docker-compose.yml
	docker compose config --quiet && echo "✓ docker-compose.yml is valid"

health: ## Check health status of all services
	@echo "Checking service health..."
	@echo "Grafana:    http://localhost:3000 (admin/admin)"
	@curl -s -o /dev/null -w "  Status: %{http_code}\n" http://localhost:3000/api/health || echo "  Status: DOWN"
	@echo "Loki:       http://localhost:3100"
	@curl -s -o /dev/null -w "  Status: %{http_code}\n" http://localhost:3100/ready || echo "  Status: DOWN"
	@echo "Prometheus: http://localhost:9090"
	@curl -s -o /dev/null -w "  Status: %{http_code}\n" http://localhost:9090/-/healthy || echo "  Status: DOWN"
	@echo "Tempo:      http://localhost:3200"
	@curl -s -o /dev/null -w "  Status: %{http_code}\n" http://localhost:3200/ready || echo "  Status: DOWN"

generate-self-signed-certs: ## Generate self-signed SSL certificates for development
	@echo "Generating self-signed SSL certificates..."
	@mkdir -p nginx/ssl
	@openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
		-keyout nginx/ssl/key.pem \
		-out nginx/ssl/cert.pem \
		-subj "/C=US/ST=State/L=City/O=Organization/OU=Department/CN=localhost"
	@echo "✓ Self-signed certificates generated in nginx/ssl/"
	@echo "  - nginx/ssl/cert.pem"
	@echo "  - nginx/ssl/key.pem"
	@echo ""
	@echo "Note: Browsers will show a security warning for self-signed certificates."
	@echo "This is expected and safe for development."

logs-nginx: ## Follow nginx logs
	docker compose logs -f nginx
