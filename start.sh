#!/usr/bin/env bash
set -euo pipefail

DISTRO="ubuntu"
SILENT=false
BUILD=false

for arg in "$@"; do
  case $arg in
    ubuntu) DISTRO="ubuntu" ;;
    debian) DISTRO="debian" ;;
    --silent) SILENT=true ;;
    --build)  BUILD=true ;;
    --help)
      echo "Usage: ./start.sh [distro] [--build] [--silent] [--help]"
      echo ""
      echo "  Start the linux-dev container and open a bash shell."
      echo ""
      echo "Distros:"
      echo "  ubuntu  Ubuntu 26.04 LTS (default)"
      echo "  debian  Debian 13 (trixie)"
      echo ""
      echo "Options:"
      echo "  --build   Build the image before starting"
      echo "  --silent  Skip confirmation prompt (for scripts/automation)"
      echo "  --help    Show this help message"
      exit 0
      ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

case $DISTRO in
  ubuntu) BASE_IMAGE="ubuntu:26.04" ;;
  debian) BASE_IMAGE="debian:trixie" ;;
esac

if ! docker info &>/dev/null; then
  echo "Error: Docker is not running." >&2
  exit 1
fi

if [[ "$SILENT" == false ]]; then
  read -rp "Start linux-dev ($BASE_IMAGE)? [Y/n] " reply
  reply=${reply:-Y}
  [[ "$reply" =~ ^[Yy]$ ]] || exit 0
fi

if [[ "$BUILD" == true ]]; then
  BASE_IMAGE=$BASE_IMAGE docker compose build
fi

# Start only if not already running
if ! BASE_IMAGE=$BASE_IMAGE docker compose ps --status running 2>/dev/null | grep -q dev; then
  BASE_IMAGE=$BASE_IMAGE docker compose up -d
fi

BASE_IMAGE=$BASE_IMAGE docker compose exec dev bash
