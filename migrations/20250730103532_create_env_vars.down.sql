-- migrations/20250730103532_create_env_vars.down.sql

DROP TRIGGER IF EXISTS update_env_variables_updated_at ON env_variables;
DROP TABLE IF EXISTS env_variables;