-- User Creation
-- name: CreateUser :one
INSERT INTO users (email, username, password_hash, first_name, last_name)
VALUES ($1, $2, $3, $4, $5)
    RETURNING *;

-- User Retrieval by ID
-- name: GetUserByID :one
SELECT * FROM users
WHERE id = $1 AND deleted_at IS NULL;

-- User Retrieval by Email (for login)
-- name: GetUserByEmail :one
SELECT * FROM users
WHERE email = $1 AND deleted_at IS NULL;

-- User Retrieval by Username
-- name: GetUserByUsername :one
SELECT * FROM users
WHERE username = $1 AND deleted_at IS NULL;

-- List All Active Users (with pagination)
-- name: ListUsers :many
SELECT * FROM users
WHERE deleted_at IS NULL
ORDER BY created_at DESC
    LIMIT $1 OFFSET $2;

-- Count Active Users
-- name: CountUsers :one
SELECT COUNT(*) FROM users
WHERE deleted_at IS NULL;

-- Update User Profile
-- name: UpdateUser :one
UPDATE users
SET
    email = $2,
    username = $3,
    first_name = $4,
    last_name = $5,
    updated_at = NOW()
WHERE id = $1 AND deleted_at IS NULL
    RETURNING *;

-- Update User Password
-- name: UpdateUserPassword :exec
UPDATE users
SET
    password_hash = $2,
    updated_at = NOW()
WHERE id = $1 AND deleted_at IS NULL;

-- Deactivate User (soft delete)
-- name: DeactivateUser :exec
UPDATE users
SET
    is_active = false,
    updated_at = NOW()
WHERE id = $1 AND deleted_at IS NULL;

-- Soft Delete User
-- name: SoftDeleteUser :exec
UPDATE users
SET
    deleted_at = NOW(),
    updated_at = NOW()
WHERE id = $1;

-- Reactivate User
-- name: ReactivateUser :exec
UPDATE users
SET
    is_active = true,
    updated_at = NOW()
WHERE id = $1 AND deleted_at IS NULL;

-- Check if Email Exists
-- name: EmailExists :one
SELECT EXISTS(
    SELECT 1 FROM users
    WHERE email = $1 AND deleted_at IS NULL
);

-- Check if Username Exists
-- name: UsernameExists :one
SELECT EXISTS(
    SELECT 1 FROM users
    WHERE username = $1 AND deleted_at IS NULL
);

-- Search Users by Name or Email
-- name: SearchUsers :many
SELECT * FROM users
WHERE deleted_at IS NULL
  AND (
    first_name ILIKE '%' || $1 || '%' OR
    last_name ILIKE '%' || $1 || '%' OR
    email ILIKE '%' || $1 || '%' OR
    username ILIKE '%' || $1 || '%'
    )
ORDER BY created_at DESC
    LIMIT $2 OFFSET $3;