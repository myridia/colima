<img src="llama.svg" alt="Llama" width="120">

# colima-test

Docker-compatible container runtime on Linux and macOS via **Colima** (a Lima
VM) + the **docker CLI** — no Docker Desktop, no desktop app. This folder is
the Linux test bed for the click-to-start workflow:

`colima.setup.sh` (once) → `./start.sh` → stack up → `./stop.sh` → stack down.

## What it tests

- Colima boots a VM and exposes a Docker-compatible engine to the local docker CLI.
- `docker compose up -d` runs the preconfig stack unchanged.
- Bind mounts (`./site`) and port mapping (`8080`) behave like real Docker.
- Same scripts/commands as the macOS one-click launcher — parity check only.

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Test stack: nginx (web) + whoami (api) |
| `nginx.conf` | nginx proxy `/api/` → whoami container |
| `site/` | Static page served by nginx (bind-mount test) |
| `colima.setup.sh` | One-time install: qemu + docker CLI + colima, then start |
| `start.sh` | One-click start (VM + stack) |
| `stop.sh` | Bring stack down, stop VM |
| `status.sh` | VM + stack status |

## Quickstart (Linux)

```bash
./colima.setup.sh        # one time: install + start VM + docker context
./start.sh               # click-to-start, every time
```

Then open http://localhost:8080 (details at `/api/`). Tear down with `./stop.sh`.

## Requirements

- Linux (Debian/Ubuntu shown) or macOS.
- `/dev/kvm` on Linux for speed; without it QEMU falls back to slow emulation.
- The dev container has **no KVM** — colima must be started on the real host.

## macOS parity

Same Colima engine, same docker CLI, same compose file. On macOS install with
`brew install colima docker docker-compose`; `colima start` replaces the VM
setup, and the click-to-start script is the same `./start.sh`.