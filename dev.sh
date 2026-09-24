#!/bin/bash
set -euo pipefail

# Open the myridia/opencode dev container (with the project's site/ mounted)
# in a new kitty window, on the colima docker engine. Usage: ./dev.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KITTY="${KITTY:-/home/veto/.local/kitty.app/bin/kitty}"

colima start >/dev/null
docker context use colima >/dev/null

exec "$KITTY" docker run -it \
  -v "${SCRIPT_DIR}/site:/site" \
  myridia/opencode bash