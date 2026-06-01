-- 0000_init_schema_migrations_table.sql
-- Optional explicit migration that creates the tracking table.
-- migrate.sh creates it automatically, so this file is mostly documentation —
-- include it if you want every step (including the table itself) versioned.

CREATE TABLE IF NOT EXISTS schema_migrations (
  version    TEXT PRIMARY KEY,
  applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
