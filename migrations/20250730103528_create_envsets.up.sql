-- migrations/20250730103528_create_envsets.up.sql

-- Env Sets type enum
CREATE TYPE envset_type AS ENUM ('personal', 'team');

-- Env Sets (collection of environment variables)
CREATE TABLE envsets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    type envset_type NOT NULL,
    owner_user_id UUID REFERENCES users(id), -- For personal envsets
    owner_team_id UUID REFERENCES teams(id), -- For team envsets
    environment_id UUID REFERENCES environments(id), -- Which env this belongs to
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE,
    CHECK (
        (type = 'personal' AND owner_user_id IS NOT NULL AND owner_team_id IS NULL) OR
        (type = 'team' AND owner_team_id IS NOT NULL AND owner_user_id IS NULL)
        )
);

-- Indexes
CREATE INDEX idx_envsets_owner_user_id ON envsets(owner_user_id);
CREATE INDEX idx_envsets_owner_team_id ON envsets(owner_team_id);
CREATE INDEX idx_envsets_environment_id ON envsets(environment_id);
CREATE INDEX idx_envsets_type ON envsets(type);
CREATE INDEX idx_envsets_deleted_at ON envsets(deleted_at);

-- Trigger for updated_at
CREATE TRIGGER update_envsets_updated_at
    BEFORE UPDATE ON envsets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();