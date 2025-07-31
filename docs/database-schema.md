# Database Schema Documentation

## Overview

The env-manager database is designed as a multi-tenant system for managing environment variables with enterprise-grade security and access control. The schema supports personal and team-based environment variable management across multiple projects and environments.

## Table of Contents

- [Core Tables](#core-tables)
- [Relationships](#relationships)
- [Security Model](#security-model)
- [Usage Examples](#usage-examples)
- [Migration Guide](#migration-guide)

---

## Core Tables

### 1. users
**Purpose:** Base user management and authentication

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| email | VARCHAR(255) | Unique email address |
| username | VARCHAR(100) | Unique username |
| password_hash | VARCHAR(255) | Bcrypt hashed password |
| first_name | VARCHAR(100) | User's first name |
| last_name | VARCHAR(100) | User's last name |
| is_active | BOOLEAN | Account status |
| created_at | TIMESTAMPTZ | Creation timestamp |
| updated_at | TIMESTAMPTZ | Last update timestamp |
| deleted_at | TIMESTAMPTZ | Soft delete timestamp |

**Example:**
```sql
INSERT INTO users (email, username, password_hash, first_name, last_name)
VALUES ('john@company.com', 'john_dev', '$2a$10$...', 'John', 'Doe');
```

### 2. teams
**Purpose:** Group users for shared environment variable management

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| name | VARCHAR(100) | Unique team name |
| description | TEXT | Team description |
| created_by_user_id | UUID | FK to users table |
| is_active | BOOLEAN | Team status |
| created_at | TIMESTAMPTZ | Creation timestamp |
| updated_at | TIMESTAMPTZ | Last update timestamp |
| deleted_at | TIMESTAMPTZ | Soft delete timestamp |

**Example:**
```sql
INSERT INTO teams (name, description, created_by_user_id)
VALUES ('Backend Team', 'Development team for backend services', 'user-uuid');
```

### 3. user_teams
**Purpose:** Many-to-many relationship between users and teams with role-based access

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | FK to users table |
| team_id | UUID | FK to teams table |
| role | team_role | User's role in the team |
| created_at | TIMESTAMPTZ | Creation timestamp |
| updated_at | TIMESTAMPTZ | Last update timestamp |

**Roles:**
- `owner` - Team owner (can delete team)
- `admin` - Team administrator (manage members, envsets)
- `member` - Team member (read/write envsets)
- `viewer` - Read-only access

**Example:**
```sql
INSERT INTO user_teams (user_id, team_id, role)
VALUES ('user-uuid', 'team-uuid', 'admin');
```

### 4. projects
**Purpose:** Organize environments under logical project boundaries

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| name | VARCHAR(100) | Project name (unique within team) |
| description | TEXT | Project description |
| team_id | UUID | FK to teams table (nullable for personal projects) |
| created_by_user_id | UUID | FK to users table |
| is_active | BOOLEAN | Project status |
| created_at | TIMESTAMPTZ | Creation timestamp |
| updated_at | TIMESTAMPTZ | Last update timestamp |
| deleted_at | TIMESTAMPTZ | Soft delete timestamp |

**Example:**
```sql
INSERT INTO projects (name, description, team_id, created_by_user_id)
VALUES ('E-commerce API', 'Main API for e-commerce platform', 'team-uuid', 'user-uuid');
```

### 5. environments
**Purpose:** Define deployment environments within projects (dev, staging, prod)

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| project_id | UUID | FK to projects table |
| name | VARCHAR(50) | Environment name (dev, staging, prod) |
| description | TEXT | Environment description |
| is_active | BOOLEAN | Environment status |
| created_at | TIMESTAMPTZ | Creation timestamp |
| updated_at | TIMESTAMPTZ | Last update timestamp |

**Example:**
```sql
INSERT INTO environments (project_id, name, description)
VALUES 
  ('project-uuid', 'development', 'Development environment'),
  ('project-uuid', 'staging', 'Staging environment for testing'),
  ('project-uuid', 'production', 'Production environment');
```

### 6. envsets
**Purpose:** Collections of environment variables (personal or team-based)

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| name | VARCHAR(100) | Envset name |
| description | TEXT | Envset description |
| type | envset_type | 'personal' or 'team' |
| owner_user_id | UUID | FK to users (for personal envsets) |
| owner_team_id | UUID | FK to teams (for team envsets) |
| environment_id | UUID | FK to environments |
| is_active | BOOLEAN | Envset status |
| created_at | TIMESTAMPTZ | Creation timestamp |
| updated_at | TIMESTAMPTZ | Last update timestamp |
| deleted_at | TIMESTAMPTZ | Soft delete timestamp |

**Constraints:**
- Personal envsets must have owner_user_id (owner_team_id = NULL)
- Team envsets must have owner_team_id (owner_user_id = NULL)

**Example:**
```sql
-- Team envset
INSERT INTO envsets (name, type, owner_team_id, environment_id)
VALUES ('Backend Team - Production DB', 'team', 'team-uuid', 'prod-env-uuid');

-- Personal envset
INSERT INTO envsets (name, type, owner_user_id, environment_id)
VALUES ('John''s Local Dev Setup', 'personal', 'user-uuid', 'dev-env-uuid');
```

### 7. env_variables
**Purpose:** Store encrypted key-value pairs for environment variables

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| envset_id | UUID | FK to envsets table |
| key | VARCHAR(255) | Variable name (unique within envset) |
| encrypted_value | TEXT | AES-256 encrypted value |
| description | TEXT | Variable description |
| is_sensitive | BOOLEAN | Sensitivity flag |
| created_at | TIMESTAMPTZ | Creation timestamp |
| updated_at | TIMESTAMPTZ | Last update timestamp |

**Example:**
```sql
INSERT INTO env_variables (envset_id, key, encrypted_value, is_sensitive)
VALUES 
  ('envset-uuid', 'DB_HOST', 'encrypted:AES256:abc123...', true),
  ('envset-uuid', 'DB_PORT', 'encrypted:AES256:def456...', false),
  ('envset-uuid', 'DB_PASSWORD', 'encrypted:AES256:xyz789...', true);
```

### 8. api_keys
**Purpose:** Authentication tokens with granular permissions

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| name | VARCHAR(100) | Human-readable key name |
| key_hash | VARCHAR(255) | SHA-256 hash of the key |
| key_prefix | VARCHAR(20) | Key prefix for identification |
| type | api_key_type | 'user', 'team', or 'service' |
| owner_user_id | UUID | FK to users (for user keys) |
| owner_team_id | UUID | FK to teams (for team/service keys) |
| permissions | JSONB | Granular permissions object |
| expires_at | TIMESTAMPTZ | Expiration timestamp |
| last_used_at | TIMESTAMPTZ | Last usage timestamp |
| is_active | BOOLEAN | Key status |
| created_at | TIMESTAMPTZ | Creation timestamp |
| updated_at | TIMESTAMPTZ | Last update timestamp |

**Example:**
```sql
INSERT INTO api_keys (name, key_hash, key_prefix, type, owner_user_id, permissions)
VALUES (
  'John''s CLI Key',
  'sha256:abcd1234...',
  'em_dev_sk_live',
  'user',
  'user-uuid',
  '{"envsets": ["read", "write"], "projects": ["read"], "audit": ["read"]}'::jsonb
);
```

### 9. audit_logs
**Purpose:** Audit trail for compliance and security monitoring

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| user_id | UUID | FK to users table |
| api_key_id | UUID | FK to api_keys table |
| action | VARCHAR(50) | Action performed (CREATE, UPDATE, DELETE, READ, LOGIN, LOGOUT) |
| resource_type | VARCHAR(50) | Type of resource (user, team, project, environment, envset, env_variable, api_key) |
| resource_id | UUID | ID of the affected resource |
| old_values | JSONB | Previous values (redacted for sensitive data) |
| new_values | JSONB | New values (redacted for sensitive data) |
| ip_address | INET | Client IP address |
| user_agent | TEXT | Client user agent |
| session_id | VARCHAR(255) | For tracking user sessions |
| request_id | VARCHAR(255) | For correlating related operations |
| created_at | TIMESTAMPTZ | Timestamp of action |

---

## Relationships

### Entity Relationship Diagram

```
User ──┬── creates ──→ Team
       ├── joins ────→ User_Teams ←── belongs to ── Team
       ├── creates ──→ Project ←── belongs to ──── Team
       ├── owns ─────→ API_Key
       └── owns ─────→ Envset (personal)

Team ──┬── owns ─────→ API_Key  
       ├── owns ─────→ Envset (team)
       └── contains ─→ Project

Project ─── contains ──→ Environment

Environment ─── contains ──→ Envset

Envset ─── contains ──→ Env_Variables

All_Operations ─── logged_to ──→ Audit_Logs
```

### Key Relationships

1. **User ↔ Team** (Many-to-Many)
   - Via `user_teams` with role-based access
   - Supports multiple users per team and multiple teams per user

2. **Team → Project** (One-to-Many)
   - Teams can have multiple projects
   - Projects can also be personal (team_id = NULL)

3. **Project → Environment** (One-to-Many)
   - Each project has multiple environments (dev, staging, prod)
   - Environment names are unique within a project

4. **Environment → Envset** (One-to-Many)
   - Each environment can have multiple envsets
   - Envsets can be personal or team-owned

5. **Envset → Env_Variables** (One-to-Many)
   - Each envset contains multiple key-value pairs
   - Keys are unique within an envset

---

## Security Model

### Encryption Strategy

- **Environment Variables**: AES-256 encryption using a master key
- **API Keys**: SHA-256 hashed, plain text never stored
- **Passwords**: Bcrypt hashed with configurable cost

### Access Control

1. **Row-Level Security**
   - Personal envsets: accessible only by owner
   - Team envsets: accessible by team members based on role

2. **API Key Permissions**
   - Granular JSONB permissions structure
   - Scope-based access control

3. **Role-Based Access**
   - Team roles: owner, admin, member, viewer
   - Hierarchical permission inheritance

### Audit Trail

- All CRUD operations logged to `audit_logs`
- Sensitive values redacted in logs
- IP address and user agent tracking
- Session and request correlation
- Login/logout event tracking
- Retention policies supported

---

## Usage Examples

### Scenario 1: Developer Local Setup

```sql
-- 1. Create personal envset for development
INSERT INTO envsets (name, type, owner_user_id, environment_id)
VALUES ('John''s Local Config', 'personal', 'user-uuid', 'dev-env-uuid');

-- 2. Add environment variables
INSERT INTO env_variables (envset_id, key, encrypted_value, is_sensitive)
VALUES 
  ('envset-uuid', 'DEBUG_MODE', 'encrypted:true', false),
  ('envset-uuid', 'LOCAL_DB_URL', 'encrypted:localhost:5432/dev', true);
```

### Scenario 2: Team Production Deployment

```sql
-- 1. Create team envset for production
INSERT INTO envsets (name, type, owner_team_id, environment_id)
VALUES ('Production Database', 'team', 'team-uuid', 'prod-env-uuid');

-- 2. Add sensitive production variables
INSERT INTO env_variables (envset_id, key, encrypted_value, is_sensitive)
VALUES 
  ('envset-uuid', 'DB_HOST', 'encrypted:prod-db.company.com', true),
  ('envset-uuid', 'DB_PASSWORD', 'encrypted:super_secret_pass', true);
```

### Scenario 3: API Access Control

```sql
-- Create service API key for CI/CD
INSERT INTO api_keys (name, key_hash, type, owner_team_id, permissions)
VALUES (
  'CI/CD Pipeline',
  'sha256:hash...',
  'service',
  'team-uuid',
  '{"envsets": ["read"], "deployments": ["write"]}'::jsonb
);
```

### Scenario 4: Audit Query

```sql
-- Find who accessed production secrets in the last 24 hours
SELECT 
  al.action,
  al.resource_type,
  u.username,
  al.ip_address,
  al.user_agent,
  al.session_id,
  al.created_at
FROM audit_logs al
LEFT JOIN users u ON al.user_id = u.id
LEFT JOIN api_keys ak ON al.api_key_id = ak.id
JOIN envsets es ON al.resource_id = es.id
JOIN environments env ON es.environment_id = env.id
WHERE env.name = 'production'
  AND al.resource_type IN ('envset', 'env_variable')
  AND al.created_at >= NOW() - INTERVAL '24 hours'
ORDER BY al.created_at DESC;

-- Track user login patterns
SELECT 
  u.username,
  al.ip_address,
  COUNT(*) as login_count,
  MAX(al.created_at) as last_login
FROM audit_logs al
JOIN users u ON al.user_id = u.id
WHERE al.action = 'LOGIN'
  AND al.created_at >= NOW() - INTERVAL '7 days'
GROUP BY u.username, al.ip_address
ORDER BY login_count DESC;
```

---

## Migration Guide

### Running Migrations

```bash
# Run all pending migrations
make db-migrate-up

# Rollback one migration
make db-migrate-down

# Check migration status
migrate -path migrations -database $POSTGRES_URL version
```

### Migration Files

The schema is divided into logical migration files:

1. `20250730103511_create_users` - Base user management
2. `20250730103516_create_teams` - Team structure
3. `20250730103519_create_projects` - Project organization
4. `20250730103523_create_environments` - Environment separation
5. `20250730103528_create_envsets` - Environment variable collections
6. `20250730103532_create_env_vars` - Encrypted key-value storage
7. `20250730103535_create_api_keys` - Authentication system
8. `20250730103538_create_user_teams` - Team membership
9. `20250730103542_create_audit_logs` - Audit trail and compliance

### Rollback Strategy

Each migration includes a corresponding `.down.sql` file for safe rollbacks:

```bash
# Rollback specific migration
migrate -path migrations -database $POSTGRES_URL down 1

# Rollback to specific version
migrate -path migrations -database $POSTGRES_URL migrate 20250730103538
```

---

## Performance Considerations

### Indexes

Strategic indexes are created for:
- Primary and foreign key lookups
- Frequently queried columns (email, username, team membership)
- Audit log queries (timestamp-based searches)
- Environment variable lookups (envset_id, key)

### Query Optimization

- Use appropriate JOINs for related data
- Leverage partial indexes for soft-deleted records
- Consider connection pooling for high-concurrency scenarios

### Scaling Recommendations

- Partition audit_logs by date for large datasets
- Consider read replicas for audit queries
- Implement caching layer for frequently accessed envsets

---

## Configuration

### Environment Variables

```bash
# Database connection
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=envmanager_dev
POSTGRES_USER=envmanager
POSTGRES_PASSWORD=your_password

# Encryption
ENCRYPTION_KEY=your-32-byte-encryption-key
JWT_SECRET=your-jwt-secret

# Migration path
MIGRATION_PATH=./migrations
```

### Development Setup

```bash
# Start development environment
make dev

# Reset database
make db-reset

# Generate SQLC code
make sqlc-generate
```