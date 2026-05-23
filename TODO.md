# TODO.md - Development Roadmap

## Priority: High

- [x] **CI/CD Pipeline**
  - [x] GitHub Actions: build and push to GHCR on push to main / tags
  - [x] Automated smoke tests (image runs, user is dev, workspace exists)
  - [x] Security scanning (Trivy config scan, SARIF upload to Code Scanning)

- [x] **Multi-platform build**
  - [x] arm64 + amd64 via `docker buildx` (Apple Silicon + Linux x86)
  - [x] Publish both platforms to GHCR on release

- [x] **SSH Server mode**
  - [x] Install and configure `openssh-server` via `INCLUDE_SSH_SERVER=true`
  - [x] Port 2222→22 mapped in `docker-compose.yml`
  - [x] `SSH_PUBLIC_KEY` env var writes to `~/.ssh/authorized_keys` at startup

## Priority: Medium

- [ ] **Arch Linux Support**
  - [ ] `Dockerfile.arch` using `archlinux:latest` base
  - [ ] Add `make build-arch` / `make up-arch` targets

- [ ] **Docker Compose Profiles**
  - [ ] `databases`: PostgreSQL, Redis
  - [ ] `dev`: full environment with port mappings

## Priority: Low

- [ ] **Advanced Features**
  - [ ] ARM64 native optimizations (NEON, platform-specific tuning)

## Completed ✅

- [x] Multi-stage Dockerfile (base + dev)
- [x] docker-compose.yml with resource limits
- [x] Non-root dev user with passwordless sudo
- [x] Locale and timezone setup
- [x] Optional tools layer (INCLUDE_EXTRA_TOOLS)
- [x] Named volume for home directory persistence (dev_home)
- [x] Makefile with distro targets
- [x] Dotfiles integration: bootstrap.sh + stow-all.sh from contento/dotfiles
- [x] Ubuntu 26.04 LTS + Debian 13 (trixie) support
- [x] GitHub Actions CI/CD workflow

## Known Issues

- dotfiles clone in entrypoint may timeout on slow connections (no retry logic)
- Alpine Linux incompatible (uses apk, not apt) — unsupported by design
