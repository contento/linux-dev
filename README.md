# linux-dev: Lightweight Terminal Development Environment

A minimal, reproducible Docker development environment for Linux distributions.

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

- **Multi-distro**: Ubuntu 26.04 LTS (default), Debian 13 (trixie), Arch Linux
- **Flexible**: Build args for customizing tools and dotfiles setup
- **Reproducible**: Consistent environment across machines
- **User-safe**: Non-root `dev` user with passwordless sudo
- **Terminal-first**: bash by default; opt in to zsh + starship + full CLI toolchain via contento/dotfiles
- **SSH-ready**: SSH server included by default, key-based auth only
- **Multi-instance**: Run multiple named containers without port or volume collisions

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

Then open your WSL2 terminal and run all commands from there — no extra tools needed.

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

Both scripts start the container if it is not already running, then drop you into a bash shell. Run `zsh` once inside if you prefer that.

## Supported Distributions

| Distribution | Base Image | Status |
| --- | --- | --- |
| Ubuntu 26.04 LTS (resolute) | `ubuntu:26.04` | ✅ Default |
| Debian 13 (trixie) | `debian:trixie-slim` | ✅ Supported |
| Arch Linux | `archlinux:latest` | ✅ Supported |

```bash
./start.sh ubuntu   # Ubuntu 26.04 LTS
./start.sh debian   # Debian 13 (trixie)
make build-arch    # Arch Linux
```

## Multiple Instances

Each named instance gets its own container, volume, and SSH port — no collisions:

```bash
./start.sh                          # ubuntu-dev, SSH :2222
./start.sh debian                   # debian-dev, SSH :2223
./start.sh --name work              # work,        SSH :2222
./start.sh --name work --port 2224  # work,        SSH :2224
```

```powershell
.\start.ps1                              # ubuntu-dev, SSH :2222
.\start.ps1 -Distro debian              # debian-dev, SSH :2223
.\start.ps1 -Name work -Port 2224       # work,        SSH :2224
```

Default SSH ports: ubuntu → `2222`, debian → `2223`.

## Levels

Choose the right level for your use case:

| Level | Size | Shell | Tools | SSH | Python/Node |
| --- | --- | --- | --- | --- | --- |
| `minimal` | ~200MB | bash | base only | ✗ | ✗ |
| `dev` | ~500MB | bash + zsh | bat, fzf, htop, jq, tmux, vim | ✓ | ✗ |
| `full` | ~1GB | bash + zsh | dev + python3 + nodejs + npm | ✓ | ✓ |

```bash
# Minimal — just the essentials
LEVEL=minimal docker compose up -d

# Dev — full terminal experience (default)
docker compose up -d

# Full — dev + Python + Node.js
LEVEL=full docker compose up -d
```

## Configuration

### Build Arguments

| Argument | Default | Description |
| --- | --- | --- |
| `BASE_IMAGE` | `ubuntu:26.04` | Base distro image |
| `LEVEL` | `dev` | `minimal` (~200MB), `dev` (~500MB), `full` (~1GB) |
| `SETUP_DOTFILES` | `false` | Clone and apply contento/dotfiles (opt-in) |

```bash
# Minimal image (~200MB — base packages only, no extra tools, no SSH)
docker compose build --build-arg LEVEL=minimal

# Dev image (~500MB — extra tools + SSH, default)
docker compose build

# Full image (~1GB — dev + python3 + nodejs + npm)
docker compose build --build-arg LEVEL=full

# Opt in to dotfiles at build time
SETUP_DOTFILES=true docker compose build
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

`git`, `curl`, `wget`, `build-essential` (gcc, make, libc-dev), `ca-certificates`, `gnupg`, `openssh-client`, `sudo`, `unzip`, `xz-utils` — plus `grep`/coreutils that ship in the base image.

### Dev level

`bash` (default login shell), `zsh` (available if you prefer), `openssh-server`, `bat`, `dnsutils` (dig/nslookup), `fzf`, `htop`, `iputils-ping`, `jq`, `less`, `man-db`, `python-is-python3`, `ripgrep` (rg), `rsync`, `tmux`, `tree`, `vim`

### Full level

All dev tools + `python3`, `python3-pip`, `nodejs`, `npm`

### From contento/dotfiles (opt-in via SETUP_DOTFILES=true)

`bootstrap.sh` installs the full toolchain via apt + Homebrew, then `stow-all.sh` symlinks configs into `$HOME`. Includes: `neovim`, `starship`, `eza`, `ripgrep`, `lazygit`, `atuin`, `yazi`, `zoxide`, `node`, `go`, `rustup`, `tmux` plugins, zsh plugins, and more.

All Homebrew-installed tools are on `PATH` out of the box.

## Dotfiles Integration

Dotfiles are **off by default**. Opt in with `SETUP_DOTFILES=true` at build time, runtime, or both:

```bash
SETUP_DOTFILES=true docker compose build      # bake into image
SETUP_DOTFILES=true ./start.sh                # also bootstrap into a fresh volume
```

When enabled, the setup runs in two phases:

**Build time** (baked into the image):

1. Clones `https://github.com/contento/dotfiles.git` to `~/.dotfiles`
2. Runs `bootstrap.sh` — installs packages and terminal toolchain
3. Runs `stow-all.sh` — symlinks configs into `$HOME`

**Runtime** (entrypoint.sh, first start):

The `dev_home` volume mounts over `/home/dev`, shadowing the build-time home dir. If `SETUP_DOTFILES=true` is also set at runtime and `~/.dotfiles/.git` is absent, `entrypoint.sh` re-runs the bootstrap into the live volume.

## Architecture

```text
ubuntu:26.04 / debian:trixie-slim / archlinux:latest
    ↓
  base  — apt/pacman packages, locale, dev user
    ↓
   dev  — bash + zsh (dev/full), SSH (dev/full), tools (dev/full); starship & dotfiles when SETUP_DOTFILES=true
```

## Persistence

- **Workspace**: `./workspace` → `/home/dev/workspace` (bind mount, local)
- **Home dir**: `<name>_dev_home` Docker volume (survives container restarts)
- Data is lost only with `docker compose down -v`

## SSH Access

SSH server is included in dev and full levels. To disable: `--build-arg LEVEL=minimal`.

### 1. Start with your public key

```bash
SSH_PUBLIC_KEY="$(cat ~/.ssh/id_ed25519.pub)" ./start.sh
```

The key is written to `/home/dev/.ssh/authorized_keys` on first start.

### 2. Connect

```bash
ssh -p 2222 dev@localhost
```

Or add an entry to `~/.ssh/config`:

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

Password login is disabled — key-based auth only. Default ports: ubuntu → `2222`, debian → `2223`. Override with `--port` / `-Port`.

## Published image (GHCR)

The published `ghcr.io/contento/linux-dev` image is **intentionally minimal** so consumers can layer their own tools on top. Built automatically on push to `main` for `linux/amd64` and `linux/arm64`.

What's inside (~175 MB):

- Base toolchain: `cc`/`gcc`, `make`, `git`, `curl`, `wget`, `grep`, `ssh` client, `sudo`, `unzip`, `xz-utils`
- Shell: `bash` (no zsh at the minimal level — install it yourself or build with `LEVEL=dev`)
- Stock home directory — no dotfiles, no Homebrew, no starship

**Not included** in the published image (opt-in via build args when you build locally):

| Off in GHCR | Build arg to enable |
| --- | --- |
| Extra apt tools (`bat`, `fzf`, `htop`, `jq`, `ripgrep`, `tree`, `tmux`, `vim`, …) | `LEVEL=dev` or `LEVEL=full` |
| SSH server (`sshd`) | `LEVEL=dev` or `LEVEL=full` |
| contento/dotfiles + bootstrap.sh + stow-all.sh | `SETUP_DOTFILES=true` |

The local `./start.sh` / `make up` flow builds with extras and SSH **on** by default (dotfiles still off) — that's the daily-driver image. The minimal GHCR image is for users who want a clean base to extend.

To reproduce the published image locally for both platforms:

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
docker compose build --no-cache

# Inspect running container
docker compose exec dev whoami   # should print: dev
docker compose exec dev pwd      # should print: /home/dev/workspace

# View build logs with timestamps
docker build --progress=plain -t linux-dev:latest . 2>&1 | tee build.log
```

## Contributing

See [TODO.md](TODO.md) for roadmap. See [CLAUDE.md](CLAUDE.md) for development guidelines.

## License

MIT — See [LICENSE](LICENSE)
