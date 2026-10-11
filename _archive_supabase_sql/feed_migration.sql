-- Migration for Clan Feed Upgrade

-- Create clan_feed_posts table
CREATE TABLE public.clan_feed_posts (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    clan_id text NOT NULL REFERENCES public.tharavad_master(id) ON DELETE CASCADE,
    creator_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content text NOT NULL,
    photo_url text,
    video_url text,
    audio_url text,
    background_color text,
    created_at timestamp with time zone DEFAULT now()
);

-- Create clan_feed_likes table
CREATE TABLE public.clan_feed_likes (
    post_id uuid NOT NULL REFERENCES public.clan_feed_posts(id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at timestamp with time zone DEFAULT now(),
    PRIMARY KEY (post_id, user_id)
);

-- Create clan_feed_comments table
CREATE TABLE public.clan_feed_comments (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    post_id uuid NOT NULL REFERENCES public.clan_feed_posts(id) ON DELETE CASCADE,
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content text NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.clan_feed_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clan_feed_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clan_feed_comments ENABLE ROW LEVEL SECURITY;

-- 90-day auto-delete cron job using pg_cron (runs daily at midnight)
-- Make sure pg_cron extension is enabled first: CREATE EXTENSION IF NOT EXISTS pg_cron;
SELECT cron.schedule(
    'delete_old_clan_feed_posts',
    '0 0 * * *',
    $$ DELETE FROM public.clan_feed_posts WHERE created_at < NOW() - INTERVAL '90 days' $$
);

-- ==========================================
-- STORAGE BUCKET & RLS CONFIGURATION
-- ==========================================

-- Create the clan_feed_media bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public) 
VALUES ('clan_feed_media', 'clan_feed_media', true)
ON CONFLICT (id) DO NOTHING;

-- Allow public read access to all files in clan_feed_media
CREATE POLICY "Public Read Access" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'clan_feed_media');

-- Allow authenticated users to upload files to clan_feed_media
CREATE POLICY "Authenticated Users Can Upload" 
ON storage.objects FOR INSERT 
WITH CHECK (
  bucket_id = 'clan_feed_media' AND 
  auth.role() = 'authenticated'
);

-- Allow users to delete their own uploaded files
CREATE POLICY "Users Can Delete Own Files" 
ON storage.objects FOR DELETE 
USING (
  bucket_id = 'clan_feed_media' AND 
  auth.uid() = owner
);
