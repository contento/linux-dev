#!/usr/bin/env bash
set -euo pipefail

SILENT=false

for arg in "$@"; do
  case $arg in
    --silent) SILENT=true ;;
    --help)
      echo "Usage: ./start.sh [--silent] [--help]"
      echo ""
      echo "  Start the linux-dev container and open a bash shell."
      echo ""
      echo "Options:"
      echo "  --silent  Skip confirmation prompt (for scripts/automation)"
      echo "  --help    Show this help message"
      exit 0
      ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

if ! docker info &>/dev/null; then
  echo "Error: Docker is not running." >&2
  exit 1
fi

if [[ "$SILENT" == false ]]; then
  read -rp "Start linux-dev (Ubuntu 26.04)? [Y/n] " reply
  reply=${reply:-Y}
  [[ "$reply" =~ ^[Yy]$ ]] || exit 0
fi

# Start only if not already running
if ! docker compose ps --status running 2>/dev/null | grep -q dev; then
  docker compose up -d
fi

docker compose exec dev bash
