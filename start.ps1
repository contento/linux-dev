#Requires -Version 7

param(
    [switch]$Silent
)

$ErrorActionPreference = 'Stop'

# Check Docker is running
docker info 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker is not running."
    exit 1
}

if (-not $Silent) {
    $reply = Read-Host "Start linux-dev (Ubuntu 26.04)? [Y/n]"
    if ($reply -and $reply -notmatch '^[Yy]$') { exit 0 }
}

# Start only if not already running
$running = docker compose ps --status running 2>$null | Select-String "dev"
if (-not $running) {
    docker compose up -d
}

docker compose exec dev bash
