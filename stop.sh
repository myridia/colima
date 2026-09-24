#!/bin/bash
set -euo pipefail

# Tear down: remove stack, stop the colima VM.

docker compose down
colima stop
echo "Stack down, VM stopped."