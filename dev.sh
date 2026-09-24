#!/bin/bash
set -euo pipefail

# Open the myridia/opencode dev container (with the project's site/ mounted)
# in a new kitty window, on the colima docker engine. Usage: ./dev.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "${KITTY:-}" ]; then
  if command -v kitty >/dev/null 2>&1; then
    KITTY="$(command -v kitty)"
  elif [ -x /home/veto/.local/kitty.app/bin/kitty ]; then
    KITTY=/home/veto/.local/kitty.app/bin/kitty
  elif [ -x /Applications/kitty.app/Contents/MacOS/kitty ]; then
    KITTY=/Applications/kitty.app/Contents/MacOS/kitty
  else
    echo "ERROR: kitty not found. Install it or run with KITTY=/path/to/kitty ./dev.sh" >&2
    exit 1
  fi
fi
echo "==> kitty: $KITTY"

colima start >/dev/null
docker context use colima >/dev/null

SSH_MOUNTS=()
if [ -d "${HOME}/.ssh" ]; then
  for k in id_ed25519 id_rsa id_ecdsa id_dsa; do
    if [ -f "${HOME}/.ssh/$k" ]; then
      SSH_MOUNTS+=(-v "${HOME}/.ssh/$k:/root/.ssh/$k:ro")
    fi
  done
fi

exec "$KITTY" docker run -it \
  -v "${SCRIPT_DIR}/site:/site" \
  ${SSH_MOUNTS[@]+"${SSH_MOUNTS[@]}"} \
  myridia/opencode bash