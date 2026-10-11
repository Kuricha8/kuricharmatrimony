-- Migration: Clan Feed Setup with 90-day retention and Media capabilities

-- 1. Create the main clan_feed_posts table
CREATE TABLE IF NOT EXISTS clan_feed_posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  creator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  clan_id INTEGER NOT NULL,
  post_type TEXT NOT NULL DEFAULT 'text', -- 'text', 'photo', 'video', 'audio'
  content TEXT,
  background_color TEXT,
  text_color TEXT,
  media_url TEXT,
  video_duration INTEGER,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Create likes table
CREATE TABLE IF NOT EXISTS clan_feed_likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID NOT NULL REFERENCES clan_feed_posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- 3. Create comments table
CREATE TABLE IF NOT EXISTS clan_feed_comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID NOT NULL REFERENCES clan_feed_posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE clan_feed_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE clan_feed_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE clan_feed_comments ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies
-- Users can read posts if they belong to the same clan
CREATE POLICY "Users can view posts of their own clan" ON clan_feed_posts
  FOR SELECT USING (
    clan_id = (SELECT father_clan_id FROM kurichiyar_profiles WHERE id = auth.uid()) OR
    clan_id = (SELECT mother_clan_id FROM kurichiyar_profiles WHERE id = auth.uid())
  );

CREATE POLICY "Users can insert posts for their clan" ON clan_feed_posts
  FOR INSERT WITH CHECK (
    clan_id = (SELECT father_clan_id FROM kurichiyar_profiles WHERE id = auth.uid()) OR
    clan_id = (SELECT mother_clan_id FROM kurichiyar_profiles WHERE id = auth.uid())
  );

CREATE POLICY "Users can delete their own posts" ON clan_feed_posts
  FOR DELETE USING (creator_id = auth.uid());


-- Likes Policies
CREATE POLICY "Users can view likes on clan posts" ON clan_feed_likes
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM clan_feed_posts p WHERE p.id = clan_feed_likes.post_id AND (
      p.clan_id = (SELECT father_clan_id FROM kurichiyar_profiles WHERE id = auth.uid()) OR
      p.clan_id = (SELECT mother_clan_id FROM kurichiyar_profiles WHERE id = auth.uid())
    ))
  );

CREATE POLICY "Users can like clan posts" ON clan_feed_likes
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM clan_feed_posts p WHERE p.id = clan_feed_likes.post_id AND (
      p.clan_id = (SELECT father_clan_id FROM kurichiyar_profiles WHERE id = auth.uid()) OR
      p.clan_id = (SELECT mother_clan_id FROM kurichiyar_profiles WHERE id = auth.uid())
    ))
  );

CREATE POLICY "Users can unlike their own likes" ON clan_feed_likes
  FOR DELETE USING (user_id = auth.uid());


-- Comments Policies
CREATE POLICY "Users can view comments on clan posts" ON clan_feed_comments
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM clan_feed_posts p WHERE p.id = clan_feed_comments.post_id AND (
      p.clan_id = (SELECT father_clan_id FROM kurichiyar_profiles WHERE id = auth.uid()) OR
      p.clan_id = (SELECT mother_clan_id FROM kurichiyar_profiles WHERE id = auth.uid())
    ))
  );

CREATE POLICY "Users can add comments to clan posts" ON clan_feed_comments
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM clan_feed_posts p WHERE p.id = clan_feed_comments.post_id AND (
      p.clan_id = (SELECT father_clan_id FROM kurichiyar_profiles WHERE id = auth.uid()) OR
      p.clan_id = (SELECT mother_clan_id FROM kurichiyar_profiles WHERE id = auth.uid())
    ))
  );

CREATE POLICY "Users can delete their own comments" ON clan_feed_comments
  FOR DELETE USING (user_id = auth.uid());


-- 6. Set up pg_cron for 90-day retention
-- Make sure pg_cron is enabled in Supabase extensions first!
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Create a function to clean up old posts
CREATE OR REPLACE FUNCTION delete_old_clan_feed_posts()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- This will automatically cascade delete likes and comments because of ON DELETE CASCADE
  DELETE FROM clan_feed_posts WHERE created_at < NOW() - INTERVAL '90 days';
  
  -- Note: Supabase Storage files associated with these posts will need to be deleted 
  -- using a storage trigger or edge function, as pg_cron cannot directly delete files.
END;
$$;

-- Schedule the cleanup to run every day at midnight
SELECT cron.schedule('delete_old_clan_posts_daily', '0 0 * * *', $$
  SELECT delete_old_clan_feed_posts();
$$);
