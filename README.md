# linux-dev: Lightweight Terminal Development Environment

A minimal, reproducible Docker development environment for Debian-based Linux distributions.

```text
  o  o
\______/
  |
     |    https://conten.to
--------
```

## Why

Setting up a consistent terminal environment across machines is tedious — installing tools, syncing configs, getting the shell right. linux-dev solves this with a single Docker container: one build gives you a complete Linux terminal with your full toolchain and dotfiles already applied. Spin it up on any machine that runs Docker and you're in the same environment, every time.

It is built around [contento/dotfiles](https://github.com/contento/dotfiles), so the container is not generic — it is a portable version of a specific, opinionated dev setup.

## Features

- **Multi-distro**: Ubuntu 26.04 LTS (default), Debian 13 (trixie)
- **Flexible**: Build args for customizing tools and dotfiles setup
- **Reproducible**: Consistent environment across machines
- **User-safe**: Non-root `dev` user with passwordless sudo
- **Terminal-first**: Modern CLI toolchain via contento/dotfiles
- **Dotfiles-ready**: Runs `bootstrap.sh` + `stow-all.sh` from contento/dotfiles

## System Requirements

| Resource | Minimum | Recommended |
| --- | --- | --- |
| CPU | 1 core | 2–4 cores |
| RAM | 512 MB | 2–4 GB |
| Disk | 10 GB | 20 GB |

### Required tools

| Tool | macOS | Linux | Windows 11 |
| --- | --- | --- | --- |
| Docker Desktop | [docker.com](https://docs.docker.com/get-docker/) | [docker.com](https://docs.docker.com/get-docker/) | `winget install Docker.DockerDesktop` |
| Docker Compose | included | `apt install docker-compose-plugin` | included with Docker Desktop |
| Make | `brew install make` | `apt install make` | `winget install GnuWin32.Make` |
| Git | `brew install git` | `apt install git` | `winget install Git.Git` |
| PowerShell 7+ | — | — | `winget install Microsoft.PowerShell` |

### Windows 11 (WSL2)

WSL2 is the recommended path on Windows — it gives you a native Linux environment where everything just works:

```powershell
# 1. Enable WSL2 (built into Windows 11)
wsl --install

# 2. Install Docker Desktop with WSL2 backend
winget install Docker.DockerDesktop
```

Open Docker Desktop → Settings → Resources → WSL Integration → enable your distro.

Then open your WSL2 terminal and run all `make` commands from there — no extra tools needed.

## Quick Start

```bash
git clone https://github.com/contento/linux-dev.git
cd linux-dev
```

### macOS / Linux / WSL2

```bash
./start.sh --build          # build image then start (first time)
./start.sh                  # start with Ubuntu 26.04 LTS (default)
./start.sh debian           # start with Debian 13 (trixie)
./start.sh --silent         # skip confirmation prompt
./start.sh --help           # show usage
```

### Windows 11 (PowerShell)

Requires **PowerShell 7+** (`pwsh`). Install it with:

```powershell
winget install Microsoft.PowerShell
```

Then run from a `pwsh` terminal:

```powershell
.\start.ps1 -Build               # build image then start (first time)
.\start.ps1                      # start with Ubuntu 26.04 LTS (default)
.\start.ps1 -Distro debian       # start with Debian 13 (trixie)
.\start.ps1 -Silent              # skip confirmation prompt
.\start.ps1 -Help                # show usage
```

Both scripts start the container if it is not already running, then drop you into a bash shell. Use `make` targets for finer-grained control.

## Supported Distributions

| Distribution | Base Image | Status |
| --- | --- | --- |
| Ubuntu 26.04 LTS (resolute) | `ubuntu:26.04` | ✅ Default |
| Debian 13 (trixie) | `debian:trixie` | ✅ Supported |
| Arch Linux | N/A | ⏳ Planned |

```bash
make up-ubuntu   # Ubuntu 26.04 LTS
make up-debian   # Debian 13 (trixie)

# or inline
BASE_IMAGE=debian:trixie docker-compose up -d
```

## Configuration

### Build Arguments

| Argument | Default | Description |
| --- | --- | --- |
| `BASE_IMAGE` | `ubuntu:26.04` | Base distro image |
| `INCLUDE_EXTRA_TOOLS` | `true` | Install bat, fzf, htop, jq, tmux, vim, zsh via apt |
| `SETUP_DOTFILES` | `true` | Clone and apply contento/dotfiles |

```bash
# Minimal image (no extra tools, no dotfiles)
docker-compose build \
  --build-arg INCLUDE_EXTRA_TOOLS=false \
  --build-arg SETUP_DOTFILES=false
```

### Resource Limits

Defaults in `docker-compose.yml`:

| Resource | Limit | Reservation |
| --- | --- | --- |
| CPU | 4 cores | 1 core |
| Memory | 4 GB | 512 MB |

Adjust in `docker-compose.yml` under `deploy.resources` as needed.

## Included Tools

### Always installed (base image)

`git`, `curl`, `wget`, `build-essential`, `ca-certificates`, `gnupg`, `sudo`

### Optional (INCLUDE_EXTRA_TOOLS=true)

`bat`, `fzf`, `htop`, `jq`, `less`, `man-db`, `tmux`, `vim`, `zsh`

### From contento/dotfiles (SETUP_DOTFILES=true)

`bootstrap.sh` installs the full toolchain via apt + Homebrew, then `stow-all.sh` symlinks configs into `$HOME`. Includes: `neovim`, `starship`, `eza`, `ripgrep`, `lazygit`, `atuin`, `yazi`, `zoxide`, `node`, `go`, `rustup`, `tmux` plugins, zsh plugins, and more.

## Dotfiles Integration

When `SETUP_DOTFILES=true` (default), the build:

1. Clones `https://github.com/contento/dotfiles.git` to `~/.dotfiles`
2. Runs `bootstrap.sh` — installs packages and terminal toolchain
3. Runs `stow-all.sh` — symlinks configs into `$HOME`

To skip: `--build-arg SETUP_DOTFILES=false`

## Architecture

```text
ubuntu:26.04 / debian:trixie
    ↓
  base  — apt packages, locale, dev user
    ↓
   dev  — optional tools, dotfiles (bootstrap + stow)
```

## Persistence

- **Workspace**: `./workspace` → `/home/dev/workspace` (bind mount, local)
- **Home dir**: `dev_home` Docker volume (survives container restarts)
- Data is lost only with `docker-compose down -v`

## SSH Access

### 1. Build with SSH server enabled

```bash
make build-ssh
# or
INCLUDE_SSH_SERVER=true docker-compose build
```

### 2. Start the container with your public key

```bash
SSH_PUBLIC_KEY="$(cat ~/.ssh/id_ed25519.pub)" docker-compose up -d
```

The key is written to `/home/dev/.ssh/authorized_keys` on first start.

### 3. Connect

```bash
ssh -p 2222 dev@localhost
```

Or add an entry to `~/.ssh/config` for convenience:

```sshconfig
Host linux-dev
  HostName localhost
  Port 2222
  User dev
  IdentityFile ~/.ssh/id_ed25519
```

Then simply:

```bash
ssh linux-dev
```

Password login is disabled — key-based auth only. Change the host port by setting `SSH_PORT` before starting (default: `2222`).

## Multi-platform

The published GHCR image supports `linux/amd64` and `linux/arm64` (built automatically on push to `main`).

To build locally for both platforms:

```bash
make build-multiplatform
```

Requires a `docker buildx` builder with multi-platform support. Docker Desktop includes one by default.

## Lifecycle

```bash
make up        # start
make exec      # enter shell
make down      # stop
make rebuild   # clean rebuild
make ps        # status
make logs      # follow logs
make clean     # stop + remove volumes
```

## Troubleshooting

```bash
# Force rebuild without cache
docker-compose build --no-cache

# Inspect running container
docker-compose exec dev whoami   # should print: dev
docker-compose exec dev pwd      # should print: /home/dev/workspace

# View build logs with timestamps
docker build --progress=plain -t linux-dev:latest . 2>&1 | tee build.log
```

## Contributing

See [TODO.md](TODO.md) for roadmap. See [CLAUDE.md](CLAUDE.md) for development guidelines.

## License

MIT — See [LICENSE](LICENSE)
