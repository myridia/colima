#!/bin/bash
set -euo pipefail

# One-time setup for Colima: docker-compatible runtime via a Lima VM,
# no desktop app. Works on Linux (apt) and macOS (brew).
# After this, ./start.sh is the one-click entry.

OS="$(uname -s)"
ARCH="$(uname -m)"
case "$OS" in
  Linux)  REL_OS="Linux" ;;
  Darwin) REL_OS="Darwin" ;;
  *) echo "ERROR: unsupported OS: ${OS}" >&2; exit 1 ;;
esac
case "$ARCH" in
  x86_64|amd64)            REL_ARCH="x86_64" ;;
  aarch64|arm64)           REL_ARCH="aarch64" ;;
  *) echo "ERROR: unsupported arch: ${ARCH}" >&2; exit 1 ;;
esac

echo "==> Detected: ${OS} (${ARCH})"

if [ "$OS" = "Darwin" ]; then
  echo "==> Checking Homebrew"
  if ! command -v brew >/dev/null 2>&1; then
    echo "ERROR: Homebrew not found. Install it first: https://brew.sh" >&2
    exit 1
  fi

  echo "==> Installing colima + docker CLI (brew)"
  brew install colima docker docker-compose
elif [ "$OS" = "Linux" ]; then
  echo "==> Installing qemu + docker CLI (apt)"
  sudo apt-get update
  sudo apt-get install -y docker.io docker-compose qemu-system-x86 qemu-utils

  LATEST_JSON="$(mktemp)"
  trap 'rm -f "$LATEST_JSON"' EXIT
  curl -fsSL -o "$LATEST_JSON" https://api.github.com/repos/abiosoft/colima/releases/latest
  LATEST="$(grep -m1 '"tag_name"' "$LATEST_JSON" | cut -d'"' -f4)"
  COLI_VERSION="${LATEST#v}"

  echo "==> Installing colima ${COLI_VERSION} (${REL_ARCH})"
  DEST="$(cd "$(dirname "$0")" && pwd)/colima.bin"
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
      exit 1
    fi
  fi
  mv "$DEST.part" "$DEST"
  sudo install -m 0755 "$DEST" /usr/local/bin/colima
else
  echo "ERROR: unsupported OS: ${OS}" >&2
  exit 1
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

echo "==> Done. Run ./start.sh to bring up the stack."