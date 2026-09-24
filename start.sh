#!/bin/bash
set -euo pipefail

# One-click start: boot the colima VM, bring up the stack.

colima start
docker context use colima >/dev/null
docker compose up -d
docker compose ps

echo ""
echo "Open:      http://localhost:8080"
echo "Container: http://localhost:8080/api/ (whoami details)"