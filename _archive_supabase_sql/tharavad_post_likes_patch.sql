-- =========================================================================
-- SQL PATCH: RESOLVE SUPABASE SCHEMA CACHE & UUID TYPE MISMATCH
-- Run this in the Supabase SQL Editor
-- =========================================================================

-- 1. Create the missing tharavad_post_likes table
CREATE TABLE IF NOT EXISTS public.tharavad_post_likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
    tharavadu_id TEXT NOT NULL,
    post_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, tharavadu_id, post_id)
);

-- 2. Update tharavadu/clan ID column types in kurichiyar_profiles from UUID to TEXT
ALTER TABLE public.kurichiyar_profiles 
  ALTER COLUMN father_clan_id TYPE TEXT USING father_clan_id::text,
  ALTER COLUMN mother_clan_id TYPE TEXT USING mother_clan_id::text,
  ALTER COLUMN father_tharavadu_id TYPE TEXT USING father_tharavadu_id::text,
  ALTER COLUMN mother_tharavadu_id TYPE TEXT USING mother_tharavadu_id::text;

-- 3. Update tharavadu ID column types in other dependent tables to TEXT
ALTER TABLE public.active_tharavad_statuses_feed 
  ALTER COLUMN tharavad_id TYPE TEXT USING tharavad_id::text;

ALTER TABLE public.tharavadu_statuses 
  ALTER COLUMN tharavad_id TYPE TEXT USING tharavad_id::text;

ALTER TABLE public.tharavadu_houses 
  ALTER COLUMN tharavad_id TYPE TEXT USING tharavad_id::text;

ALTER TABLE public.tharavadu_exclusions 
  ALTER COLUMN tharavad_id TYPE TEXT USING tharavad_id::text,
  ALTER COLUMN excluded_tharavad_id TYPE TEXT USING excluded_tharavad_id::text;

ALTER TABLE public.tharavadu_photo_requests 
  ALTER COLUMN tharavad_id TYPE TEXT USING tharavad_id::text;

-- 4. Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
