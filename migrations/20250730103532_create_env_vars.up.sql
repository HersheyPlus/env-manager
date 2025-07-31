-- migrations/20250730103532_create_env_vars.up.sql

-- Environment Variables (encrypted values)
CREATE TABLE env_variables (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    envset_id UUID NOT NULL REFERENCES envsets(id) ON DELETE CASCADE,
    key VARCHAR(255) NOT NULL,
    encrypted_value TEXT NOT NULL, -- AES-256 encrypted
    description TEXT,
    is_sensitive BOOLEAN DEFAULT true, -- Flag for sensitive data
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(envset_id, key) -- Key unique within envset
);

-- Indexes
CREATE INDEX idx_env_variables_envset_id ON env_variables(envset_id);
CREATE INDEX idx_env_variables_key ON env_variables(key);
CREATE INDEX idx_env_variables_is_sensitive ON env_variables(is_sensitive);

-- Trigger for updated_at
CREATE TRIGGER update_env_variables_updated_at
    BEFORE UPDATE ON env_variables
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();