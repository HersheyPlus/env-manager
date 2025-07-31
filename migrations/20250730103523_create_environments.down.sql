-- migrations/20250730103523_create_environments.down.sql

DROP TRIGGER IF EXISTS update_environments_updated_at ON environments;
DROP TABLE IF EXISTS environments;