#!/usr/bin/env bash
set -euo pipefail

DISTRO="ubuntu"
SILENT=false
BUILD=false
NAME=""
PORT=""

next_val=""
for arg in "$@"; do
  if [[ -n "$next_val" ]]; then
    declare "$next_val=$arg"
    next_val=""
    continue
  fi
  case $arg in
    ubuntu) DISTRO="ubuntu" ;;
    debian) DISTRO="debian" ;;
    --silent)   SILENT=true ;;
    --build)    BUILD=true ;;
    --name)     next_val="NAME" ;;
    --name=*)   NAME="${arg#--name=}" ;;
    --port)     next_val="PORT" ;;
    --port=*)   PORT="${arg#--port=}" ;;
    --help)
      echo "Usage: ./start.sh [distro] [--name <name>] [--port <port>] [--build] [--silent] [--help]"
      echo ""
      echo "  Start the linux-dev container and open a bash shell."
      echo ""
      echo "Distros:"
      echo "  ubuntu  Ubuntu 26.04 LTS (default)"
      echo "  debian  Debian 13 (trixie)"
      echo ""
      echo "Options:"
      echo "  --name    Container name (default: ubuntu-dev / debian-dev)"
      echo "  --port    SSH host port    (default: ubuntu→2222, debian→2223)"
      echo "  --build   Build the image before starting"
      echo "  --silent  Skip confirmation prompt (for scripts/automation)"
      echo "  --help    Show this help message"
      exit 0
      ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

case $DISTRO in
  ubuntu) BASE_IMAGE="ubuntu:26.04";  DEFAULT_PORT=2222 ;;
  debian) BASE_IMAGE="debian:trixie"; DEFAULT_PORT=2223 ;;
esac

CONTAINER_NAME="${NAME:-${DISTRO}-dev}"
SSH_PORT="${PORT:-$DEFAULT_PORT}"

# Use container name as compose project so volumes/networks are isolated per instance
export BASE_IMAGE CONTAINER_NAME SSH_PORT
export COMPOSE_PROJECT_NAME="$CONTAINER_NAME"

if ! docker info &>/dev/null; then
  echo "Error: Docker is not running." >&2
  exit 1
fi

if [[ "$SILENT" == false ]]; then
  read -rp "Start $CONTAINER_NAME ($BASE_IMAGE, SSH :$SSH_PORT)? [Y/n] " reply
  reply=${reply:-Y}
  [[ "$reply" =~ ^[Yy]$ ]] || exit 0
fi

if [[ "$BUILD" == true ]]; then
  docker compose build
fi

# Start only if not already running
if ! docker compose ps --status running 2>/dev/null | grep -q dev; then
  docker compose up -d
fi

docker compose exec dev zsh
