# Variables
APP_NAME := env-manager
VERSION := $(shell cat VERSION)
DOCKER_REGISTRY := localhost:5000
GO_VERSION := 1.24
POSTGRES_URL := "postgres://envmanager:1234@localhost:5432/envmanager_dev?sslmode=disable"

# Build info
BUILD_TIME := $(shell date -u '+%Y-%m-%d_%H:%M:%S')
COMMIT_HASH := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
LDFLAGS := -ldflags "-X main.Version=$(VERSION) -X main.BuildTime=$(BUILD_TIME) -X main.CommitHash=$(COMMIT_HASH)"

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

.PHONY: help
help: ## Show this help message
	@echo "$(BLUE)$(APP_NAME) - Development Commands$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Development
.PHONY: dev
dev: ## Start development environment with hot reload & logging
	@echo "$(BLUE)Starting development environment...$(NC)"
	docker compose -f deployments/docker-compose.dev.yml up --build

.PHONY: dev-nlog
dev-nlog: ## Start development environment with hot reload & no logging
	@echo "$(BLUE)Starting development environment...$(NC)"
	docker compose -f deployments/docker-compose.dev.yml up --build -d

.PHONY: dev-down
dev-down: ## Stop development environment
	@echo "$(YELLOW)Stopping development environment...$(NC)"
	docker compose -f deployments/docker-compose.dev.yml down

.PHONY: dev-clean
dev-clean: ## Clean development environment (removes volumes)
	@echo "$(RED)Cleaning development environment...$(NC)"
	docker compose -f deployments/docker-compose.dev.yml down -v --remove-orphans
	docker system prune -f

# Database
.PHONY: db-migrate-up
db-migrate-up: ## Run database migrations up
	@echo "$(BLUE)Running database migrations up...$(NC)"
	migrate -path migrations -database $(POSTGRES_URL) up

.PHONY: db-migrate-down
db-migrate-down: ## Run database migrations down
	@echo "$(YELLOW)Running database migrations down...$(NC)"
	migrate -path migrations -database $(POSTGRES_URL) down 1

.PHONY: db-migrate-create
db-migrate-create: ## Create new migration file (usage: make db-migrate-create NAME=create_users)
	@if [ -z "$(NAME)" ]; then echo "$(RED)Error: NAME is required$(NC)"; exit 1; fi
	@echo "$(BLUE)Creating migration: $(NAME)$(NC)"
	migrate create -ext sql -dir migrations $(NAME)

.PHONY: db-reset
db-reset: ## Reset database (drop and recreate)
	@echo "$(RED)Resetting database...$(NC)"
	docker compose -f deployments/docker-compose.dev.yml exec postgres psql -U envmanager -d postgres -c "DROP DATABASE IF EXISTS envmanager_dev;"
	docker compose -f deployments/docker-compose.dev.yml exec postgres psql -U envmanager -d postgres -c "CREATE DATABASE envmanager_dev;"
	$(MAKE) db-migrate-up

# Build
.PHONY: build
build: ## Build all binaries
	@echo "$(BLUE)Building binaries...$(NC)"
	@mkdir -p bin
	go build $(LDFLAGS) -o bin/server ./cmd/server
	go build $(LDFLAGS) -o bin/cli ./cmd/cli

.PHONY: build-docker
build-docker: ## Build Docker images
	@echo "$(BLUE)Building Docker images...$(NC)"
	docker build -f deployments/Dockerfile.server -t $(APP_NAME):$(VERSION) .
	docker build -f deployments/Dockerfile.cli -t $(APP_NAME)-cli:$(VERSION) .

# Testing
.PHONY: test
test: ## Run all tests
	@echo "$(BLUE)Running tests...$(NC)"
	go test -v -race -coverprofile=coverage.out ./...

.PHONY: test-unit
test-unit: ## Run unit tests only
	@echo "$(BLUE)Running unit tests...$(NC)"
	go test -v -race -short ./tests/unit/...

.PHONY: test-integration
test-integration: ## Run integration tests only
	@echo "$(BLUE)Running integration tests...$(NC)"
	go test -v -race ./tests/integration/...

.PHONY: test-coverage
test-coverage: test ## Generate test coverage report
	@echo "$(BLUE)Generating coverage report...$(NC)"
	go tool cover -html=coverage.out -o coverage.html
	@echo "$(GREEN)Coverage report generated: coverage.html$(NC)"

# Code Quality
.PHONY: lint
lint: ## Run linter
	@echo "$(BLUE)Running linter...$(NC)"
	golangci-lint run

.PHONY: fmt
fmt: ## Format code
	@echo "$(BLUE)Formatting code...$(NC)"
	go fmt ./...
	goimports -w .

.PHONY: mod
mod: ## Tidy go modules
	@echo "$(BLUE)Tidying go modules...$(NC)"
	go mod tidy
	go mod verify

# Tools
.PHONY: tools
tools: ## Install development tools
	@echo "$(BLUE)Installing development tools...$(NC)"
	go install github.com/air-verse/air@latest
	go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	go install golang.org/x/tools/cmd/goimports@latest

# Security Keys
.PHONY: generate-keys
generate-keys: ## Generate new encryption and JWT keys
	@echo "$(BLUE)Generating security keys...$(NC)"
	@echo "$(YELLOW)ENCRYPTION_KEY (32 bytes):$(NC)"
	@openssl rand -hex 16
	@echo "$(YELLOW)JWT_SECRET (64 chars):$(NC)"
	@openssl rand -base64 64 | tr -d '\n' && echo

.PHONY: generate-encryption-key
generate-encryption-key: ## Generate new encryption key (32 bytes)
	@echo "$(BLUE)Generated ENCRYPTION_KEY:$(NC)"
	@openssl rand -hex 16

.PHONY: generate-jwt-secret
generate-jwt-secret: ## Generate new JWT secret (64 chars)
	@echo "$(BLUE)Generated JWT_SECRET:$(NC)"
	@openssl rand -base64 64 | tr -d '\n' && echo

# SQLC
.PHONY: sqlc-generate
sqlc-generate: ## Generate SQLC code
	@echo "$(BLUE)Generating SQLC code...$(NC)"
	sqlc generate

# API Documentation
.PHONY: docs
docs: ## Generate API documentation
	@echo "$(BLUE)Generating API documentation...$(NC)"
	swag init -g cmd/server/main.go -o docs/swagger

# Deployment
.PHONY: deploy-staging
deploy-staging: ## Deploy to staging environment
	@echo "$(BLUE)Deploying to staging...$(NC)"
	docker compose -f deployments/docker-compose.staging.yml up -d

.PHONY: deploy-prod
deploy-prod: ## Deploy to production environment
	@echo "$(RED)Deploying to production...$(NC)"
	@read -p "Are you sure you want to deploy to production? [y/N]: " confirm && \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		docker compose -f deployments/docker-compose.prod.yml up -d; \
	else \
		echo "Deployment cancelled."; \
	fi

# Utility
.PHONY: clean
clean: ## Clean build artifacts
	@echo "$(YELLOW)Cleaning build artifacts...$(NC)"
	rm -rf bin/
	rm -rf tmp/
	rm -f coverage.out coverage.html
	go clean -cache

.PHONY: version
version: ## Show version information
	@echo "$(BLUE)$(APP_NAME) v$(VERSION)$(NC)"
	@echo "Go Version: $(GO_VERSION)"
	@echo "Build Time: $(BUILD_TIME)"
	@echo "Commit Hash: $(COMMIT_HASH)"

# CLI helpers
.PHONY: cli-demo
cli-demo: build ## Demo CLI functionality
	@echo "$(BLUE)Running CLI demo...$(NC)"
	./bin/cli --help