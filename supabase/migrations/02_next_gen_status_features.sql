-- ================================================================================
-- NEXT-GEN STATUS FEATURES MIGRATION
-- ================================================================================

-- 1. Add new values to story_type_enum (outside transaction block if run individually)
ALTER TYPE story_type_enum ADD VALUE IF NOT EXISTS 'audio_wave';
ALTER TYPE story_type_enum ADD VALUE IF NOT EXISTS 'bio_card';

-- 2. Burn story RPC for View-Once Stories
CREATE OR REPLACE FUNCTION public.burn_story(story_id UUID)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    DELETE FROM public.stories 
    WHERE id = story_id AND story_type = 'view_once';
END;
$$;

-- 3. Music Catalog Table
CREATE TABLE IF NOT EXISTS public.status_music_catalog (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    artist TEXT NOT NULL,
    category TEXT,
    audio_url TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 4. Frames Catalog Table
CREATE TABLE IF NOT EXISTS public.status_frames_catalog (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    frame_url TEXT NOT NULL,
    active_from TIMESTAMPTZ,
    active_to TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 5. Enable RLS
ALTER TABLE public.status_music_catalog ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.status_frames_catalog ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public select music" ON public.status_music_catalog;
CREATE POLICY "Public select music" ON public.status_music_catalog FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public select frames" ON public.status_frames_catalog;
CREATE POLICY "Public select frames" ON public.status_frames_catalog FOR SELECT USING (true);

-- Allow all writes for admins
DROP POLICY IF EXISTS "Admin write music" ON public.status_music_catalog;
CREATE POLICY "Admin write music" ON public.status_music_catalog FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.kurichiyar_profiles 
        WHERE id = auth.uid() AND (role = 'admin' OR is_admin = true)
      )
);

DROP POLICY IF EXISTS "Admin write frames" ON public.status_frames_catalog;
CREATE POLICY "Admin write frames" ON public.status_frames_catalog FOR ALL USING (
    EXISTS (
        SELECT 1 FROM public.kurichiyar_profiles 
        WHERE id = auth.uid() AND (role = 'admin' OR is_admin = true)
      )
);
