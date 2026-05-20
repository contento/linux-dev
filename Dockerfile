# Multi-stage Dockerfile for lightweight terminal dev environment
# Supports: Ubuntu 26.04 LTS (resolute), Debian 13 (trixie)
# All supported bases use apt — swap via BASE_IMAGE build arg

ARG BASE_IMAGE=ubuntu:26.04

FROM ${BASE_IMAGE} as base

LABEL maintainer="contento"
LABEL description="Lightweight terminal-based development environment"

# Set environment
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TZ=UTC

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
    wget \
    && rm -rf /var/lib/apt/lists/*

# Setup locale
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen

# Create dev user (unprivileged)
RUN useradd -m -s /bin/bash -G sudo dev \
    && echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/dev \
    && chmod 0440 /etc/sudoers.d/dev

# Development stage
FROM base as dev

# Additional dev tools (optional)
ARG INCLUDE_EXTRA_TOOLS=true
RUN if [ "${INCLUDE_EXTRA_TOOLS}" = "true" ]; then \
    apt-get update && apt-get install -y --no-install-recommends \
    bat \
    fzf \
    htop \
    jq \
    less \
    man-db \
    tmux \
    vim \
    zsh \
    && rm -rf /var/lib/apt/lists/*; \
    fi

# SSH server (optional — enable with INCLUDE_SSH_SERVER=true)
ARG INCLUDE_SSH_SERVER=false
RUN if [ "${INCLUDE_SSH_SERVER}" = "true" ]; then \
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

# Switch to dev user
USER dev

# Setup dotfiles (optional)
ARG SETUP_DOTFILES=true
RUN if [ "${SETUP_DOTFILES}" = "true" ]; then \
    git clone --depth 1 https://github.com/contento/dotfiles.git ~/.dotfiles && \
    cd ~/.dotfiles && \
    NONINTERACTIVE=1 bash bootstrap.sh && \
    rm -f ~/.bashrc ~/.bash_logout ~/.profile && \
    bash stow-all.sh; \
    fi

# Default shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash", "-l"]
