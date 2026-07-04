# Multi-stage Dockerfile for lightweight terminal dev environment
# Supports: Ubuntu 26.04 LTS (resolute), Debian 13 (trixie)
# All supported bases use apt — swap via BASE_IMAGE build arg
#
# Levels:
#   minimal — base packages only, bash, ~200MB
#   dev     — extra tools + SSH + dotfiles (opt-in), ~500MB (default)
#   full    — dev + python3 + nodejs + npm, ~1GB

ARG BASE_IMAGE=ubuntu:26.04

FROM ${BASE_IMAGE} AS base

LABEL maintainer="contento"
LABEL description="Lightweight terminal-based development environment"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set environment
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=UTC \
    PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:/usr/local/bin:${PATH}"

# Install base packages (minimal footprint)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    git \
    gnupg \
    locales \
    openssh-client \
    sudo \
    unzip \
    wget \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Setup locale
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen

# Create dev user (unprivileged) at UID 1000 — ubuntu:24.04+ ships a default
# "ubuntu" user squatting on 1000, which would push dev to 1001 and break
# bind-mount ownership vs the debian build
RUN userdel -r ubuntu 2>/dev/null || true \
    && useradd -m -u 1000 -s /bin/bash -G sudo dev \
    && echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/dev \
    && chmod 0440 /etc/sudoers.d/dev

# Development stage
FROM base AS dev

# Level: minimal | dev | full
ARG LEVEL=dev

# Shell — zsh for dev and full, bash for minimal
RUN if [ "${LEVEL}" != "minimal" ]; then \
    apt-get update && apt-get install -y --no-install-recommends zsh \
    && rm -rf /var/lib/apt/lists/*; \
    fi

# Extra dev tools — dev and full
RUN if [ "${LEVEL}" = "dev" ] || [ "${LEVEL}" = "full" ]; then \
    apt-get update && apt-get install -y --no-install-recommends \
    bat \
    dnsutils \
    fzf \
    htop \
    iputils-ping \
    jq \
    less \
    man-db \
    python-is-python3 \
    ripgrep \
    rsync \
    tmux \
    tree \
    vim \
    && rm -rf /var/lib/apt/lists/*; \
    fi

# Full: add python3, nodejs, npm
RUN if [ "${LEVEL}" = "full" ]; then \
    apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*; \
    fi

# SSH server — dev and full
RUN if [ "${LEVEL}" != "minimal" ]; then \
    apt-get update && apt-get install -y --no-install-recommends openssh-server \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /run/sshd \
    && echo "PasswordAuthentication no" >> /etc/ssh/sshd_config \
    && echo "PubkeyAuthentication yes"  >> /etc/ssh/sshd_config \
    && echo "PermitRootLogin no"        >> /etc/ssh/sshd_config \
    && echo "AllowUsers dev"            >> /etc/ssh/sshd_config; \
    fi

# Set working directory
WORKDIR /home/dev/workspace

# Copy entrypoint script
COPY --chown=dev:dev entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Setup dotfiles (opt-in) — dev and full
ARG SETUP_DOTFILES=false
RUN if [ "${LEVEL}" != "minimal" ] && [ "${SETUP_DOTFILES}" = "true" ]; then \
    curl -fsSL https://starship.rs/install.sh | sh -s -- --yes; \
    fi

# Default shell — wrapper picks zsh when available, falls back to bash
RUN printf '#!/bin/sh\nif command -v zsh >/dev/null 2>&1; then\n  exec /bin/zsh -l\nelse\n  exec /bin/bash -l\nfi\n' \
    > /usr/local/bin/default-shell && chmod +x /usr/local/bin/default-shell

# Switch to dev user
USER dev

RUN if [ "${LEVEL}" != "minimal" ] && [ "${SETUP_DOTFILES}" = "true" ]; then \
    git clone --depth 1 https://github.com/contento/dotfiles.git ~/.dotfiles && \
    cd ~/.dotfiles && \
    NONINTERACTIVE=1 bash bootstrap.sh && \
    rm -f ~/.bashrc ~/.bash_logout ~/.profile && \
    bash stow-all.sh; \
    fi

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/usr/local/bin/default-shell"]
