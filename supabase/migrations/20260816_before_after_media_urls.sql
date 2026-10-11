-- ==============================================================================
-- MIGRATION: Support Multiple Images & Before/After Statuses + Realtime Deletes
-- ==============================================================================

-- 1. Ensure `statuses` table supports multi-image and post_type
ALTER TABLE IF EXISTS public.statuses 
  ADD COLUMN IF NOT EXISTS media_urls JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS post_type TEXT DEFAULT 'SINGLE';

-- 2. Ensure `tharavad_stories` table supports media_urls and post_type
ALTER TABLE IF EXISTS public.tharavad_stories 
  ADD COLUMN IF NOT EXISTS media_urls JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS post_type TEXT DEFAULT 'SINGLE';

-- 3. Ensure `user_stories` table supports media_urls and post_type
ALTER TABLE IF EXISTS public.user_stories 
  ADD COLUMN IF NOT EXISTS media_urls JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS post_type TEXT DEFAULT 'SINGLE';

-- 4. Ensure `tharavadu_statuses` table supports media_urls and post_type
ALTER TABLE IF EXISTS public.tharavadu_statuses 
  ADD COLUMN IF NOT EXISTS media_urls JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS post_type TEXT DEFAULT 'SINGLE';

-- 5. Enable Realtime Replication for status tables
DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.statuses;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;

  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.tharavad_stories;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;

  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.user_stories;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
END $$;
