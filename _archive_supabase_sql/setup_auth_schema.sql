-- 1. Enable required PostgreSQL extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 2. Create auth schema and users table
CREATE SCHEMA IF NOT EXISTS auth;
CREATE TABLE IF NOT EXISTS auth.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    instance_id UUID,
    email TEXT UNIQUE,
    encrypted_password TEXT,
    password TEXT,
    email_confirmed_at TIMESTAMP WITH TIME ZONE,
    invited_at TIMESTAMP WITH TIME ZONE,
    confirmation_token VARCHAR(255) DEFAULT '',
    confirmation_sent_at TIMESTAMP WITH TIME ZONE,
    recovery_token VARCHAR(255) DEFAULT '',
    recovery_sent_at TIMESTAMP WITH TIME ZONE,
    email_change_token_new VARCHAR(255) DEFAULT '',
    email_change VARCHAR(255) DEFAULT '',
    email_change_sent_at TIMESTAMP WITH TIME ZONE,
    last_sign_in_at TIMESTAMP WITH TIME ZONE,
    raw_app_meta_data JSONB DEFAULT '{}'::jsonb,
    raw_user_meta_data JSONB DEFAULT '{}'::jsonb,
    is_super_admin BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    phone TEXT,
    phone_confirmed_at TIMESTAMP WITH TIME ZONE,
    phone_change TEXT,
    phone_change_token VARCHAR(255) DEFAULT '',
    phone_change_sent_at TIMESTAMP WITH TIME ZONE,
    confirmed_at TIMESTAMP WITH TIME ZONE,
    email_change_token_current VARCHAR(255) DEFAULT '',
    email_change_confirm_status SMALLINT DEFAULT 0,
    banned_until TIMESTAMP WITH TIME ZONE,
    reauthentication_token VARCHAR(255) DEFAULT '',
    reauthentication_sent_at TIMESTAMP WITH TIME ZONE,
    is_sso_user BOOLEAN DEFAULT false,
    deleted_at TIMESTAMP WITH TIME ZONE,
    role TEXT DEFAULT 'authenticated',
    aud TEXT DEFAULT 'authenticated'
);

-- In case table already exists, run ALTER TABLE statements to add any missing columns safely
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS instance_id UUID;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS email_confirmed_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS invited_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS confirmation_token VARCHAR(255) DEFAULT '';
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS confirmation_sent_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS recovery_token VARCHAR(255) DEFAULT '';
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS recovery_sent_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS email_change_token_new VARCHAR(255) DEFAULT '';
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS email_change VARCHAR(255) DEFAULT '';
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS email_change_sent_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS last_sign_in_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS is_super_admin BOOLEAN DEFAULT false;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS phone_confirmed_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS phone_change TEXT;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS phone_change_token VARCHAR(255) DEFAULT '';
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS phone_change_sent_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS confirmed_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS email_change_token_current VARCHAR(255) DEFAULT '';
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS email_change_confirm_status SMALLINT DEFAULT 0;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS banned_until TIMESTAMP WITH TIME ZONE;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS reauthentication_token VARCHAR(255) DEFAULT '';
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS reauthentication_sent_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS is_sso_user BOOLEAN DEFAULT false;
ALTER TABLE auth.users ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

-- Fix potential NULL value parsing crashes inside GoTrue scanner
UPDATE auth.users SET confirmation_token = '' WHERE confirmation_token IS NULL;
UPDATE auth.users SET recovery_token = '' WHERE recovery_token IS NULL;
UPDATE auth.users SET email_change_token_new = '' WHERE email_change_token_new IS NULL;
UPDATE auth.users SET email_change_token_current = '' WHERE email_change_token_current IS NULL;
UPDATE auth.users SET reauthentication_token = '' WHERE reauthentication_token IS NULL;
UPDATE auth.users SET phone_change_token = '' WHERE phone_change_token IS NULL;

-- 3. Create auth.uid() and auth.role() functions so that RLS policies that reference them don't fail
CREATE OR REPLACE FUNCTION auth.uid()
RETURNS uuid
LANGUAGE sql STABLE
AS $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid;
$$;

CREATE OR REPLACE FUNCTION auth.role()
RETURNS text
LANGUAGE sql STABLE
AS $$
  select nullif(current_setting('request.jwt.claim.role', true), '')::text;
$$;

-- 4. Create storage schema and buckets table stub
CREATE SCHEMA IF NOT EXISTS storage;
CREATE TABLE IF NOT EXISTS storage.buckets (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    public BOOLEAN DEFAULT false
);

-- 5. Enable Row Level Security (RLS) on auth.users
ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

-- 6. Create RLS policies allowing public read access for authentication
DROP POLICY IF EXISTS "Allow public read access for authentication" ON auth.users;
CREATE POLICY "Allow public read access for authentication" 
ON auth.users 
FOR SELECT 
TO public 
USING (true);

-- Also add INSERT and UPDATE policies to allow signup/updates
DROP POLICY IF EXISTS "Allow public insert for authentication" ON auth.users;
CREATE POLICY "Allow public insert for authentication" 
ON auth.users 
FOR INSERT 
TO public 
WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public update for authentication" ON auth.users;
CREATE POLICY "Allow public update for authentication" 
ON auth.users 
FOR UPDATE 
TO public 
USING (true);

-- 7. Grant necessary permissions so the app can successfully query the schema
GRANT USAGE ON SCHEMA auth TO public;
GRANT SELECT, INSERT, UPDATE, DELETE ON auth.users TO public;

GRANT USAGE ON SCHEMA storage TO public;
GRANT SELECT, INSERT, UPDATE, DELETE ON storage.buckets TO public;
