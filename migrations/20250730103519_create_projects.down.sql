-- migrations/20250730103519_create_projects.down.sql

DROP TRIGGER IF EXISTS update_projects_updated_at ON projects;
DROP TABLE IF EXISTS projects;