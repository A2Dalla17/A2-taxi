#!/usr/bin/env bash
#
# AC7 Ride — start the development stack (WSL / Linux / macOS)
#
#   ./scripts/start-dev.sh                 backend + frontend
#   ./scripts/start-dev.sh --frontend-only just the UI
#   ./scripts/start-dev.sh --local-db      local Postgres instead of Supabase
#   ./scripts/start-dev.sh --all-services  all 17 services (see the warning)
#

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

FRONTEND_ONLY=0
LOCAL_DB=0
ALL_SERVICES=0

for arg in "$@"; do
  case "$arg" in
    --frontend-only) FRONTEND_ONLY=1 ;;
    --local-db)      LOCAL_DB=1 ;;
    --all-services)  ALL_SERVICES=1 ;;
    -h|--help)       sed -n '3,10p' "$0"; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

C_RESET=$'\033[0m'; C_CYAN=$'\033[36m'; C_GREEN=$'\033[32m'
C_YELLOW=$'\033[33m'; C_RED=$'\033[31m'; C_DIM=$'\033[2m'

step() { printf '\n%s[%s] %s%s\n' "$C_CYAN" "$1" "$2" "$C_RESET"; }
ok()   { printf '    %sOK%s  %s\n' "$C_GREEN" "$C_RESET" "$1"; }
warn() { printf '    %s!%s   %s\n' "$C_YELLOW" "$C_RESET" "$1"; }
err()  { printf '    %sX%s   %s\n' "$C_RED" "$C_RESET" "$1"; }

printf '\n  AC7 Ride — development stack\n'
printf '  %s%s%s\n' "$C_DIM" "$ROOT" "$C_RESET"

# ---------------------------------------------------------------------------
# 1. Prerequisites
# ---------------------------------------------------------------------------
step 1 'Checking prerequisites'

if ! command -v node >/dev/null 2>&1; then
  err 'Node.js not found.'
  echo '    Install it inside WSL:'
  echo '      curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -'
  echo '      sudo apt install -y nodejs'
  exit 1
fi
ok "Node $(node --version)"

if [ "$FRONTEND_ONLY" -eq 0 ]; then
  if ! command -v docker >/dev/null 2>&1; then
    err 'docker not found in WSL.'
    echo '    Docker Desktop -> Settings -> Resources -> WSL Integration,'
    echo '    enable your distro, then restart the terminal.'
    echo '    Or run with --frontend-only.'
    exit 1
  fi

  if ! docker info >/dev/null 2>&1; then
    err 'Docker is installed but not responding.'
    echo '    Start Docker Desktop on Windows and wait for it to finish loading.'
    exit 1
  fi
  ok 'Docker is running'
fi

# ---------------------------------------------------------------------------
# 2. Configuration
# ---------------------------------------------------------------------------
if [ "$FRONTEND_ONLY" -eq 0 ] && [ "$LOCAL_DB" -eq 0 ]; then
  step 2 'Checking Supabase configuration'

  ENV_FILE="$ROOT/backend/.env"

  if [ ! -f "$ENV_FILE" ]; then
    err 'backend/.env is missing.'
    echo '      cd backend && cp .env.supabase.example .env'
    echo '    Then fill in DB_PASSWORD and JWT_SECRET.'
    exit 1
  fi

  if ! grep -qE '^DB_PASSWORD=.+$' "$ENV_FILE"; then
    err 'DB_PASSWORD is empty in backend/.env'
    echo '    Supabase dashboard -> Settings -> Database'
    exit 1
  fi
  ok 'DB_PASSWORD is set'

  if ! grep -qE '^JWT_SECRET=.+$' "$ENV_FILE"; then
    err 'JWT_SECRET is empty in backend/.env'
    echo '    Generate one:  openssl rand -base64 48'
    exit 1
  fi
  ok 'JWT_SECRET is set'
fi

# ---------------------------------------------------------------------------
# 3. Backend
# ---------------------------------------------------------------------------
if [ "$FRONTEND_ONLY" -eq 0 ]; then
  step 3 'Starting backend'

  # --env-file is required: compose reads .env from the project directory,
  # not from backend/. Without it the ${DB_USER:?} interpolation fails.
  COMPOSE=(docker compose)
  [ -f backend/.env ] && COMPOSE+=(--env-file backend/.env)
  COMPOSE+=(-f deploy/docker-compose.yml)

  if [ "$LOCAL_DB" -eq 0 ]; then
    COMPOSE+=(-f deploy/docker-compose.supabase.yml)
    printf '    %sDatabase: Supabase%s\n' "$C_DIM" "$C_RESET"
  else
    printf '    %sDatabase: local Postgres container%s\n' "$C_DIM" "$C_RESET"
  fi

  SERVICES=()
  if [ "$ALL_SERVICES" -eq 0 ]; then
    # Enough for auth, booking and tracking. The other ten services multiply
    # connection use against a 60-connection free tier for no benefit in dev.
    SERVICES=(redis nats kong auth-service rides-service geo-service payments-service)
    [ "$LOCAL_DB" -eq 1 ] && SERVICES+=(postgres)
  fi

  cd "$ROOT"
  if ! "${COMPOSE[@]}" up -d "${SERVICES[@]}"; then
    err 'docker compose failed'
    exit 1
  fi
  ok 'Containers started'

  printf '    %sWaiting for the gateway…%s\n' "$C_DIM" "$C_RESET"
  READY=0
  for _ in $(seq 1 30); do
    sleep 2
    if curl -fsS --max-time 3 http://localhost:8000/api/v1/auth/healthz >/dev/null 2>&1; then
      READY=1
      break
    fi
  done

  if [ "$READY" -eq 1 ]; then
    ok 'Gateway is responding on http://localhost:8000'
  else
    warn 'Gateway did not respond within 60s.'
    echo "    Logs:  docker compose -f deploy/docker-compose.yml logs auth-service"
    echo '    Continuing — the frontend will still start.'
  fi
fi

# ---------------------------------------------------------------------------
# 4. Frontend
# ---------------------------------------------------------------------------
step 4 'Starting frontend'

cd "$ROOT/frontend"

if [ ! -d node_modules ]; then
  printf '    %sInstalling dependencies…%s\n' "$C_DIM" "$C_RESET"
  warn 'This project lives on the Windows filesystem (/mnt/c).'
  echo '    npm install across the WSL/Windows boundary is slow — expect'
  echo '    several minutes. It only happens once.'
  npm install
  ok 'Dependencies installed'
else
  ok 'Dependencies already present'
fi

cat <<EOF

  ────────────────────────────────────────────────
   App:      http://localhost:3000
$( [ "$FRONTEND_ONLY" -eq 0 ] && echo "   API:      http://localhost:8000" )

   ${C_YELLOW}Use the LOCAL address above.${C_RESET}
   ${C_DIM}Vite also prints two "Network:" addresses (10.255.255.254 and
   172.x.x.x). Those belong to the WSL virtual adapter — Chrome on
   Windows cannot route to them and you will get a timeout.${C_RESET}
  ────────────────────────────────────────────────

EOF

# Open the Windows browser from inside WSL, if the helper is available.
if command -v wslview >/dev/null 2>&1; then
  wslview http://localhost:3000 >/dev/null 2>&1 || true
elif command -v explorer.exe >/dev/null 2>&1; then
  explorer.exe 'http://localhost:3000' >/dev/null 2>&1 || true
fi

npm run dev
