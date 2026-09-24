# AGENTS.md — colima-test

## What this is
Test bed for the **Colima** (Lima VM) docker-compatible runtime + docker CLI,
no desktop app. Linux and macOS parity check for the click-to-start workflow.

## Stack
- `docker-compose.yml` — nginx:1.27-alpine (`colimatest_web`, port 8080) +
  traefik/whoami (`colimatest_api`). compose v2 (no `version:` key).
- nginx proxies `/api/` → api container; `./site` and `./nginx.conf` are
  bind-mounts (test host-folder sharing).
- Containers prefixed `colimatest_*` per workspace convention.

## Commands
- `./start.sh` — `colima start` + `docker context use colima` + `compose up -d`
- `./stop.sh` — `compose down` + `colima stop`
- `./status.sh` — VM + stack status
- `./colima.setup.sh` — one-time Linux install (qemu, docker CLI, colima)

## Conventions
- No comments in code unless asked.
- Verify with `bash -n <script>`.
- **Environment**: the dev container has no `/dev/kvm` and is itself a
  container — colima must run on the real host, never here. docker/cargo/php
  availability is not guaranteed in this workspace; check before relying on it.

## Workflow
1. Read this file.
2. Check README for the logo (`llama.svg` present).
3. Make minimal changes, run `bash -n` on any touched shell script.
4. Do not commit — commits are done by the user only.