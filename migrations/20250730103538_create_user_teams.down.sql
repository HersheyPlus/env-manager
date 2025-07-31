-- migrations/20250730103538_create_user_teams.down.sql

DROP TRIGGER IF EXISTS update_user_teams_updated_at ON user_teams;
DROP TABLE IF EXISTS user_teams;
DROP TYPE IF EXISTS team_role;