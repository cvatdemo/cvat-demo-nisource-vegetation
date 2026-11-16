# Shared settings for the demo scripts. Sourced, not run.
CVAT_TAG="v2.82.0"
CVAT_URL="${CVAT_URL:-http://localhost:8080}"
DEMO_USER="demo"
CREDS=".demo-credentials"   # written by setup.sh, read by the other scripts; local only
cd "$(dirname "${BASH_SOURCE[0]}")/.."
if [ -f "$CREDS" ]; then DEMO_PASS="$(cat "$CREDS")"; fi
# True inside Windows Subsystem for Linux.
is_wsl() { grep -qiE "microsoft|wsl" /proc/version 2>/dev/null; }
need() { command -v "$1" >/dev/null || { echo "Missing: $1. $2"; exit 1; }; }
