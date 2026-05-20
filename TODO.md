# TODO.md - Development Roadmap

## Priority: High

- [ ] **CI/CD Pipeline**
  - [ ] GitHub Actions: build and push to GHCR on release
  - [ ] Automated smoke tests (image runs, user is dev, workspace exists)
  - [ ] Security scanning (Trivy)

- [ ] **Multi-platform build**
  - [ ] arm64 + amd64 via `docker buildx`
  - [ ] Test on Apple Silicon and Linux x86

## Priority: Medium

- [ ] **Arch Linux Support**
  - [ ] `Dockerfile.arch` using `archlinux:latest` base
  - [ ] Add `make build-arch` / `make up-arch` targets

- [ ] **Docker Compose Profiles**
  - [ ] `databases`: PostgreSQL, Redis
  - [ ] `dev`: full environment with port mappings

## Priority: Low

- [ ] **Advanced Features**
  - [ ] SSH server mode for remote access
  - [ ] ARM64 native optimizations

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
