-- =============================================================================
-- REBUILD THARAVADU STATUS TRAY DB TABLE & RPC FUNCTION
-- =============================================================================

-- 1. Create tharavadu_statuses table if not exists
CREATE TABLE IF NOT EXISTS public.tharavadu_statuses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    user_name TEXT,
    tharavad_name TEXT NOT NULL,
    media_url TEXT NOT NULL,
    media_type TEXT DEFAULT 'image',
    caption TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '24 hours')
);

-- Index for efficient fetching
CREATE INDEX IF NOT EXISTS idx_tharavadu_statuses_expires ON public.tharavadu_statuses(expires_at);
CREATE INDEX IF NOT EXISTS idx_tharavadu_statuses_tharavad ON public.tharavadu_statuses(tharavad_name);

-- 2. Create RPC: get_active_tharavadu_tray
-- Groups non-expired statuses by tharavad_name with item count and latest media URL
CREATE OR REPLACE FUNCTION public.get_active_tharavadu_tray()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_agg(
        jsonb_build_object(
            'tharavad_name', tharavad_name,
            'status_count', count(*),
            'latest_media_url', (
                SELECT media_url 
                FROM public.tharavadu_statuses s2 
                WHERE s2.tharavad_name = s.tharavad_name 
                  AND s2.expires_at > NOW() 
                ORDER BY created_at DESC 
                LIMIT 1
            ),
            'statuses', (
                SELECT jsonb_agg(
                    jsonb_build_object(
                        'id', id,
                        'user_id', user_id,
                        'user_name', user_name,
                        'tharavad_name', tharavad_name,
                        'media_url', media_url,
                        'media_type', media_type,
                        'caption', caption,
                        'created_at', created_at
                    ) ORDER BY created_at ASC
                )
                FROM public.tharavadu_statuses s3
                WHERE s3.tharavad_name = s.tharavad_name
                  AND s3.expires_at > NOW()
            )
        )
    ) INTO result
    FROM public.tharavadu_statuses s
    WHERE expires_at > NOW()
    GROUP BY tharavad_name;

    RETURN COALESCE(result, '[]'::jsonb);
END;
$$;
