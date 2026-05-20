#!/bin/bash
set -e

# Entrypoint script for dev environment
# Handles optional dotfiles setup and shell initialization

DOTFILES_DIR="${HOME}/.dotfiles"

# Setup dotfiles if not already done
if [ ! -d "$DOTFILES_DIR/.git" ]; then
  echo "Setting up dotfiles..."
  git clone --depth 1 https://github.com/contento/dotfiles.git "$DOTFILES_DIR" || true

  if [ -d "$DOTFILES_DIR" ]; then
    cd "$DOTFILES_DIR"
    bash bootstrap.sh || true
    rm -f ~/.bashrc ~/.bash_logout ~/.profile
    bash stow-all.sh || true
  fi
fi

# Execute passed command or default shell
exec "$@"
