# DevBox - Universal Development Environment

> Your bulletproof, cross-platform development setup for .NET, Python, Go, JavaScript, TypeScript, and React—no more "works on my machine" or port conflicts.

---

## Philosophy

This repository serves as the **single source of truth** for development environment configuration across:

* **macOS** (primary)
* **Windows** (WSL2 + Docker Desktop)
* **Linux** (Ubuntu + Docker)

**Core principles:**

1. **Zero port conflicts** - hostname-based routing via reverse proxy
2. **Zero version hell** - all tooling in containers, pinned by digest
3. **Unified workflow** - same commands on macOS, Windows, Linux
4. **Fast iteration** - hot reload for all stacks

---

## The Setup

### Prerequisites

| Platform | Requirements |
|----------|-------------|
| **macOS** | Docker Desktop 4.25+, VS Code |
| **Windows** | WSL2, Docker Desktop (WSL2 backend), VS Code with Remote-WSL |
| **Linux** | Docker 24+, Docker Compose v2, VS Code |

### Installation

#### macOS
```bash
# Install Docker Desktop
brew install --cask docker
# Install VS Code
brew install --cask visual-studio-code
```

#### Windows
```powershell
# Install WSL2 (PowerShell as Admin)
wsl --install -d Ubuntu-22.04
# Install Docker Desktop (enable WSL2 integration)
winget install Docker.DockerDesktop
# Install VS Code
winget install Microsoft.VisualStudioCode
```

#### Linux (Ubuntu)
```bash
# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# Install Docker Compose v2
sudo apt-get update && sudo apt-get install docker-compose-plugin
# Install VS Code
sudo snap install code --classic
```

---

## Architecture

### 1. Global Reverse Proxy (Traefik)

**The secret sauce for zero port conflicts.**

All services route through a single Traefik instance that listens on `:80` and `:443`, routing requests by hostname to containers on internal ports only.

**Setup (run once per machine):**

```bash
cd docker/reverse-proxy

# 1. Generate local HTTPS certificates (uses mkcert)
./setup-local-certs.sh

# 2. Start Traefik
docker compose up -d
```

**Access Traefik dashboard:** `http://localhost:8080` (when port is uncommented)

**How it works:**
- Each project joins the shared `edge` network
- Containers expose internal ports (no `-p` bindings)
- Traefik routes by hostname: `https://<service>.<project>.localhost`
- HTTPS by default with mkcert-generated certificates
- HTTP requests automatically redirect to HTTPS
- DNS: `*.localhost` domains automatically resolve to `127.0.0.1` (RFC 6761)

### 2. Per-Project Compose Files

Each project gets its own `docker-compose.yml` with:
- Services joined to the `edge` network
- Traefik labels for routing
- Compose profiles for stack toggling
- Image pinning by digest

**Example structure:**
```
my-project/
├── docker-compose.yml         # Multi-stack definitions
├── .devcontainer/
│   └── devcontainer.json     # VS Code dev container config
├── docker/
│   ├── Dockerfile.dotnet     # .NET hot reload
│   ├── Dockerfile.python     # Python/FastAPI reload
│   ├── Dockerfile.go         # Go live reload (air)
│   └── Dockerfile.node       # Node/React HMR
├── .env                      # Non-sensitive defaults
├── .env.local               # Secrets (gitignored)
├── Makefile or Taskfile.yml # Command shortcuts
└── src/
    ├── dotnet/
    ├── python/
    ├── go/
    └── frontend/
```

---

## Supported Stacks

### Backend

| Stack | Hot Reload | Internal Port | Default URL |
|-------|-----------|---------------|-------------|
| **.NET 8** | `dotnet watch` | 8080 | `https://api.<project>.localhost` |
| **Python/FastAPI** | `uvicorn --reload` | 8000 | `https://py.<project>.localhost` |
| **Go** | `air` | 8081 | `https://go.<project>.localhost` |

### Frontend

| Stack | Hot Reload | Internal Port | Default URL |
|-------|-----------|---------------|-------------|
| **React/Vite** | HMR | 5173 | `https://app.<project>.localhost` |
| **Next.js** | Fast Refresh | 3000 | `https://next.<project>.localhost` |

### Databases

All databases run on **internal ports only** (no host bindings):
- **PostgreSQL**: internal `:5432`
- **MongoDB**: internal `:27017`
- **Redis**: internal `:6379`

---

## Daily Workflow

### Starting a New Project

```bash
# 1. Clone/create project
git clone <repo> && cd <repo>

# 2. Start services (all or by profile)
docker compose up -d --build

# 3. Open in VS Code
code .

# 4. Reopen in Container (Cmd/Ctrl+Shift+P → "Reopen in Container")
# Now you're coding inside the container with all tools available

# 5. Access your services
open https://api.myproject.localhost      # .NET API
open https://py.myproject.localhost       # Python API
open https://app.myproject.localhost      # React frontend
```

### Common Commands

Use `Makefile` or `Taskfile.yml` for consistency:

```bash
make up        # Start all services
make down      # Stop and remove containers
make logs      # Follow logs
make sh        # Shell into container
make test      # Run tests in container
```

### Using Compose Profiles

Toggle parts of your stack without editing YAML:

```bash
# Run only Python + database
docker compose --profile py --profile db up -d --build

# Run .NET + React frontend + database
docker compose --profile net --profile frontend --profile db up -d --build

# Run everything
docker compose --profile py --profile net --profile go --profile frontend --profile db up -d --build
```

---

## Platform-Specific Notes

### macOS
- Uses **virtiofs** for fast file sync (Docker Desktop 4.25+)
- If you experience slowness with large repos, consider [Mutagen](https://mutagen.io/)
- Traefik runs natively on macOS Docker Desktop

### Windows (WSL2)
- **Always work inside WSL2 filesystem** (`\\wsl$\Ubuntu\home\<user>\projects`)
- Never clone repos to Windows filesystem (`/mnt/c/`) - performance is poor
- Docker Desktop must have WSL2 integration enabled for your distro
- Use VS Code with Remote-WSL extension
- Traefik works identically to macOS

```bash
# Check WSL integration
wsl -l -v  # Should show Docker-desktop running

# Open project in WSL from Windows
wsl cd ~/projects/myproject && code .
```

### Linux (Ubuntu)
- Docker socket at `/var/run/docker.sock` - ensure your user is in `docker` group
- Add to `/etc/hosts` if `.localhost` doesn't resolve:
  ```
  127.0.0.1 *.myproject.localhost
  ```
- Or use `dnsmasq` for wildcard `.localhost` resolution

---

## Avoiding Common Pitfalls

### ✅ Do's

| Problem | Solution |
|---------|----------|
| Port conflicts | Use Traefik + internal ports only (no `-p` flags) |
| Version hell | Pin images by digest, use devcontainers for tooling |
| "Works on my machine" | All tooling in containers; CI = dev environment |
| Slow file sync | Use virtiofs (macOS/Win), avoid `/mnt/c/` on WSL2 |
| Database collisions | Namespace with `COMPOSE_PROJECT_NAME` (auto per `name:`) |

### ❌ Don'ts

| Bad Practice | Why | Better Approach |
|-------------|-----|-----------------|
| `-p 3000:3000` in compose | Port conflicts | Use Traefik labels + expose only |
| `FROM python:latest` | Surprise breakage | Pin by digest: `python:3.12-slim@sha256:...` |
| Installing tools locally | Version drift | Use devcontainer with all tools inside |
| WSL2 + Windows filesystem | 10-100x slower | Clone repos to `~/projects` in WSL |
| Hardcoded secrets in `.env` | Security risk | Use `.env.local` (gitignored) or 1Password CLI |

---

## Example: Health Check API

See [`docker/health/`](./docker/health/) for a complete example showing:
- FastAPI service with health check endpoints (`/health`, `/ready`, `/live`)
- Dockerfile for Python service
- docker-compose.yml with Traefik HTTPS integration
- Access at: `https://health.devbox.localhost`

**Try it:**
```bash
cd docker/health
docker compose up -d --build
curl https://health.devbox.localhost/health
```

See [`docker/reverse-proxy/`](./docker/reverse-proxy/) for the global Traefik setup with HTTPS.

---

## Advanced: Tooling & Automation

### Auto-updating Dependencies

Use **Renovate** or **Dependabot** to automatically update:
- Base image digests
- Package versions
- Docker Compose image tags

### Linting & Formatting (in containers)

| Stack | Tools |
|-------|-------|
| **.NET** | `dotnet format`, Roslyn analyzers |
| **Python** | `ruff`, `black`, `mypy` |
| **Go** | `gofumpt`, `staticcheck`, `golangci-lint` |
| **JS/TS** | `eslint`, `prettier`, `tsc` |

Run via `docker compose exec`:
```bash
docker compose exec api-python ruff check .
docker compose exec api-dotnet dotnet format --verify-no-changes
docker compose exec api-go staticcheck ./...
```

### Pre-commit Hooks

Install [pre-commit](https://pre-commit.com/) to run formatters before every commit:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: dotnet-format
        name: .NET Format
        entry: docker compose exec -T api-dotnet dotnet format
        language: system
        pass_filenames: false
```

### CI/CD Parity

Your CI pipeline should:
1. Use the **same Dockerfiles** as local dev
2. Use the **same pinned digests**
3. Run the **same test/lint commands**

Example GitHub Actions:
```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: docker compose --profile py run --rm api-python pytest
```

---

## Troubleshooting

### Traefik not routing

```bash
# Check Traefik is running
docker ps | grep traefik

# Verify edge network exists
docker network ls | grep edge

# Check container joined edge network
docker compose ps
docker inspect <container-id> | grep edge
```

### Slow file sync (macOS/WSL2)

```bash
# macOS: Verify virtiofs is enabled
# Docker Desktop → Settings → General → "VirtioFS" checked

# WSL2: Verify file location
pwd  # Should be /home/<user>/..., NOT /mnt/c/
```

### Port already in use

```bash
# Should NEVER happen with this setup
# If it does, check for rogue `-p` flags:
docker compose config | grep ports
```

### Container can't reach another service

```bash
# Check both are on the same network
docker compose exec api-python ping db
# Should resolve to internal IP
```

### HTTPS certificate invalid in browser

```bash
# Verify mkcert CA is installed
mkcert -install

# Clear browser cache
# Chrome: chrome://net-internals/#sockets → "Flush socket pools"
# Chrome: chrome://net-internals/#hsts → delete domain entry

# Restart browser completely

# Test certificate with curl
curl -vI https://health.devbox.localhost 2>&1 | grep "SSL certificate"
# Should show: "SSL certificate verify ok"
```

---

## Resources

- [Docker Compose Profiles](https://docs.docker.com/compose/profiles/)
- [Traefik Docker Provider](https://doc.traefik.io/traefik/providers/docker/)
- [mkcert - Local HTTPS certificates](https://github.com/FiloSottile/mkcert)
- [VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers)
- [Image Digest Pinning](https://docs.docker.com/engine/reference/commandline/pull/#pull-an-image-by-digest-immutable-identifier)
- [WSL2 Best Practices](https://learn.microsoft.com/en-us/windows/wsl/filesystems)

---

## Contributing

1. Test changes on **all three platforms** (macOS, Windows/WSL2, Linux)
2. Update this README if you change the setup
3. Pin all new images by digest
4. Verify hot reload works for all stacks

---

## License

MIT - do whatever you want with this setup.

---

**Questions?** Open an issue. **It works?** Star the repo and tell a friend—fewer "works on my machine" bugs for everyone.
