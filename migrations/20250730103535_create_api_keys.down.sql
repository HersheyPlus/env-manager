-- migrations/20250730103535_create_api_keys.down.sql

DROP TRIGGER IF EXISTS update_api_keys_updated_at ON api_keys;
DROP TABLE IF EXISTS api_keys;
DROP TYPE IF EXISTS api_key_type;