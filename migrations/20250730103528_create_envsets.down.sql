-- migrations/20250730103528_create_envsets.down.sql

DROP TRIGGER IF EXISTS update_envsets_updated_at ON envsets;
DROP TABLE IF EXISTS envsets;
DROP TYPE IF EXISTS envset_type;