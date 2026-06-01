#!/usr/bin/env bash
# Raw psql migration runner — zero migration-tool dependency.
# Applies migrations/NNN_*.sql in order, tracks applied versions in schema_migrations.
# Wraps each migration in a transaction.
#
# Usage:
#   DATABASE_URL=postgres://...  bash migrate.sh
#   DATABASE_URL=postgres://...  bash migrate.sh status
#
# Convention: migrations/NNNN_name.sql  (e.g. 0001_init.sql)

set -euo pipefail

MIGRATIONS_DIR="${MIGRATIONS_DIR:-migrations}"
CMD="${1:-up}"

[[ -z "${DATABASE_URL:-}" ]] && { echo "DATABASE_URL is not set" >&2; exit 1; }

# Ensure tracking table exists.
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -q -c "
  CREATE TABLE IF NOT EXISTS schema_migrations (
    version TEXT PRIMARY KEY,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
  );"

list_applied() {
  psql "$DATABASE_URL" -At -c "SELECT version FROM schema_migrations ORDER BY version;"
}

case "$CMD" in
  status)
    echo "Applied:"
    list_applied | sed 's/^/  /'
    echo "Pending:"
    for f in "$MIGRATIONS_DIR"/*.sql; do
      [[ -e "$f" ]] || continue
      v=$(basename "$f" .sql)
      list_applied | grep -qx "$v" || echo "  $v"
    done
    ;;
  up)
    APPLIED=$(list_applied)
    for f in "$MIGRATIONS_DIR"/*.sql; do
      [[ -e "$f" ]] || continue
      v=$(basename "$f" .sql)
      if echo "$APPLIED" | grep -qx "$v"; then
        continue
      fi
      echo ">>> applying $v"
      psql "$DATABASE_URL" -v ON_ERROR_STOP=1 --single-transaction <<SQL
BEGIN;
$(cat "$f")
INSERT INTO schema_migrations (version) VALUES ('$v');
COMMIT;
SQL
    done
    echo "OK"
    ;;
  *)
    echo "Usage: $0 [up|status]" >&2
    exit 2
    ;;
esac
