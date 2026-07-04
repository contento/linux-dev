# CLAUDE.md - Developer Context & Guidelines

> **Purpose**: Context and best practices for AI-assisted development of linux-dev

## Project Overview

**linux-dev** is a reproducible Docker development environment for terminal-based workflows on Linux systems. It can optionally bake in [contento/dotfiles](https://github.com/contento/dotfiles) for a fully configured shell.

### Design Philosophy

1. **Minimal**: Only include what's necessary; extras are opt-in
2. **Flexible**: Build args allow customization without code changes
3. **Non-root**: `dev` user for safety; passwordless sudo for when needed
4. **Reproducible**: Same setup across all machines
5. **Dotfiles-optional**: `bootstrap.sh` + `stow-all.sh` from contento/dotfiles are available via `SETUP_DOTFILES=true`

## Architecture

### Multi-stage Dockerfile

- **base**: System packages, locale, `dev` user
- **dev**: Level-based tooling (`LEVEL` build arg), dotfiles setup (`SETUP_DOTFILES`)

Supported bases: `ubuntu:26.04` (default), `debian:trixie-slim`, `archlinux:latest` — selected via `BASE_IMAGE` build arg (Debian/Ubuntu) or `Dockerfile.arch` (Arch).

Supported hosts: macOS, Linux, Windows 11 (WSL2 recommended — run all commands from the WSL2 terminal). On Windows, PowerShell 7+ (`pwsh`) is required for `start.ps1`.

### Levels

The `LEVEL` build arg controls what gets installed:

| Level | Shell | Tools | SSH | Dotfiles | Python/Node | Size |
| --- | --- | --- | --- | --- | --- | --- |
| `minimal` | bash | base only | ✗ | ✗ | ✗ | ~200MB |
| `dev` | bash + zsh | bat, fzf, htop, jq, tmux, vim | ✓ | opt-in | ✗ | ~500MB |
| `full` | bash + zsh | dev + python3 + nodejs + npm | ✓ | opt-in | ✓ | ~1GB |

### Dotfiles Integration

Dotfiles are **opt-in** (default is off). When `SETUP_DOTFILES=true` is set as a build arg and/or runtime env:

1. Clone `contento/dotfiles` to `~/.dotfiles`
2. Run `bootstrap.sh` — installs full toolchain via apt + Homebrew
3. Remove default shell files that would conflict with stow (`~/.bashrc`, etc.)
4. Run `stow-all.sh` — symlinks configs into `$HOME`

`entrypoint.sh` repeats steps 1–4 at runtime when `SETUP_DOTFILES=true` and `~/.dotfiles/.git` is absent (useful when the home dir is a fresh volume on a dotfiles-built image).

**Note**: the default-off keeps CI builds fast (no Homebrew install). To get a fully-loaded local image, build with `SETUP_DOTFILES=true docker compose build`.

### Build Arguments

- `BASE_IMAGE` (default: `ubuntu:26.04`) — base distro; also supports `debian:trixie-slim`
- `LEVEL` (default: `dev`) — `minimal` (~200MB), `dev` (~500MB), `full` (~1GB)
- `SETUP_DOTFILES` (default: `false`) — opt-in; runs bootstrap.sh + stow-all.sh from contento/dotfiles. Also honoured at runtime by `entrypoint.sh`. The `starship` install in the Dockerfile is gated on this same flag.

### Published vs local image

The image published to GHCR is built with `LEVEL=minimal` — see [.github/workflows/build.yml](.github/workflows/build.yml). It's the smallest possible base for consumers to extend. The local `./start.sh` flow builds with `LEVEL=dev` (the daily-driver image), and dotfiles opt-in.

`SSH_PUBLIC_KEY` env var (runtime, not build-time) — written to `~/.ssh/authorized_keys` by `entrypoint.sh` when SSH server is active. Port mapped as `SSH_PORT` (default `2222`) → `22`.

### Non-root User

```bash
useradd -m -s /bin/bash -G sudo dev
echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/dev
```

Security best practice; prevents accidental root operations.

### Entry Scripts

- `start.sh` — macOS/Linux/WSL2. Prompts for confirmation then runs `docker compose up -d` + `exec`. Pass `--silent` to skip the prompt.
- `start.ps1` — Windows 11, requires PowerShell 7+ (`#Requires -Version 7`). Same behaviour; pass `-Silent` to skip the prompt. Both scripts detect if the container is already running and skip `up`.

## Common Tasks

### Adding a Package to the Base Image

```dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends \
    existing-package \
    new-package \
    && rm -rf /var/lib/apt/lists/*
```

### Adding a Build Argument

1. `ARG MY_VAR=default` near top of stage
2. `RUN if [ "${MY_VAR}" = "true" ]; then ...; fi`
3. Document in README.md and here

### Debugging a Build

```bash
# Force rebuild
docker build --no-cache --progress=plain -t linux-dev:debug . 2>&1 | tee build.log

# Bypass entrypoint
docker run -it --entrypoint bash linux-dev:debug

# Inspect installed packages
docker run --rm linux-dev:latest dpkg -l | grep "tool-name"
```

## Testing Checklist

### After Dockerfile Changes

```bash
# Test minimal level
docker build --no-cache -t linux-dev:test-minimal --build-arg LEVEL=minimal .
docker run --rm linux-dev:test-minimal whoami   # dev
docker run --rm linux-dev:test-minimal pwd      # /home/dev/workspace
docker run --rm linux-dev:test-minimal bash -c "command -v zsh || echo 'no zsh'"

# Test dev level (default)
docker build --no-cache -t linux-dev:test-dev .
docker run --rm linux-dev:test-dev whoami
docker run --rm linux-dev:test-dev which bat
docker run --rm linux-dev:test-dev which tmux

# Test full level
docker build --no-cache -t linux-dev:test-full --build-arg LEVEL=full .
docker run --rm linux-dev:test-full which python3
docker run --rm linux-dev:test-full which node

# Test Arch Linux
docker build --no-cache -t linux-dev:test-arch -f Dockerfile.arch .
docker run --rm linux-dev:test-arch whoami
docker run --rm linux-dev:test-arch pacman --version
```

### After docker-compose Changes

```bash
docker compose config   # validate
docker compose up -d && docker compose exec dev whoami && docker compose down
```

## Common Pitfalls

| Pitfall | Solution |
| --- | --- |
| stow fails on existing files | Remove default shell files before `stow-all.sh` |
| bootstrap.sh in CI hangs | Default is now off; only opt in (`SETUP_DOTFILES=true`) for local images |
| Stale apt cache | `apt-get update` before any install |
| Lost data on rebuild | Use named volumes (`dev_home`) |
| Silent dotfiles failure | Check `~/.dotfiles/.git` exists after build |

## Security

- Non-root `dev` user with `NOPASSWD` sudo (remove sudo for sensitive environments)
- Official base images only (Ubuntu, Debian, Arch)
- Trivy scan runs in CI on every push to main

## Resources

- [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)
- [Compose File Specification](https://docs.docker.com/compose/compose-file/)
- [contento/dotfiles](https://github.com/contento/dotfiles)
- `dive linux-dev:latest` — inspect image layers

---

**Maintainer**: contento
