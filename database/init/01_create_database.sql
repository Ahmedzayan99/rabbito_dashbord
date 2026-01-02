-- Create database and user if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'rabbit_ecosystem') THEN
        CREATE DATABASE rabbit_ecosystem;
    END IF;
END
$$;

-- Create user if doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'rabbit_user') THEN
        CREATE USER rabbit_user WITH PASSWORD 'rabbit_password_2024';
    END IF;
END
$$;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE rabbit_ecosystem TO rabbit_user;
ALTER USER rabbit_user CREATEDB;