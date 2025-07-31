-- migrations/20250730103523_create_environments.up.sql

-- Environments within projects (dev, staging, prod, etc.)
CREATE TABLE environments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL, -- dev, staging, prod, etc.
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(project_id, name) -- Environment name unique within project
);

-- Indexes
CREATE INDEX idx_environments_project_id ON environments(project_id);
CREATE INDEX idx_environments_name ON environments(name);

-- Trigger for updated_at
CREATE TRIGGER update_environments_updated_at
    BEFORE UPDATE ON environments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();