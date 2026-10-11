-- ================================================================================
-- EPHEMERAL STATUS ENGINE (ESE) MIGRATION
-- ================================================================================

-- 1.1 Extensions & Enums
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_cron";

DO $$ BEGIN
    CREATE TYPE story_type_enum AS ENUM (
        'standard',
        'before_after',
        'countdown',
        'poll',
        'chain_root',
        'view_once'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE privacy_type_enum AS ENUM (
        'public',
        'contacts_only',
        'close_circle',
        'excluded',
        'geo_fenced'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 1.2 Core Stories Table
CREATE TABLE IF NOT EXISTS public.stories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    story_type story_type_enum NOT NULL DEFAULT 'standard',
    media_urls TEXT[] NOT NULL,
    media_durations_ms INT[] DEFAULT ARRAY[5000],
    caption TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    privacy_type privacy_type_enum NOT NULL DEFAULT 'public',
    privacy_whitelist UUID[] DEFAULT NULL,
    privacy_blacklist UUID[] DEFAULT NULL,
    geo_point POINT DEFAULT NULL,
    geo_radius_meters INT DEFAULT 0,
    is_sponsored BOOLEAN DEFAULT FALSE,
    priority_weight INT DEFAULT 0,
    is_flagged BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (timezone('utc', now()) + INTERVAL '24 hours')
);

-- 1.3 Story Views Table (Idempotent Tracking)
CREATE TABLE IF NOT EXISTS public.story_views (
    id BIGSERIAL PRIMARY KEY,
    story_id UUID NOT NULL REFERENCES public.stories(id) ON DELETE CASCADE,
    viewer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    is_ghost_mode BOOLEAN DEFAULT FALSE,
    viewed_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    CONSTRAINT unique_story_viewer UNIQUE(story_id, viewer_id)
);

-- 1.4 Story Interactions Table (Polls, Clicks, Reactions)
CREATE TABLE IF NOT EXISTS public.story_interactions (
    id BIGSERIAL PRIMARY KEY,
    story_id UUID NOT NULL REFERENCES public.stories(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    interaction_type TEXT NOT NULL,
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 1.5 High-Throughput Composite Indexes
CREATE INDEX IF NOT EXISTS idx_stories_feed_active ON public.stories (expires_at DESC, priority_weight DESC) WHERE is_flagged = FALSE;
CREATE INDEX IF NOT EXISTS idx_stories_user_active ON public.stories (user_id, expires_at DESC);
CREATE INDEX IF NOT EXISTS idx_story_views_lookup ON public.story_views (story_id, viewer_id);

-- 1.6 Row Level Security (RLS)
ALTER TABLE public.stories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.story_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.story_interactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Stories Viewability Rules" ON public.stories;
CREATE POLICY "Stories Viewability Rules" ON public.stories
FOR SELECT USING (
    expires_at > timezone('utc', now())
    AND is_flagged = FALSE
    AND (
        privacy_type = 'public'
        OR user_id = auth.uid()
        OR (privacy_type = 'close_circle' AND auth.uid() = ANY(privacy_whitelist))
        OR (privacy_type = 'contacts_only' AND auth.uid() NOT IN (SELECT unnest(privacy_blacklist)))
    )
);

DROP POLICY IF EXISTS "Stories Insert Policy" ON public.stories;
CREATE POLICY "Stories Insert Policy" ON public.stories
FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Stories View Log Policy" ON public.story_views;
CREATE POLICY "Stories View Log Policy" ON public.story_views
FOR INSERT WITH CHECK (auth.uid() = viewer_id);

DROP POLICY IF EXISTS "Stories Interaction Policy" ON public.story_interactions;
CREATE POLICY "Stories Interaction Policy" ON public.story_interactions
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 1.7 Hourly Purge via pg_cron (Safe check)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
        PERFORM cron.schedule(
            'cleanup-expired-stories',
            '0 * * * *',
            $$DELETE FROM public.stories WHERE expires_at < timezone('utc', now());$$
        );
    END IF;
EXCEPTION
    WHEN OTHERS THEN NULL;
END $$;

-- 1.8 Feed Aggregation RPC Function
CREATE OR REPLACE FUNCTION get_active_story_feed(current_user_id UUID)
RETURNS TABLE (
    author_id UUID,
    author_name TEXT,
    author_avatar TEXT,
    has_unseen BOOLEAN,
    latest_story_time TIMESTAMPTZ,
    story_tray JSONB
) LANGUAGE sql STABLE AS $$
    SELECT 
        p.id AS author_id,
        COALESCE(p.full_name, 'User') AS author_name,
        p.avatar_url AS author_avatar,
        EXISTS (
            SELECT 1 FROM public.stories s2 
            WHERE s2.user_id = p.id 
              AND s2.expires_at > timezone('utc', now())
              AND s2.id NOT IN (SELECT story_id FROM public.story_views WHERE viewer_id = current_user_id)
        ) AS has_unseen,
        max(s.created_at) AS latest_story_time,
        jsonb_agg(s.* ORDER BY s.is_sponsored DESC, s.created_at ASC) AS story_tray
    FROM public.stories s
    JOIN public.kurichiyar_profiles p ON s.user_id = p.id
    WHERE s.expires_at > timezone('utc', now())
      AND s.is_flagged = FALSE
    GROUP BY p.id, p.full_name, p.avatar_url
    ORDER BY has_unseen DESC, max(s.priority_weight) DESC, latest_story_time DESC;
$$;
