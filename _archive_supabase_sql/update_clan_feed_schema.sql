-- 1. Ensure `clan_posts` has all required columns
ALTER TABLE public.clan_posts ADD COLUMN IF NOT EXISTS clan_id INT;
ALTER TABLE public.clan_posts ADD COLUMN IF NOT EXISTS video_url TEXT;
ALTER TABLE public.clan_posts ADD COLUMN IF NOT EXISTS audio_url TEXT;
ALTER TABLE public.clan_posts ADD COLUMN IF NOT EXISTS bg_color TEXT;

-- 2. Post Likes Table
CREATE TABLE IF NOT EXISTS public.clan_post_likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID REFERENCES public.clan_posts(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(post_id, user_id)
);

-- 3. Post Comments Table
CREATE TABLE IF NOT EXISTS public.clan_post_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID REFERENCES public.clan_posts(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Post Views Table
CREATE TABLE IF NOT EXISTS public.clan_post_views (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID REFERENCES public.clan_posts(id) ON DELETE CASCADE,
    viewer_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(post_id, viewer_id)
);

-- 5. Recreate the main view to include the missing columns (clan_id, video_url, etc.)
DROP VIEW IF EXISTS public.user_clan_posts_with_stats;

CREATE OR REPLACE VIEW public.user_clan_posts_with_stats AS
SELECT 
  cp.id,
  cp.creator_id,
  cp.clan_id,
  cp.content,
  cp.image_url,
  cp.video_url,
  cp.audio_url,
  cp.bg_color,
  cp.created_at,
  (SELECT COUNT(*) FROM public.clan_post_views WHERE post_id = cp.id) as views_count,
  (SELECT COUNT(*) FROM public.clan_post_likes WHERE post_id = cp.id) as likes_count,
  (SELECT COUNT(*) FROM public.clan_post_comments WHERE post_id = cp.id) as comments_count
FROM public.clan_posts cp;

-- (Optional) If you want a Clans table, use INT for ID to match your Dart codebase, NOT TEXT.
CREATE TABLE IF NOT EXISTS public.clans (
    id INT PRIMARY KEY,
    name TEXT NOT NULL,
    group_name TEXT,
    location TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
-- 6. Enable Row Level Security (RLS)
ALTER TABLE public.clan_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clan_post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clan_post_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clan_post_views ENABLE ROW LEVEL SECURITY;

-- 7. Public RLS Policies (Allow all authenticated users to read/insert/update/delete their own)

-- clan_posts
DROP POLICY IF EXISTS "Enable read access for all users" ON public.clan_posts;
CREATE POLICY "Enable read access for all users" ON public.clan_posts FOR SELECT USING (true);

DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.clan_posts;
CREATE POLICY "Enable insert for authenticated users only" ON public.clan_posts FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Enable update for users based on creator_id" ON public.clan_posts;
CREATE POLICY "Enable update for users based on creator_id" ON public.clan_posts FOR UPDATE USING (auth.uid() = creator_id);

DROP POLICY IF EXISTS "Enable delete for users based on creator_id" ON public.clan_posts;
CREATE POLICY "Enable delete for users based on creator_id" ON public.clan_posts FOR DELETE USING (auth.uid() = creator_id);

-- clan_post_likes
DROP POLICY IF EXISTS "Enable read access for all users" ON public.clan_post_likes;
CREATE POLICY "Enable read access for all users" ON public.clan_post_likes FOR SELECT USING (true);

DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.clan_post_likes;
CREATE POLICY "Enable insert for authenticated users only" ON public.clan_post_likes FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Enable delete for users based on user_id" ON public.clan_post_likes;
CREATE POLICY "Enable delete for users based on user_id" ON public.clan_post_likes FOR DELETE USING (auth.uid() = user_id);

-- clan_post_comments
DROP POLICY IF EXISTS "Enable read access for all users" ON public.clan_post_comments;
CREATE POLICY "Enable read access for all users" ON public.clan_post_comments FOR SELECT USING (true);

DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.clan_post_comments;
CREATE POLICY "Enable insert for authenticated users only" ON public.clan_post_comments FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Enable update for users based on user_id" ON public.clan_post_comments;
CREATE POLICY "Enable update for users based on user_id" ON public.clan_post_comments FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Enable delete for users based on user_id" ON public.clan_post_comments;
CREATE POLICY "Enable delete for users based on user_id" ON public.clan_post_comments FOR DELETE USING (auth.uid() = user_id);

-- clan_post_views
DROP POLICY IF EXISTS "Enable read access for all users" ON public.clan_post_views;
CREATE POLICY "Enable read access for all users" ON public.clan_post_views FOR SELECT USING (true);

DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.clan_post_views;
CREATE POLICY "Enable insert for authenticated users only" ON public.clan_post_views FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Optional: Enable RLS on clans (read-only for public)
-- ALTER TABLE public.clans ENABLE ROW LEVEL SECURITY;
-- CREATE POLICY "Enable read access for all users" ON public.clans FOR SELECT USING (true);
