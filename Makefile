.PHONY: help build up down exec logs clean rebuild restart \
        build-ubuntu build-debian up-ubuntu up-debian

SHELL := /bin/bash

# Distro targets
UBUNTU_LTS := ubuntu:26.04
DEBIAN_LTS := debian:trixie

# Color output (NC = no color / reset)
BLUE   := \033[0;34m
GREEN  := \033[0;32m
YELLOW := \033[0;33m
NC     := \033[0m

help: ## Show this help message
	@echo -e "$(BLUE)linux-dev - Lightweight Development Environment$(NC)"
	@echo -e ""
	@echo -e "$(GREEN)Usage:$(NC)"
	@echo -e "  make $(YELLOW)<target>$(NC)"
	@echo -e ""
	@echo -e "$(GREEN)Distro targets:$(NC)"
	@echo -e "  $(YELLOW)build-ubuntu$(NC)     Build Ubuntu 26.04 LTS image"
	@echo -e "  $(YELLOW)build-debian$(NC)     Build Debian 13 (trixie) image"
	@echo -e "  $(YELLOW)up-ubuntu$(NC)        Start Ubuntu LTS container"
	@echo -e "  $(YELLOW)up-debian$(NC)        Start Debian LTS container"
	@echo -e ""
	@echo -e "$(GREEN)All targets:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'

build: ## Build the Docker image (default: Ubuntu LTS)
	docker-compose build

build-ubuntu: ## Build Ubuntu 26.04 LTS image
	BASE_IMAGE=$(UBUNTU_LTS) docker-compose build

build-debian: ## Build Debian 13 (trixie) image
	BASE_IMAGE=$(DEBIAN_LTS) docker-compose build

build-multiplatform: ## Build multi-platform image (amd64 + arm64) — requires buildx
	docker buildx build --platform linux/amd64,linux/arm64 \
	  -t linux-dev:latest .

build-ssh: ## Build image with SSH server enabled
	INCLUDE_SSH_SERVER=true docker-compose build

up: ## Start the container (default: Ubuntu LTS)
	docker-compose up -d
	@echo -e "$(GREEN)✓ Container started$(NC)"

up-ubuntu: ## Start Ubuntu 24.04 LTS container
	BASE_IMAGE=$(UBUNTU_LTS) docker-compose up -d
	@echo -e "$(GREEN)✓ Ubuntu container started$(NC)"

up-debian: ## Start Debian 12 (bookworm) container
	BASE_IMAGE=$(DEBIAN_LTS) docker-compose up -d
	@echo -e "$(GREEN)✓ Debian container started$(NC)"

down: ## Stop the container
	docker-compose down
	@echo -e "$(GREEN)✓ Container stopped$(NC)"

exec: ## Enter the container shell
	docker-compose exec dev bash

exec-zsh: ## Enter the container with zsh
	docker-compose exec dev zsh

logs: ## View container logs
	docker-compose logs -f dev

logs-tail: ## View last 50 lines of logs
	docker-compose logs --tail 50 dev

clean: ## Stop container and remove volumes (destructive)
	docker-compose down -v
	@echo -e "$(YELLOW)⚠ Container and volumes removed$(NC)"

rebuild: clean build up ## Full rebuild: clean → build → up
	@echo -e "$(GREEN)✓ Rebuild complete$(NC)"

restart: ## Restart the container
	docker-compose restart
	@echo -e "$(GREEN)✓ Container restarted$(NC)"

ps: ## Show container status
	docker-compose ps

test: ## Test container functionality
	@echo -e "$(BLUE)Testing container...$(NC)"
	docker-compose exec dev whoami
	docker-compose exec dev pwd
	docker-compose exec dev bash --version
	@echo -e "$(GREEN)✓ All tests passed$(NC)"

shell: ## Alias for 'exec'
	make exec

version: ## Show Docker and Docker Compose versions
	@echo -e "Docker version:" && docker --version
	@echo -e "Docker Compose version:" && docker-compose --version

lint-dockerfile: ## Check Dockerfile syntax (requires hadolint)
	@which hadolint > /dev/null || (echo -e "$(YELLOW)hadolint not found. Install: brew install hadolint$(NC)" && exit 1)
	hadolint Dockerfile

validate-compose: ## Validate docker-compose.yml
	docker-compose config --quiet && echo -e "$(GREEN)✓ docker-compose.yml is valid$(NC)"

info: ## Show environment info
	@echo -e "$(BLUE)Environment Information:$(NC)"
	@echo -e "OS: $$(uname -s)"
	@echo -e "Docker: $$(docker --version)"
	@echo -e "Compose: $$(docker-compose --version)"
	@echo -e "Image: linux-dev:latest"
	@echo -e "Container: linux-dev"

rm-container: ## Remove container (without removing volumes)
	docker-compose rm -f

rm-image: ## Remove image
	docker-compose down && docker rmi linux-dev:latest || true

prune: ## Clean up all Docker resources (careful!)
	@echo -e "$(YELLOW)Pruning Docker resources...$(NC)"
	docker system prune -a --volumes
	@echo -e "$(GREEN)✓ Cleanup complete$(NC)"

.DEFAULT_GOAL := help
