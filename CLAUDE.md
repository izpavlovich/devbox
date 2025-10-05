# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DevBox is a universal development environment setup that provides cross-platform (macOS, Windows/WSL2, Linux) Docker-based development with zero port conflicts and unified workflows.

**Core Architecture:** All services route through a global Traefik reverse proxy that provides hostname-based routing (`http://<service>.<project>.localhost`) instead of port-based access. This eliminates port conflicts and allows multiple projects to run simultaneously.

## Key Commands

### Initial Setup (One-time per machine)

Start the global reverse proxy:
```bash
cd docker/reverse-proxy
docker compose up -d
```

Verify Traefik is running:
```bash
docker ps | grep traefik
docker network ls | grep edge
```

### Project Workflow

Start all services:
```bash
docker compose up -d --build
```

Start specific stack profiles:
```bash
# Python + database only
docker compose --profile py --profile db up -d --build

# .NET + React frontend + database
docker compose --profile net --profile frontend --profile db up -d --build

# All stacks
docker compose --profile py --profile net --profile go --profile frontend --profile db up -d --build
```

Stop services:
```bash
docker compose down
```

View logs:
```bash
docker compose logs -f [service-name]
```

Shell into container:
```bash
docker compose exec <service-name> /bin/bash
```

Run tests in container:
```bash
docker compose exec <service-name> <test-command>
# Examples:
docker compose exec api-python pytest
docker compose exec api-dotnet dotnet test
docker compose exec api-go go test ./...
```

Run linters/formatters:
```bash
docker compose exec api-python ruff check .
docker compose exec api-dotnet dotnet format --verify-no-changes
docker compose exec api-go staticcheck ./...
```

## Architecture Principles

### Traefik Reverse Proxy System

1. **Global Traefik container** runs on `:80` and `:443`, routing by hostname
2. **All projects join the shared `edge` network** (created by reverse-proxy)
3. **Services expose internal ports only** - never use `-p` port bindings in project compose files
4. **Routing via Traefik labels** - containers get labels like `traefik.http.routers.<name>.rule=Host(\`api.myproject.localhost\`)`

### Multi-Stack Support

Expected project structure supports multiple tech stacks in one repository:
- **Backend:** .NET 8 (port 8080), Python/FastAPI (port 8000), Go (port 8081)
- **Frontend:** React/Vite (port 5173), Next.js (port 3000)
- **Databases:** PostgreSQL (5432), MongoDB (27017), Redis (6379) - all internal

Each stack controlled via **Docker Compose profiles** to enable/disable independently.

### Image Management

- **Always pin images by digest** (`python:3.12-slim@sha256:...`) for reproducibility
- Avoid `latest` tags to prevent surprise breakage
- Use Renovate or Dependabot to auto-update digests

### Development Containers

Projects use VS Code devcontainers (`.devcontainer/devcontainer.json`) to:
- Provide all tooling inside containers (no local installs)
- Ensure dev environment matches CI/CD
- Support "Reopen in Container" workflow

## Platform-Specific Behavior

### macOS
- Uses virtiofs for fast file sync (Docker Desktop 4.25+)
- Traefik runs natively
- `.localhost` domains work out of the box

### Windows (WSL2)
- **CRITICAL:** All repos must be in WSL2 filesystem (`/home/<user>/projects`), never in `/mnt/c/`
- Docker Desktop must have WSL2 integration enabled
- Use VS Code with Remote-WSL extension
- Performance is 10-100x slower on Windows filesystem

### Linux (Ubuntu)
- User must be in `docker` group
- May need to add to `/etc/hosts`: `127.0.0.1 *.myproject.localhost`
- Or configure `dnsmasq` for wildcard `.localhost` resolution

## Important Patterns

### Service Access URLs

Services are accessed via hostname, not ports:
- .NET API: `http://api.<project>.localhost`
- Python API: `http://py.<project>.localhost`
- Go API: `http://go.<project>.localhost`
- React frontend: `http://app.<project>.localhost`
- Next.js frontend: `http://next.<project>.localhost`

### Compose File Structure

When creating/editing `docker-compose.yml`:
```yaml
services:
  my-service:
    build: ./docker/Dockerfile.stack
    networks:
      - edge  # Join shared Traefik network
    expose:
      - "8000"  # Internal port only
    # NEVER use 'ports:' - routing is via Traefik
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myservice.rule=Host(`myservice.project.localhost`)"
      - "traefik.http.services.myservice.loadbalancer.server.port=8000"
    profiles:
      - mystack  # Enable via --profile flag
networks:
  edge:
    external: true  # Created by reverse-proxy
```

### Hot Reload Configuration

Each stack requires specific hot-reload mechanisms:
- **.NET:** `dotnet watch run` in Dockerfile CMD
- **Python/FastAPI:** `uvicorn --reload`
- **Go:** Use `air` for live reload
- **React/Vite:** Built-in HMR
- **Next.js:** Built-in Fast Refresh

## Troubleshooting Checklist

If services aren't accessible:
1. Check Traefik is running: `docker ps | grep traefik`
2. Verify `edge` network exists: `docker network ls | grep edge`
3. Confirm service joined network: `docker inspect <container-id> | grep edge`
4. Check Traefik labels: `docker compose config | grep traefik`

If experiencing port conflicts:
- **Should never happen** - indicates rogue `-p` flag somewhere
- Check: `docker compose config | grep ports` should be empty

If containers can't communicate:
```bash
docker compose exec service-a ping service-b
# Should resolve to internal Docker network IP
```

If file changes aren't reflected:
- macOS: Verify virtiofs enabled in Docker Desktop settings
- Windows: Verify working in WSL2 filesystem with `pwd` (not `/mnt/c/`)
- Check volume mounts in `docker-compose.yml`

## Repository Structure

```
/
├── README.md                     # Full documentation (very comprehensive)
├── docker/
│   ├── reverse-proxy/
│   │   └── docker-compose.yml   # Global Traefik setup
│   ├── readme.md                # Brief architecture notes
│   └── health/                  # Empty directory
└── [project directories]        # Future project-specific setups
```

The `docker/reverse-proxy/` directory contains the one-time setup that all projects depend on. Individual projects would live alongside this repository or reference this setup pattern.
