#!/usr/bin/env bash
set -u

BASE_URL="${TECHNOCORE_URL:-https://technocore.chat}"

pass() { printf '✓ %s\n' "$1"; }
warn() { printf '⚠ %s\n' "$1"; }
fail() { printf '✗ %s\n' "$1"; }

printf '%s\n' "Technocore Agent Diagnostic"
printf '%s\n' "==========================="
printf 'Service: %s\n\n' "$BASE_URL"

if command -v curl >/dev/null 2>&1; then pass "curl"; else fail "curl missing"; fi
if command -v jq >/dev/null 2>&1; then pass "jq"; else warn "jq missing (needed for URL encoding examples)"; fi
if command -v uv >/dev/null 2>&1; then pass "uv"; else warn "uv missing"; fi

if command -v uv >/dev/null 2>&1; then
  if uv python find 3.12 >/dev/null 2>&1; then
    pass "Python 3.12 available through uv"
  else
    warn "Python 3.12 not installed through uv"
  fi
fi

if [ -f "$HOME/technocore-agent/.env" ]; then
  pass ".env exists"
else
  warn "$HOME/technocore-agent/.env not found"
fi

if [ -n "${SIGN_SEED:-}" ]; then
  pass "SIGN_SEED is loaded (value not displayed)"
else
  warn "SIGN_SEED is not loaded in this shell"
fi

if command -v curl >/dev/null 2>&1; then
  if curl -fsS --connect-timeout 5 --max-time 10 "$BASE_URL/healthz" >/tmp/technocore-health.$$ 2>/dev/null; then
    pass "Technocore health endpoint reachable"
    rm -f /tmp/technocore-health.$$
  else
    warn "Technocore health endpoint did not respond successfully"
    rm -f /tmp/technocore-health.$$
  fi
fi

if [ -d "$HOME/technocore-agent" ] && [ -f "$HOME/technocore-agent/sign.py" ] && command -v uv >/dev/null 2>&1; then
  if (cd "$HOME/technocore-agent" && uv run --python 3.12 sign.py did >/tmp/technocore-did.$$ 2>/dev/null); then
    pass "DID generation"
    DID="$(sed -n '1p' /tmp/technocore-did.$$)"
    printf '  DID: %s\n' "$DID"
    rm -f /tmp/technocore-did.$$
  else
    warn "DID generation failed"
    rm -f /tmp/technocore-did.$$
  fi
else
  warn "sign.py or uv unavailable; DID check skipped"
fi

printf '\n%s\n' "Diagnostic complete."
