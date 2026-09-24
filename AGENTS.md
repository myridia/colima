# AGENTS.md — colima-test

## What this is
Test bed for the **Colima** (Lima VM) docker-compatible runtime + docker CLI,
no desktop app. Linux and macOS parity check for the click-to-start workflow.

## Stack
- `dockers/docker-compose.yml` — nginx:1.27-alpine (`colimatest_web`, port
  8080) + traefik/whoami (`colimatest_api`). compose v2 (no `version:` key).
- nginx proxies `/api/` → api container; `./nginx.conf` (in `dockers/`) and
  `../site` (at project root) are bind-mounts (test host-folder sharing).
- Containers prefixed `colimatest_*` per workspace convention.

## Task runner — `ask.sh`
Single hub replacing the loose scripts. Run `./ask.sh` (interactive menu) or
`./ask.sh <id>` (one-shot). `colima.bin` is a transient download artifact,
gitignored.

| ID | Task |
|----|------|
| 1 | Setup — install colima + lima + kitty (idempotent; Linux apt since colima needs limactl on PATH — fetch lima tarball from GitHub releases) |
| 2 | Start — `colima start` + `docker context use colima` + `compose up -d` (`dockers/docker-compose.yml`) |
| 3 | Stop — `compose down` + `colima stop` |
| 4 | Status — VM + docker context + stack |
| 5 | Dev — open `myridia/opencode` in kitty; mounts `site/` + SSH identity keys read-only |

## Conventions
- No comments in code unless asked.
- Verify with `bash -n <script>`.
- **Environment**: the dev container has no `/dev/kvm` and is itself a
  container — colima must run on the real host, never here. docker/cargo/php
  availability is not guaranteed in this workspace; check before relying on it.
- `ask.sh` is bash (arrays for the SSH mounts); macOS ships bash 3.2 — keep
  syntax 3.2-safe (use `${arr[@]+"${arr[@]}"}` expansion).
- Dev container runs as root; keys mount to `/root/.ssh` read-only so the
  host's `~/.ssh/config` (owner mismatch → ssh "Bad owner" error) is excluded.

## Workflow
1. Read this file.
2. Check README for the logo (`llama.svg` present).
3. Make minimal changes, run `bash -n` on any touched shell script.
4. Do not commit — commits are done by the user only.