#!/usr/bin/env bash
# Throwaway PostgreSQL on loopback for test runs.
# Usage:
#   bash pg_ephemeral.sh up [NAME]   start, wait until ready, print NAME and the test URL
#   bash pg_ephemeral.sh down NAME   remove the container
# Never pass the names of containers you did not start.
set -euo pipefail

IMAGE="${PG_IMAGE:-timescale/timescaledb:latest-pg16}"

case "${1:-}" in
  up)
    NAME="${2:-qa-pg-$RANDOM}"
    PORT=$(python3 -c "import socket;s=socket.socket();s.bind(('127.0.0.1',0));print(s.getsockname()[1]);s.close()")
    docker run -d --name "$NAME" -e POSTGRES_USER=qa -e POSTGRES_PASSWORD=qa -e POSTGRES_DB=qa \
      -p "127.0.0.1:$PORT:5432" "$IMAGE" >/dev/null
    ok=0
    for _ in $(seq 1 90); do
      if docker exec "$NAME" psql -U qa -d qa -tAc "select 1" >/dev/null 2>&1; then
        ok=$((ok + 1))
        [ "$ok" -ge 3 ] && break
      else
        ok=0
      fi
      sleep 1
    done
    if [ "$ok" -lt 3 ]; then
      echo "database never became ready; removing $NAME" >&2
      docker rm -f "$NAME" >/dev/null || true
      exit 1
    fi
    echo "NAME=$NAME"
    echo "SUMMIT_PG_TEST_URL=postgresql+asyncpg://qa:qa@127.0.0.1:$PORT/qa"
    ;;
  down)
    [ -n "${2:-}" ] || { echo "usage: $0 down NAME" >&2; exit 2; }
    docker rm -f "$2" >/dev/null && echo "removed $2"
    ;;
  *)
    echo "usage: $0 up [NAME] | down NAME" >&2
    exit 2
    ;;
esac
