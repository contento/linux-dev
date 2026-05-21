#Requires -Version 7

param(
    [ValidateSet("ubuntu", "debian")]
    [string]$Distro = "ubuntu",
    [string]$Name = "",
    [int]$Port = 0,
    [switch]$Build,
    [switch]$Silent,
    [switch]$Help
)

if ($Help) {
    Write-Host "Usage: .\start.ps1 [[-Distro] <distro>] [-Name <name>] [-Port <port>] [-Build] [-Silent] [-Help]"
    Write-Host ""
    Write-Host "  Start the linux-dev container and open a bash shell."
    Write-Host ""
    Write-Host "Distros:"
    Write-Host "  ubuntu  Ubuntu 26.04 LTS (default)"
    Write-Host "  debian  Debian 13 (trixie)"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Name    Container name (default: ubuntu-dev / debian-dev)"
    Write-Host "  -Port    SSH host port    (default: ubuntu->2222, debian->2223)"
    Write-Host "  -Build   Build the image before starting"
    Write-Host "  -Silent  Skip confirmation prompt (for scripts/automation)"
    Write-Host "  -Help    Show this help message"
    exit 0
}

$baseImages    = @{ ubuntu = "ubuntu:26.04"; debian = "debian:trixie" }
$defaultPorts  = @{ ubuntu = 2222;           debian = 2223 }

$env:BASE_IMAGE           = $baseImages[$Distro]
$env:CONTAINER_NAME       = if ($Name) { $Name } else { "$Distro-dev" }
$env:SSH_PORT             = if ($Port -gt 0) { $Port } else { $defaultPorts[$Distro] }
$env:COMPOSE_PROJECT_NAME = $env:CONTAINER_NAME

$ErrorActionPreference = 'Stop'

docker info 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker is not running."
    exit 1
}

if (-not $Silent) {
    $reply = Read-Host "Start $($env:CONTAINER_NAME) ($($env:BASE_IMAGE), SSH :$($env:SSH_PORT))? [Y/n]"
    if ($reply -and $reply -notmatch '^[Yy]$') { exit 0 }
}

if ($Build) {
    docker compose build
}

$running = docker compose ps --status running 2>$null | Select-String "dev"
if (-not $running) {
    docker compose up -d
}

docker compose exec dev zsh
