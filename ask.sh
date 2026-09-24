#!/bin/bash
set -euo pipefail

# colima-test task runner — single hub for setup, start/stop/status and the
# dev container. Usage: ./ask.sh  (menu)   or   ./ask.sh <task-id>

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

setup() {
  OS="$(uname -s)"
  ARCH="$(uname -m)"
  case "$OS" in
    Linux)  REL_OS="Linux" ;;
    Darwin) REL_OS="Darwin" ;;
    *) echo "ERROR: unsupported OS: ${OS}" >&2; return 1 ;;
  esac
  case "$ARCH" in
    x86_64|amd64)  REL_ARCH="x86_64" ;;
    aarch64|arm64) REL_ARCH="aarch64" ;;
    *) echo "ERROR: unsupported arch: ${ARCH}" >&2; return 1 ;;
  esac

  echo "==> Detected: ${OS} (${ARCH})"

  if [ "$OS" = "Darwin" ]; then
    echo "==> Checking Homebrew"
    if ! command -v brew >/dev/null 2>&1; then
      echo "ERROR: Homebrew not found. Install it first: https://brew.sh" >&2
      return 1
    fi

    echo "==> Installing colima + docker CLI (brew)"
    brew install colima docker docker-compose

    echo "==> Installing kitty (terminal for the dev container)"
    if [ -x /Applications/kitty.app/Contents/MacOS/kitty ]; then
      echo "kitty already installed"
    else
      brew install --cask kitty
    fi
  elif [ "$OS" = "Linux" ]; then
    echo "==> Installing qemu + docker CLI (apt)"
    sudo apt-get update
    sudo apt-get install -y docker.io docker-compose qemu-system-x86 qemu-utils

    LATEST_JSON="$(mktemp)"
    trap 'rm -f "$LATEST_JSON"' EXIT

    if ! command -v colima >/dev/null 2>&1; then
      curl -fsSL -o "$LATEST_JSON" https://api.github.com/repos/abiosoft/colima/releases/latest
      LATEST="$(grep -m1 '"tag_name"' "$LATEST_JSON" | cut -d'"' -f4)"
      COLI_VERSION="${LATEST#v}"

      echo "==> Installing colima ${COLI_VERSION} (${REL_ARCH})"
      DEST="$ROOT/colima.bin"
      URL="https://github.com/abiosoft/colima/releases/download/v${COLI_VERSION}/colima-${REL_OS}-${REL_ARCH}"

      rm -f "$DEST.part"
      if ! curl -fsSL --retry 3 -o "$DEST.part" "$URL"; then
        echo "curl failed (23 = write). Trying wget..."
        rm -f "$DEST.part"
        if ! command -v wget >/dev/null 2>&1 || ! wget -q -O "$DEST.part" "$URL"; then
          echo "ERROR: both curl and wget failed. Diagnostics:" >&2
          df -h "$(dirname "$DEST")" >&2
          echo "Try manually:" >&2
          echo "  wget -O /tmp/colima '$URL' && ls -l /tmp/colima" >&2
          rm -f "$DEST.part"
          return 1
        fi
      fi
      mv "$DEST.part" "$DEST"
      sudo install -m 0755 "$DEST" /usr/local/bin/colima
    else
      echo "==> colima already installed: $(command -v colima)"
    fi

    if ! command -v limactl >/dev/null 2>&1; then
      curl -fsSL -o "$LATEST_JSON" https://api.github.com/repos/lima-vm/lima/releases/latest
      LATEST="$(grep -m1 '"tag_name"' "$LATEST_JSON" | cut -d'"' -f4)"
      LIMA_VERSION="${LATEST#v}"

      echo "==> Installing lima (limactl) ${LIMA_VERSION} (${REL_ARCH})"
      LIMA_TMP="$(mktemp -d)"
      LIMA_URL="https://github.com/lima-vm/lima/releases/download/v${LIMA_VERSION}/lima-${LIMA_VERSION}-${REL_OS}-${REL_ARCH}.tar.gz"
      curl -fsSL --retry 3 -o "$LIMA_TMP/lima.tgz" "$LIMA_URL"
      tar -xzf "$LIMA_TMP/lima.tgz" -C "$LIMA_TMP"
      sudo install -m 0755 "$LIMA_TMP/bin/limactl" "$LIMA_TMP/bin/lima" /usr/local/bin/
      sudo mkdir -p /usr/local/share/man
      sudo cp -R "$LIMA_TMP/share/lima" /usr/local/share/
      sudo cp -R "$LIMA_TMP/share/man" /usr/local/share/man/
      rm -rf "$LIMA_TMP"
    else
      echo "==> limactl already installed: $(command -v limactl)"
    fi
  fi

  if [ "$OS" = "Linux" ]; then
    echo "==> Checking KVM"
    if [ -e /dev/kvm ]; then
      echo "KVM present: fast path."
    else
      echo "WARNING: no /dev/kvm -> QEMU software emulation, will be slow."
    fi
  fi

  echo "==> Starting colima (2 cpu / 2 GB)"
  colima start --cpu 2 --memory 2

  echo "==> Pointing docker CLI at colima"
  docker context use colima
}

start() {
  colima start
  docker context use colima >/dev/null
  docker compose -f "$ROOT/dockers/docker-compose.yml" up -d
  docker compose -f "$ROOT/dockers/docker-compose.yml" ps

  echo ""
  echo "Open:      http://localhost:8080"
  echo "Container: http://localhost:8080/api/ (whoami details)"
}

stop() {
  docker compose -f "$ROOT/dockers/docker-compose.yml" down
  colima stop
  echo "Stack down, VM stopped."
}

status() {
  colima status
  echo ""
  docker context show 2>/dev/null || true
  echo ""
  docker compose -f "$ROOT/dockers/docker-compose.yml" ps 2>/dev/null || true
}

dev() {
  local kitty ssh_mount
  if [ -z "${KITTY:-}" ]; then
    if command -v kitty >/dev/null 2>&1; then
      kitty="$(command -v kitty)"
    elif [ -x /home/veto/.local/kitty.app/bin/kitty ]; then
      kitty=/home/veto/.local/kitty.app/bin/kitty
    elif [ -x /Applications/kitty.app/Contents/MacOS/kitty ]; then
      kitty=/Applications/kitty.app/Contents/MacOS/kitty
    else
      echo "ERROR: kitty not found. Install it or run with KITTY=/path/to/kitty ./ask.sh 5" >&2
      return 1
    fi
  else
    kitty="$KITTY"
  fi
  echo "==> kitty: $kitty"

  colima start >/dev/null
  docker context use colima >/dev/null

  ssh_mount=()
  if [ -d "${HOME}/.ssh" ]; then
    for k in id_ed25519 id_rsa id_ecdsa id_dsa; do
      if [ -f "${HOME}/.ssh/$k" ]; then
        ssh_mount+=(-v "${HOME}/.ssh/$k:/root/.ssh/$k:ro")
      fi
    done
  fi

  "$kitty" docker run -it \
    -v "${ROOT}/site:/site" \
    "${ssh_mount[@]}" \
    myridia/opencode bash
}

menu() {
  printf "\n  colima-test — Task Runner\n\n"
  printf "  ┌─────┬──────────────────────────────────────────────┐\n"
  printf "  │  ID │ Description                                  │\n"
  printf "  ├─────┼──────────────────────────────────────────────┤\n"
  printf "  │  1  │ Setup — install colima + lima + kitty (once) │\n"
  printf "  │  2  │ Start — boot VM + bring up stack             │\n"
  printf "  │  3  │ Stop — stack down + stop VM                  │\n"
  printf "  │  4  │ Status — VM / docker context / stack         │\n"
  printf "  │  5  │ Dev — open opencode dev container            │\n"
  printf "  │  0  │ Exit                                         │\n"
  printf "  └─────┴──────────────────────────────────────────────┘\n\n"
}

run() {
  case "$1" in
    1) setup ;;
    2) start ;;
    3) stop ;;
    4) status ;;
    5) dev ;;
    0) return 0 ;;
    *) echo "Unknown task: $1" >&2; return 1 ;;
  esac
}

if [ "$#" -gt 0 ]; then
  run "$1"
  exit $?
fi

while true; do
  menu
  printf "  Enter Task ID: "
  read -r task
  [ -z "$task" ] && continue
  if [ "$task" = "0" ]; then
    echo "Goodbye!"
    break
  fi
  run "$task"
  echo ""
done