-- ==============================================================================
-- UPCOMING EVENTS SCHEMA & STORAGE
-- ==============================================================================

-- 1. Create upcoming_events Table
CREATE TABLE IF NOT EXISTS public.upcoming_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    location TEXT,
    event_date DATE NOT NULL,
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 2. Enable Row Level Security (RLS)
ALTER TABLE public.upcoming_events ENABLE ROW LEVEL SECURITY;

-- 3. Policies
DROP POLICY IF EXISTS "Public can view upcoming events" ON public.upcoming_events;
CREATE POLICY "Public can view upcoming events"
ON public.upcoming_events FOR SELECT
USING (true);

DROP POLICY IF EXISTS "Authenticated users can manage upcoming events" ON public.upcoming_events;
CREATE POLICY "Authenticated users can manage upcoming events"
ON public.upcoming_events FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

-- 4. Storage Bucket Setup
INSERT INTO storage.buckets (id, name, public)
VALUES ('event-images', 'event-images', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DROP POLICY IF EXISTS "Public can read event-images" ON storage.objects;
CREATE POLICY "Public can read event-images"
ON storage.objects FOR SELECT
USING (bucket_id = 'event-images');

DROP POLICY IF EXISTS "Authenticated users can upload event-images" ON storage.objects;
CREATE POLICY "Authenticated users can upload event-images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'event-images');

DROP POLICY IF EXISTS "Authenticated users can update event-images" ON storage.objects;
CREATE POLICY "Authenticated users can update event-images"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'event-images');
