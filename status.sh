#!/bin/bash
set -euo pipefail

# Show colima VM + stack status.

colima status
echo ""
docker context show 2>/dev/null || true
echo ""
docker compose ps 2>/dev/null || true