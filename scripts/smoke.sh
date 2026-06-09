#!/usr/bin/env bash
export LC_ALL=C
export LANG=C
set -euo pipefail

if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

DASHBOARD_URL="${DASHBOARD_URL:-http://localhost:${DASHBOARD_HOST_PORT:-15173}}"
GATEWAY_URL="${GATEWAY_URL:-http://localhost:${GATEWAY_HOST_PORT:-18080}}"
API_URL="${API_URL:-http://localhost:${API_HOST_PORT:-18000}}"
API_BASE_URL="${API_URL%/}/api/v1"
GATEWAY_API_BASE_URL="${GATEWAY_URL%/}/api/v1"
WAIT_SECONDS="${WAIT_SECONDS:-120}"
DEMO_USERNAME="${DEMO_USERNAME:-admin}"
DEMO_PASSWORD="${DEMO_PASSWORD:-password123}"
EXPECTED_SEED_VIN="${EXPECTED_SEED_VIN:-1FTFW1RG0PFA12345}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

log() {
  printf '[smoke] %s\n' "$*"
}

fail() {
  printf '[smoke] ERROR: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

wait_for_url() {
  name="$1"
  url="$2"
  deadline=$((SECONDS + WAIT_SECONDS))

  log "Waiting for ${name}: ${url}"
  while [ "$SECONDS" -lt "$deadline" ]; do
    if curl -fsS --max-time 5 "$url" >/dev/null 2>&1; then
      log "${name} is reachable"
      return 0
    fi
    sleep 2
  done

  fail "${name} did not become reachable within ${WAIT_SECONDS}s"
}

assert_json_field() {
  body="$1"
  expression="$2"
  message="$3"
  printf '%s' "$body" | ASSERT_EXPRESSION="$expression" ASSERT_MESSAGE="$message" \
    python3 -c "import json, os, sys; data = json.load(sys.stdin); assert eval(os.environ['ASSERT_EXPRESSION'], {'__builtins__': {}}, {'data': data}), os.environ['ASSERT_MESSAGE']"
}

assert_header() {
  headers_file="$1"
  header_name="$2"
  if ! grep -qi "^${header_name}:" "$headers_file"; then
    fail "Expected response header ${header_name}"
  fi
}

require_command curl
require_command grep
require_command python3

wait_for_url "dashboard" "$DASHBOARD_URL"
wait_for_url "telemetry API" "${API_BASE_URL}/health"
wait_for_url "gateway" "${GATEWAY_URL%/}/health"

log "Checking telemetry API health"
api_health="$(curl -fsS "${API_BASE_URL}/health")"
assert_json_field "$api_health" "data.get('status') == 'ok'" "telemetry API health status is not ok"

log "Checking gateway health"
gateway_health="$(curl -fsS "${GATEWAY_URL%/}/health")"
assert_json_field "$gateway_health" "data.get('status') == 'ok' and data.get('redis') == 'ok'" "gateway health or Redis status is not ok"

log "Checking unauthenticated protected route returns 401 with rate-limit headers"
unauth_headers="$TMP_DIR/unauth.headers"
unauth_body="$TMP_DIR/unauth.body"
unauth_status="$(
  curl -sS \
    -D "$unauth_headers" \
    -o "$unauth_body" \
    -w '%{http_code}' \
    "${GATEWAY_API_BASE_URL}/vehicles"
)"
[ "$unauth_status" = "401" ] || fail "Expected 401 for unauthenticated vehicles request, got ${unauth_status}"
assert_header "$unauth_headers" "X-RateLimit-Limit"
assert_header "$unauth_headers" "X-RateLimit-Remaining"
assert_header "$unauth_headers" "X-RateLimit-Reset"

log "Logging in through gateway"
login_payload="$(
  DEMO_USERNAME="$DEMO_USERNAME" DEMO_PASSWORD="$DEMO_PASSWORD" \
    python3 -c "import json, os; print(json.dumps({'username': os.environ['DEMO_USERNAME'], 'password': os.environ['DEMO_PASSWORD']}))"
)"
login_body="$(
  curl -fsS \
    -X POST "${GATEWAY_API_BASE_URL}/auth/login" \
    -H "Content-Type: application/json" \
    -d "$login_payload"
)"
token="$(
  printf '%s' "$login_body" | python3 -c "import json, sys; data = json.load(sys.stdin); token = data.get('access_token', ''); assert token, 'missing access_token'; print(token)"
)"

log "Fetching seeded vehicle through gateway"
vehicles_body="$(
  curl -fsS \
    "${GATEWAY_API_BASE_URL}/vehicles" \
    -H "Authorization: Bearer ${token}"
)"
printf '%s' "$vehicles_body" | EXPECTED_SEED_VIN="$EXPECTED_SEED_VIN" \
  python3 -c "import json, os, sys; vehicles = json.load(sys.stdin); vin = os.environ['EXPECTED_SEED_VIN']; assert isinstance(vehicles, list), 'vehicles response is not a list'; assert any(vehicle.get('vin') == vin for vehicle in vehicles), f'seed vehicle {vin} not found'"

log "Checking gateway metrics"
metrics_body="$(curl -fsS "${GATEWAY_URL%/}/metrics")"
printf '%s' "$metrics_body" | grep -q "gateway_requests_total" || fail "Expected gateway_requests_total metric"

log "Smoke checks passed"
