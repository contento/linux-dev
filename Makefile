.PHONY: help build up down exec logs clean clean-all rebuild restart \
        build-ubuntu build-debian build-arch up-ubuntu up-debian up-arch

SHELL := /bin/bash

# Pick distro with `make DISTRO=debian <target>` (default: ubuntu).
# Mirrors start.sh so make and ./start.sh operate on the same containers/volumes.
DISTRO ?= ubuntu

ifeq ($(DISTRO),ubuntu)
  BASE_IMAGE := ubuntu:26.04
  SSH_PORT   := 2222
else ifeq ($(DISTRO),debian)
  BASE_IMAGE := debian:trixie-slim
  SSH_PORT   := 2223
else ifeq ($(DISTRO),arch)
  BASE_IMAGE := archlinux:latest
  SSH_PORT   := 2224
else
  $(error Unknown DISTRO=$(DISTRO). Use ubuntu, debian, or arch)
endif

CONTAINER_NAME ?= $(DISTRO)-dev
IMAGE_TAG      ?= $(DISTRO)

export BASE_IMAGE CONTAINER_NAME IMAGE_TAG SSH_PORT
export COMPOSE_PROJECT_NAME := $(CONTAINER_NAME)

# Legacy aliases used by build-ubuntu / build-debian targets below
UBUNTU_LTS := ubuntu:26.04
DEBIAN_LTS := debian:trixie-slim

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
	@echo -e "  $(YELLOW)build-arch$(NC)       Build Arch Linux image"
	@echo -e "  $(YELLOW)up-ubuntu$(NC)        Start Ubuntu LTS container"
	@echo -e "  $(YELLOW)up-debian$(NC)        Start Debian LTS container"
	@echo -e "  $(YELLOW)up-arch$(NC)          Start Arch Linux container"
	@echo -e ""
	@echo -e "$(GREEN)Levels:$(NC)"
	@echo -e "  $(YELLOW)LEVEL=minimal$(NC)    Base packages only, bash, ~200MB"
	@echo -e "  $(YELLOW)LEVEL=dev$(NC)        extra tools + SSH, ~500MB (default)"
	@echo -e "  $(YELLOW)LEVEL=full$(NC)       dev + python3 + nodejs + npm, ~1GB"
	@echo -e ""
	@echo -e "$(GREEN)All targets:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'

build: ## Build the Docker image (default: Ubuntu LTS)
	docker-compose build

build-ubuntu: ## Build Ubuntu 26.04 LTS image
	BASE_IMAGE=$(UBUNTU_LTS) docker-compose build

build-debian: ## Build Debian 13 (trixie) image
	BASE_IMAGE=$(DEBIAN_LTS) docker-compose build

build-arch: ## Build Arch Linux image
	docker build -t linux-dev:arch -f Dockerfile.arch .

build-multiplatform: ## Build minimal multi-platform image (amd64 + arm64) matching the published GHCR image
	docker buildx build --platform linux/amd64,linux/arm64 \
	  --build-arg LEVEL=minimal \
	  -t linux-dev:latest .

build-ssh: ## Build image with SSH server enabled
	LEVEL=dev docker-compose build

up: ## Start the container (default: Ubuntu LTS)
	docker-compose up -d
	@echo -e "$(GREEN)✓ Container started$(NC)"

up-ubuntu: ## Start Ubuntu 24.04 LTS container
	BASE_IMAGE=$(UBUNTU_LTS) docker-compose up -d
	@echo -e "$(GREEN)✓ Ubuntu container started$(NC)"

up-debian: ## Start Debian 12 (bookworm) container
	BASE_IMAGE=$(DEBIAN_LTS) docker-compose up -d
	@echo -e "$(GREEN)✓ Debian container started$(NC)"

up-arch: ## Start Arch Linux container
	docker run -d --name linux-dev-arch \
	  -v ./workspace:/home/dev/workspace \
	  -p 2224:22 \
	  linux-dev:arch
	@echo -e "$(GREEN)✓ Arch Linux container started$(NC)"

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

clean: ## Tear down container, volumes, network AND image for current DISTRO (destructive)
	docker compose down -v --remove-orphans
	-docker image rm linux-dev:$(IMAGE_TAG) 2>/dev/null
	@echo -e "$(YELLOW)⚠ $(CONTAINER_NAME): container, volumes, network, image removed$(NC)"

clean-all: ## Tear down every linux-dev instance + image (ubuntu-dev, debian-dev, arch-dev) — destructive
	@for distro in ubuntu debian arch; do \
	  echo -e "$(YELLOW)→ tearing down $$distro-dev$(NC)"; \
	  COMPOSE_PROJECT_NAME=$$distro-dev docker compose down -v --remove-orphans 2>/dev/null || true; \
	  docker image rm linux-dev:$$distro 2>/dev/null || true; \
	done
	@echo -e "$(YELLOW)⚠ All linux-dev instances and images removed$(NC)"

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

rm-container: ## Remove container (without removing volumes or image)
	docker compose rm -f

prune: ## Clean up all Docker resources system-wide (careful!)
	@echo -e "$(YELLOW)Pruning Docker resources...$(NC)"
	docker system prune -a --volumes
	@echo -e "$(GREEN)✓ Cleanup complete$(NC)"

.DEFAULT_GOAL := help
