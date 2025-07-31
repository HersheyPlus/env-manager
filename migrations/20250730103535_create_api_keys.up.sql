-- migrations/20250730103535_create_api_keys.up.sql

-- API Key type enum
CREATE TYPE api_key_type AS ENUM ('user', 'team', 'service');

-- API Keys for authentication
CREATE TABLE api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    key_hash VARCHAR(255) UNIQUE NOT NULL, -- SHA-256 hash of the key
    key_prefix VARCHAR(20) NOT NULL, -- First few chars for identification
    type api_key_type NOT NULL,
    owner_user_id UUID REFERENCES users(id),
    owner_team_id UUID REFERENCES teams(id),
    permissions JSONB, -- Flexible permissions structure
    expires_at TIMESTAMP WITH TIME ZONE,
    last_used_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CHECK (
        (type = 'user' AND owner_user_id IS NOT NULL AND owner_team_id IS NULL) OR
        (type IN ('team', 'service') AND owner_team_id IS NOT NULL)
    )
);

-- Indexes
CREATE INDEX idx_api_keys_key_hash ON api_keys(key_hash);
CREATE INDEX idx_api_keys_key_prefix ON api_keys(key_prefix);
CREATE INDEX idx_api_keys_owner_user_id ON api_keys(owner_user_id);
CREATE INDEX idx_api_keys_owner_team_id ON api_keys(owner_team_id);
CREATE INDEX idx_api_keys_type ON api_keys(type);
CREATE INDEX idx_api_keys_is_active ON api_keys(is_active);
CREATE INDEX idx_api_keys_expires_at ON api_keys(expires_at);

-- Trigger for updated_at
CREATE TRIGGER update_api_keys_updated_at
    BEFORE UPDATE ON api_keys
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();