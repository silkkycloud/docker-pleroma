#!/usr/bin/env bash

set -euo pipefail

if [ ! -e "$PLEROMA_CONFIG_PATH" ] ; then
  gen-config.sh
fi

echo "-- Waiting for database..."
while ! pg_isready -U "${POSTGRES_USER:-pleroma}" -d "postgres://${POSTGRES_HOST:-postgres}:5432/${POSTGRES_DB:-pleroma}" -t 1; do
  echo "Waiting for ${POSTGRES_HOST:-postgres} to come up..." >&2
  sleep 1s
done

./bin/pleroma_ctl migrate

exec ./bin/pleroma start
