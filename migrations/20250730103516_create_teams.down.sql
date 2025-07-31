-- migrations/20250730103516_create_teams.down.sql

DROP TRIGGER IF EXISTS update_teams_updated_at ON teams;
DROP TABLE IF EXISTS teams;