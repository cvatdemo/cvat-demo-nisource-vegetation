#!/usr/bin/env bash
# Starts open-source CVAT v2.82.0 on this machine and creates a local demo user. Safe to re-run.
set -euo pipefail
source "$(dirname "$0")/common.sh"

need docker "Install Docker Desktop: https://docs.docker.com/get-docker/"
need git "https://git-scm.com (on Ubuntu or WSL: sudo apt install git)"
need curl "On Ubuntu or WSL: sudo apt install curl"
docker compose version >/dev/null || { echo "Docker Compose v2 is required."; exit 1; }
if ! docker info >/dev/null 2>&1; then
  echo "Docker is installed but not running. Start Docker Desktop and run this again."
  if is_wsl; then
    echo "On Windows: in Docker Desktop, open Settings > Resources > WSL integration and turn it on for this distribution."
  fi
  exit 1
fi
if is_wsl && [[ "$PWD" == /mnt/* ]]; then
  echo "Note: this folder is on the Windows drive ($PWD). It works, but it is slow. For best results, move it into your WSL home folder (for example ~/cvat-demo)."
fi
# Python 3.10 or newer for the command-line tools; uv can supply one if the system Python is older.
PY=""
for cand in python3.13 python3.12 python3.11 python3.10 python3; do
  if command -v "$cand" >/dev/null && "$cand" -c 'import sys; sys.exit(sys.version_info < (3, 10))'; then PY="$cand"; break; fi
done
if [ -z "$PY" ] && ! command -v uv >/dev/null; then
  echo "Python 3.10 or newer is required (found: $(python3 --version 2>&1 || echo none))."
  echo "Install it from https://www.python.org/downloads/ or install uv (https://docs.astral.sh/uv/), then run this again."
  exit 1
fi

# Command-line tools for restore, reports and auto-annotation. Done first, so a missing Python
# piece is reported before anything large is downloaded.
if [ -n "$PY" ]; then
  if [ ! -x .venv/bin/pip ]; then
    rm -rf .venv
    if ! "$PY" -m venv .venv 2>/dev/null || [ ! -x .venv/bin/pip ]; then
      rm -rf .venv
      echo "Python could not create a virtual environment (the venv module is missing)."
      echo "On Ubuntu, Debian or WSL run:  sudo apt install python3-venv   then run this again."
      echo "Or install uv (https://docs.astral.sh/uv/), which brings its own Python."
      exit 1
    fi
  fi
  .venv/bin/pip install -q --upgrade pip
else
  [ -d .venv ] || uv venv --seed --python 3.12 .venv
fi
.venv/bin/pip install -q "cvat-cli==2.82.0" "cvat-sdk==2.82.0" requests

# 1. CVAT at the pinned version
if [ ! -d docker/cvat/.git ]; then
  git clone --depth 1 --branch "$CVAT_TAG" https://github.com/cvat-ai/cvat.git docker/cvat
fi
COMPOSE=(docker compose -f docker-compose.yml)
if [ "$(uname -m)" = "arm64" ] || [ "$(uname -m)" = "aarch64" ]; then
  echo "Apple Silicon or ARM machine: running CVAT's Intel images under emulation."
  COMPOSE+=(-f ../apple-silicon.override.yml)
fi
( cd docker/cvat && CVAT_VERSION="$CVAT_TAG" "${COMPOSE[@]}" up -d )

# 2. Wait until the server answers (first start downloads images and can take several minutes)
echo "Waiting for CVAT at $CVAT_URL ..."
for i in $(seq 1 120); do
  if curl -sf "$CVAT_URL/api/server/about" >/dev/null; then break; fi
  [ "$i" = 120 ] && { echo "CVAT did not start. See: docker logs cvat_server"; exit 1; }
  sleep 5
done

# 3. A local demo user with a random password (kept in $CREDS, never sent anywhere)
if [ ! -f "$CREDS" ]; then
  ( umask 077; LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 20 > "$CREDS" ) || true
  [ -s "$CREDS" ] || { echo "Could not create a password."; exit 1; }
fi
DEMO_PASS="$(cat "$CREDS")"
docker exec -e DJANGO_SUPERUSER_PASSWORD="$DEMO_PASS" cvat_server \
  python3 manage.py createsuperuser --noinput --username "$DEMO_USER" --email demo@example.com 2>/dev/null \
  || echo "User $DEMO_USER already exists."

# 4. The server answers before its permission service has loaded its rules; until then signed-in
#    requests fail with "Server Error (500)". Wait for a signed-in request to work.
for i in $(seq 1 60); do
  code="$(curl -s -o /dev/null -w '%{http_code}' -u "$DEMO_USER:$DEMO_PASS" "$CVAT_URL/api/projects?page_size=1" || true)"
  [ "$code" = 200 ] && break
  [ "$i" = 60 ] && { echo "CVAT started but does not accept requests yet (HTTP $code). Wait a minute and run this again."; exit 1; }
  sleep 5
done

echo
echo "CVAT is running: $CVAT_URL"
echo "Sign in as: $DEMO_USER   password: in the file $CREDS"
echo "Next: bash scripts/restore.sh"
