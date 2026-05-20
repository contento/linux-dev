#Requires -Version 7

param(
    [ValidateSet("ubuntu", "debian")]
    [string]$Distro = "ubuntu",
    [switch]$Build,
    [switch]$Silent,
    [switch]$Help
)

if ($Help) {
    Write-Host "Usage: .\start.ps1 [[-Distro] <distro>] [-Silent] [-Help]"
    Write-Host ""
    Write-Host "  Start the linux-dev container and open a bash shell."
    Write-Host ""
    Write-Host "Distros:"
    Write-Host "  ubuntu  Ubuntu 26.04 LTS (default)"
    Write-Host "  debian  Debian 13 (trixie)"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Build   Build the image before starting"
    Write-Host "  -Silent  Skip confirmation prompt (for scripts/automation)"
    Write-Host "  -Help    Show this help message"
    exit 0
}

$baseImages = @{ ubuntu = "ubuntu:26.04"; debian = "debian:trixie" }
$env:BASE_IMAGE = $baseImages[$Distro]

$ErrorActionPreference = 'Stop'

# Check Docker is running
docker info 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker is not running."
    exit 1
}

if (-not $Silent) {
    $reply = Read-Host "Start linux-dev ($($env:BASE_IMAGE))? [Y/n]"
    if ($reply -and $reply -notmatch '^[Yy]$') { exit 0 }
}

if ($Build) {
    docker compose build
}

# Start only if not already running
$running = docker compose ps --status running 2>$null | Select-String "dev"
if (-not $running) {
    docker compose up -d
}

docker compose exec dev bash
