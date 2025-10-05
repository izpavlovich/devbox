# The blueprint

## 1. One reverse proxy for everything (stop binding ports)

**Goal:** never `-p 3000:3000` again. That’s where conflicts start.

* Run a single Traefik (or Nginx Proxy Manager) container on your Mac that:

  * Listens on `:80` and `:443`
  * Routes `http(s)://<service>.<project>.localhost` → your containers by labels
  * Gives you per-service hostnames instead of ports
* All app containers expose **internal** ports only; no host bindings.

> Result: zero port collisions, side-by-side stacks, nice URLs, HTTPS locally if you want.

### Traefik once-and-forget (global) `reverese-proxy/docker-compose.yml`

