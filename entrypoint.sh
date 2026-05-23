#!/bin/bash
set -e

DOTFILES_DIR="${HOME}/.dotfiles"

# Setup dotfiles at runtime only when explicitly opted-in (e.g. fresh volume on a dotfiles-built image)
if [ "${SETUP_DOTFILES:-false}" = "true" ] && [ ! -d "$DOTFILES_DIR/.git" ]; then
  echo "Setting up dotfiles..."
  git clone --depth 1 https://github.com/contento/dotfiles.git "$DOTFILES_DIR" || true

  if [ -d "$DOTFILES_DIR" ]; then
    cd "$DOTFILES_DIR"
    NONINTERACTIVE=1 bash bootstrap.sh || true
    rm -f ~/.bashrc ~/.bash_logout ~/.profile
    bash stow-all.sh || true
  fi
fi

# Start SSH server if installed
if command -v sshd &>/dev/null; then
  if [ -n "${SSH_PUBLIC_KEY:-}" ]; then
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    echo "${SSH_PUBLIC_KEY}" >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
  fi
  sudo mkdir -p /run/sshd
  sudo /usr/sbin/sshd
fi

exec "$@"
