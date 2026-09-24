<img src="llama.svg" alt="Llama" width="120">

# colima-test

Docker-compatible container runtime on Linux and macOS via **Colima** (a Lima
VM) + the **docker CLI** — no Docker Desktop, no desktop app. This folder is
the Linux test bed for the click-to-start workflow. Everything runs through
the `ask.sh` task runner:

`./ask.sh 1` (once) → `./ask.sh 2` → stack up → `./ask.sh 3` → stack down.

## What it tests

- Colima boots a VM and exposes a Docker-compatible engine to the local docker CLI.
- `docker compose up -d` runs the preconfig stack unchanged.
- Bind mounts (`./site`) and port mapping (`8080`) behave like real Docker.
- Same scripts/commands as the macOS one-click launcher — parity check only.

| File | Purpose |
|------|---------|
| `ask.sh` | Task runner hub: setup / start / stop / status / dev container |
| `dockers/` | Docker config: `docker-compose.yml` (nginx web + whoami api), `nginx.conf` |
| `site/` | Static page served by nginx (bind-mount test) |
| `llama.svg` | Project logo |

## Quickstart (Linux)

```bash
./ask.sh 1     # one time: install colima + lima + kitty, start VM + context
./ask.sh 2     # click-to-start, every time
```

Or run `./ask.sh` plain for the interactive menu. Then open
http://localhost:8080 (details at `/api/`). Tear down with `./ask.sh 3`.

| Task | What it does |
|------|--------------|
| 1 | Setup — install colima + lima + kitty (idempotent) |
| 2 | Start — boot VM + `docker compose up -d` |
| 3 | Stop — `compose down` + stop VM |
| 4 | Status — VM / docker context / stack |
| 5 | Dev — open the `myridia/opencode` container (site/ + SSH keys mounted) |

## Requirements

- Linux (Debian/Ubuntu shown) or macOS.
- `/dev/kvm` on Linux for speed; without it QEMU falls back to slow emulation.
- The dev container has **no KVM** — colima must be started on the real host.

## macOS parity

Same Colima engine, same docker CLI, same compose file. Task 1 on macOS does
`brew install colima docker docker-compose --cask kitty` (lima comes along as a
dependency — no manual `limactl`). Task 2 is identical.