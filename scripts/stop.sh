#!/usr/bin/env bash
# Stops CVAT. Your data is kept. Add --delete to remove CVAT's data volumes as well.
set -euo pipefail
source "$(dirname "$0")/common.sh"
COMPOSE=(docker compose -f docker-compose.yml)
if [ "$(uname -m)" = "arm64" ] || [ "$(uname -m)" = "aarch64" ]; then COMPOSE+=(-f ../apple-silicon.override.yml); fi
if [ "${1:-}" = "--delete" ]; then ( cd docker/cvat && "${COMPOSE[@]}" down -v ); else ( cd docker/cvat && "${COMPOSE[@]}" down ); fi
