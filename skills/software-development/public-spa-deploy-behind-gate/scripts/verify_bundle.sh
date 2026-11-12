#!/usr/bin/env bash
# Check a built static site before it is copied to the live folder.
#
# usage: verify_bundle.sh <dist-dir> [required-string ...]
#   Fails (exit 1) if any banned local address appears in the JS, or if any
#   required string (for example the production auth host and client id) is missing.
#   Override the banned list with BANNED_STRINGS="a b c".
# A match on a library fallback is not automatically a failure: read it first.
set -u

DIST="${1:?usage: verify_bundle.sh <dist-dir> [required ...]}"
shift

read -r -a BANNED <<< "${BANNED_STRINGS:-localhost:8080 127.0.0.1:8080 localhost:3000 aarvas-web}"

mapfile -t JSFILES < <(find "$DIST" -name '*.js' -type f)
if [ ${#JSFILES[@]} -eq 0 ]; then
  echo "no JS files under $DIST"
  exit 2
fi

status=0
for b in "${BANNED[@]}"; do
  hits=$(grep -l -F -- "$b" "${JSFILES[@]}" 2>/dev/null || true)
  if [ -n "$hits" ]; then
    echo "BANNED '$b' found in:"
    echo "$hits"
    status=1
  fi
done

for r in "$@"; do
  if ! grep -q -F -- "$r" "${JSFILES[@]}"; then
    echo "REQUIRED missing: $r"
    status=1
  fi
done

if [ $status -eq 0 ]; then
  echo "bundle ok: ${#JSFILES[@]} JS files checked"
fi
exit $status
