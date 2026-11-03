#!/usr/bin/env bash
# Table-driven API smoke test. Copy into the scratch dir, then edit the BASE and the cases.
# Each check prints PASS or FAIL with the actual status code. Exits non-zero on any FAIL.
# Never prints tokens. Use only synthetic identifiers.
set -u
BASE=${BASE:-http://127.0.0.1:8010/api/v1}
FAILS=0
BODY_FILE=$(mktemp)

# req METHOD PATH [JSON_BODY] [BEARER_TOKEN] -> sets CODE and BODY
req() {
  local m=$1 p=$2 d=${3:-} t=${4:-}
  local args=(-s -o "$BODY_FILE" -w '%{http_code}' -X "$m" "$BASE$p" -H 'Content-Type: application/json')
  [ -n "$t" ] && args+=(-H "Authorization: Bearer $t")
  [ -n "$d" ] && args+=(-d "$d")
  CODE=$(curl "${args[@]}")
  BODY=$(cat "$BODY_FILE" 2>/dev/null)
}

# expect LABEL EXPECTED_CODE METHOD PATH [JSON_BODY] [BEARER_TOKEN]
expect() {
  local label=$1 want=$2; shift 2
  req "$@"
  if [ "$CODE" = "$want" ]; then
    echo "PASS  $label  -> $CODE"
  else
    echo "FAIL  $label  -> got $CODE, want $want"
    FAILS=$((FAILS+1))
  fi
}

# json_field JSON KEY -> prints the value of a top-level key (for pulling tokens and ids)
json_field() { printf '%s' "$1" | python3 -c "import sys,json;print(json.load(sys.stdin)['$2'])"; }

# ---- cases: replace these with the service's real endpoints ----
expect 'unauthenticated read is denied' 401 GET /things/me

# Example sign-in flow (adapt the endpoints and field names from the repo's API schemas):
# req POST /auth/request '{"phone":"+15550100001"}'
# CH=$(json_field "$BODY" challenge_id)
# req POST /auth/verify "{\"challenge_id\":\"$CH\",\"phone\":\"+15550100001\",\"otp\":\"123456\"}"
# TA=$(json_field "$BODY" access_token)
# expect 'own profile readable' 200 GET /things/me '' "$TA"

rm -f "$BODY_FILE"
echo "---"
if [ "$FAILS" -eq 0 ]; then echo "ALL PASS"; else echo "$FAILS FAILED"; exit 1; fi
