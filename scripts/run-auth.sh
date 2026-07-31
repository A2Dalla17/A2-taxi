#!/usr/bin/env bash
#
# AC7 Ride — run the auth service and record everything.
#
#   bash scripts/run-auth.sh
#
# Output goes to the terminal AND to logs/auth.log, so the log can be read
# and diagnosed without screenshots.
#

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$ROOT/logs"
LOG="$LOG_DIR/auth.log"

mkdir -p "$LOG_DIR"

{
  echo "=========================================================="
  echo " AC7 Ride — auth service"
  echo " $(date)"
  echo "=========================================================="
  echo

  echo "--- environment ---"
  echo "pwd     : $ROOT/backend"
  echo "go      : $(command -v go >/dev/null 2>&1 && go version || echo 'NOT INSTALLED')"
  echo

  if [ -f "$ROOT/backend/.env" ]; then
    echo "--- backend/.env (secrets masked) ---"
    sed -E 's/^(DB_PASSWORD|JWT_SECRET|STRIPE_API_KEY|TWILIO_AUTH_TOKEN|GOOGLE_MAPS_API_KEY)=.*/\1=<masked>/' \
      "$ROOT/backend/.env" | grep -vE '^\s*#|^$'
  else
    echo "!!! backend/.env NOT FOUND"
  fi
  echo

  echo "--- starting ./cmd/auth ---"
  echo
} > "$LOG" 2>&1

cat "$LOG"

if ! command -v go >/dev/null 2>&1; then
  echo "go is not installed. Install it with:" | tee -a "$LOG"
  echo "  sudo apt update && sudo apt install -y golang-go" | tee -a "$LOG"
  exit 1
fi

cd "$ROOT/backend"

# stdbuf keeps Go's output unbuffered so the log stays current even if the
# process hangs — which is exactly the case worth diagnosing.
if command -v stdbuf >/dev/null 2>&1; then
  stdbuf -oL -eL go run ./cmd/auth 2>&1 | tee -a "$LOG"
else
  go run ./cmd/auth 2>&1 | tee -a "$LOG"
fi

echo | tee -a "$LOG"
echo "--- process exited ---" | tee -a "$LOG"
echo "Log saved to: logs/auth.log" | tee -a "$LOG"
