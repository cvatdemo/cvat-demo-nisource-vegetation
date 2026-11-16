#!/usr/bin/env bash
# One command: starts CVAT, loads the demo project, prints the scores and opens the browser.
# Usage: bash start.sh      Safe to run again. To stop: bash scripts/stop.sh
set -euo pipefail
cd "$(dirname "$0")"

echo "Step 1 of 3: starting CVAT (the first run downloads it and can take 10 minutes or more)"
bash scripts/setup.sh
echo
echo "Step 2 of 3: loading the demo project"
bash scripts/restore.sh
echo
echo "Step 3 of 3: scoring the work against the answer key"
bash scripts/quality_report.sh

PROJECT_URL="$(grep '^project=' demo/local-urls.txt | cut -d= -f2-)"
echo
echo "------------------------------------------------------------"
echo "CVAT is ready:  $PROJECT_URL"
echo "Sign in as:     demo"
echo "Password:       $(cat .demo-credentials)"
echo "Next:           open START-HERE.html and follow 'What to try'"
echo "To stop CVAT:   bash scripts/stop.sh"
echo "------------------------------------------------------------"
# Open the browser where we can: macOS, Windows (from WSL), or a Linux desktop.
if command -v open >/dev/null && [ "$(uname -s)" = "Darwin" ]; then open "$PROJECT_URL" || true
elif command -v wslview >/dev/null; then wslview "$PROJECT_URL" || true
elif command -v explorer.exe >/dev/null; then explorer.exe "$PROJECT_URL" || true
elif command -v xdg-open >/dev/null; then xdg-open "$PROJECT_URL" >/dev/null 2>&1 || true
fi
