-- ====================================================================
-- Traffic & Guest Analytics Database Tables
-- Kurichiyar Matrimony Admin Panel
-- ====================================================================

-- 1. Registered User Sessions
CREATE TABLE IF NOT EXISTS public.user_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
    user_name TEXT,
    user_phone TEXT,
    session_start TIMESTAMPTZ DEFAULT NOW(),
    last_active TIMESTAMPTZ DEFAULT NOW(),
    location TEXT DEFAULT 'Wayanad, Kerala',
    is_online BOOLEAN DEFAULT true,
    device_model TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Guest Visitor Analytics
CREATE TABLE IF NOT EXISTS public.guest_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_id TEXT UNIQUE NOT NULL,
    device_model TEXT DEFAULT 'Unknown Device',
    first_seen TIMESTAMPTZ DEFAULT NOW(),
    last_active TIMESTAMPTZ DEFAULT NOW(),
    total_session_seconds INT DEFAULT 0,
    is_online BOOLEAN DEFAULT true,
    location TEXT DEFAULT 'Kerala, India',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Screen Navigation & Time Spent Tracking
CREATE TABLE IF NOT EXISTS public.screen_page_views (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id TEXT,
    user_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
    device_id TEXT,
    screen_name TEXT NOT NULL,
    time_spent_seconds INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Indexes for High-Performance Queries
CREATE INDEX IF NOT EXISTS idx_user_sessions_online ON public.user_sessions(is_online, last_active);
CREATE INDEX IF NOT EXISTS idx_guest_analytics_online ON public.guest_analytics(is_online, last_active);
CREATE INDEX IF NOT EXISTS idx_guest_analytics_device ON public.guest_analytics(device_id);
CREATE INDEX IF NOT EXISTS idx_screen_page_views_screen ON public.screen_page_views(screen_name);
CREATE INDEX IF NOT EXISTS idx_screen_page_views_user ON public.screen_page_views(user_id);
CREATE INDEX IF NOT EXISTS idx_screen_page_views_device ON public.screen_page_views(device_id);

-- 5. Row Level Security (RLS)
ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guest_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.screen_page_views ENABLE ROW LEVEL SECURITY;

-- Allow public inserts & updates for telemetry
CREATE POLICY "Allow public session insert" ON public.user_sessions FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public session update" ON public.user_sessions FOR UPDATE USING (true);
CREATE POLICY "Allow public session select" ON public.user_sessions FOR SELECT USING (true);

CREATE POLICY "Allow public guest insert" ON public.guest_analytics FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public guest update" ON public.guest_analytics FOR UPDATE USING (true);
CREATE POLICY "Allow public guest select" ON public.guest_analytics FOR SELECT USING (true);

CREATE POLICY "Allow public screen_views insert" ON public.screen_page_views FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public screen_views select" ON public.screen_page_views FOR SELECT USING (true);

-- Enable Realtime for live dashboard presence
ALTER PUBLICATION supabase_realtime ADD TABLE public.user_sessions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.guest_analytics;
ALTER PUBLICATION supabase_realtime ADD TABLE public.screen_page_views;
