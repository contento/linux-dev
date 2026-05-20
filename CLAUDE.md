# CLAUDE.md - Developer Context & Guidelines

> **Purpose**: Context and best practices for AI-assisted development of linux-dev

## Project Overview

**linux-dev** is a reproducible Docker development environment for terminal-based workflows on Debian/Ubuntu systems. It integrates with [contento/dotfiles](https://github.com/contento/dotfiles) to deliver a fully configured shell out of the box.

### Design Philosophy

1. **Minimal**: Only include what's necessary; extras are optional
2. **Flexible**: Build args allow customization without code changes
3. **Non-root**: `dev` user for safety; passwordless sudo for when needed
4. **Reproducible**: Same setup across all machines
5. **Dotfiles-first**: `bootstrap.sh` + `stow-all.sh` from contento/dotfiles do the heavy lifting

## Architecture

### Multi-stage Dockerfile

- **base**: System packages, locale, `dev` user
- **dev**: Optional apt tools (`INCLUDE_EXTRA_TOOLS`), dotfiles setup (`SETUP_DOTFILES`)

Supported bases: `ubuntu:26.04` (default), `debian:trixie` — selected via `BASE_IMAGE` build arg.

Supported hosts: macOS, Linux, Windows 11 (WSL2 recommended — run all commands from the WSL2 terminal). On Windows, PowerShell 7+ (`pwsh`) is required for `start.ps1`.

### Dotfiles Integration

When `SETUP_DOTFILES=true` (default):

1. Clone `contento/dotfiles` to `~/.dotfiles`
2. Run `bootstrap.sh` — installs full toolchain via apt + Homebrew
3. Remove default shell files that would conflict with stow (`~/.bashrc`, etc.)
4. Run `stow-all.sh` — symlinks configs into `$HOME`

`entrypoint.sh` repeats steps 1–4 at runtime if `~/.dotfiles/.git` is absent (useful when home dir is a fresh volume).

**Note**: CI/CD builds use `SETUP_DOTFILES=false` to avoid Homebrew installs in CI.

### Build Arguments

- `BASE_IMAGE` (default: `ubuntu:26.04`) — base distro; also supports `debian:trixie`
- `INCLUDE_EXTRA_TOOLS` (default: `true`) — installs bat, fzf, htop, jq, tmux, vim, zsh via apt
- `INCLUDE_SSH_SERVER` (default: `false`) — installs openssh-server, disables password auth, restricts to `dev` user
- `SETUP_DOTFILES` (default: `true`) — runs bootstrap.sh + stow-all.sh from contento/dotfiles

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
docker build --no-cache -t linux-dev:test --build-arg SETUP_DOTFILES=false .
docker run --rm linux-dev:test whoami   # dev
docker run --rm linux-dev:test pwd      # /home/dev/workspace
docker run --rm linux-dev:test which bat
docker run --rm linux-dev:test which tmux
```

### After docker-compose Changes

```bash
docker compose config   # validate
docker-compose up -d && docker-compose exec dev whoami && docker-compose down
```

## Common Pitfalls

| Pitfall | Solution |
| --- | --- |
| stow fails on existing files | Remove default shell files before `stow-all.sh` |
| bootstrap.sh in CI hangs | Always set `SETUP_DOTFILES=false` in CI builds |
| Stale apt cache | `apt-get update` before any install |
| Lost data on rebuild | Use named volumes (`dev_home`) |
| Silent dotfiles failure | Check `~/.dotfiles/.git` exists after build |

## Security

- Non-root `dev` user with `NOPASSWD` sudo (remove sudo for sensitive environments)
- Official base images only (Ubuntu, Debian)
- Trivy scan runs in CI on every push to main

## Resources

- [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)
- [Compose File Specification](https://docs.docker.com/compose/compose-file/)
- [contento/dotfiles](https://github.com/contento/dotfiles)
- `dive linux-dev:latest` — inspect image layers

---

**Maintainer**: contento
