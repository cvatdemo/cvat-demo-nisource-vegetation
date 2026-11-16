#!/usr/bin/env bash
# Scores every job against the answer key and prints the result.
set -euo pipefail
source "$(dirname "$0")/common.sh"
[ -n "${DEMO_PASS:-}" ] || { echo "Run: bash scripts/setup.sh first."; exit 1; }
export CVAT_URL DEMO_USER DEMO_PASS
.venv/bin/python scripts/demo_tool.py report
