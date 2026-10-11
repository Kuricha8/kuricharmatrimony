-- =============================================================================
-- Migration: Tharavadu Feed Access Control, Tagging & Automated Top-Liked Icon System
-- =============================================================================

-- 1. Create tharavadu_posts table
CREATE TABLE IF NOT EXISTS public.tharavadu_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tharavadu_id TEXT NOT NULL,
  author_id UUID NOT NULL,
  content TEXT,
  media_type TEXT NOT NULL CHECK (media_type IN ('text', 'photo', 'video', 'audio')),
  media_url TEXT,
  thumbnail_url TEXT,
  duration_seconds INTEGER DEFAULT 0,
  is_tharavadu_tag BOOLEAN DEFAULT FALSE,
  likes_count INTEGER DEFAULT 0,
  comments_count INTEGER DEFAULT 0,
  is_deleted BOOLEAN DEFAULT FALSE,
  is_moderated BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tharavadu_posts_clan ON public.tharavadu_posts (tharavadu_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_tharavadu_posts_tag ON public.tharavadu_posts (tharavadu_id, is_tharavadu_tag, likes_count DESC, created_at ASC);

-- 2. Create tharavadu_likes table
CREATE TABLE IF NOT EXISTS public.tharavadu_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES public.tharavadu_posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  tharavadu_id TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_tharavadu_likes_post ON public.tharavadu_likes(post_id);

-- 3. Add icon_post_id column to tharavadu table if it exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tharavadu') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tharavadu' AND column_name = 'icon_post_id') THEN
      ALTER TABLE public.tharavadu ADD COLUMN icon_post_id UUID;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tharavadu' AND column_name = 'icon_author_id') THEN
      ALTER TABLE public.tharavadu ADD COLUMN icon_author_id UUID;
    END IF;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tharavadus') THEN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tharavadus' AND column_name = 'icon_post_id') THEN
      ALTER TABLE public.tharavadus ADD COLUMN icon_post_id UUID;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'tharavadus' AND column_name = 'icon_author_id') THEN
      ALTER TABLE public.tharavadus ADD COLUMN icon_author_id UUID;
    END IF;
  END IF;
END $$;

-- 4. Function & Trigger: Recalculate Top-Liked Tagged Photo Icon
CREATE OR REPLACE FUNCTION public.fn_sync_tharavadu_top_icon()
RETURNS TRIGGER AS $$
DECLARE
  v_tharavadu_id TEXT;
  v_top_post_id UUID;
  v_top_media_url TEXT;
  v_top_author_id UUID;
  v_old_author_id UUID;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_tharavadu_id := OLD.tharavadu_id;
  ELSE
    v_tharavadu_id := NEW.tharavadu_id;
  END IF;

  -- Find the candidate tagged photo with the highest likes (earliest timestamp tie-breaker)
  SELECT id, media_url, author_id
  INTO v_top_post_id, v_top_media_url, v_top_author_id
  FROM public.tharavadu_posts
  WHERE tharavadu_id = v_tharavadu_id
    AND media_type = 'photo'
    AND is_tharavadu_tag = TRUE
    AND is_deleted = FALSE
    AND is_moderated = FALSE
    AND media_url IS NOT NULL
  ORDER BY likes_count DESC, created_at ASC
  LIMIT 1;

  -- Update tharavadu table icon_url and icon_post_id
  IF v_top_post_id IS NOT NULL THEN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tharavadu') THEN
      UPDATE public.tharavadu
      SET icon_url = v_top_media_url,
          icon_post_id = v_top_post_id,
          icon_author_id = v_top_author_id
      WHERE id::TEXT = v_tharavadu_id OR name = v_tharavadu_id;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tharavadus') THEN
      UPDATE public.tharavadus
      SET icon_url = v_top_media_url,
          icon_post_id = v_top_post_id,
          icon_author_id = v_top_author_id
      WHERE id::TEXT = v_tharavadu_id OR name = v_tharavadu_id;
    END IF;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Trigger on Post Changes (Tag, Moderation, Deletion)
DROP TRIGGER IF EXISTS trg_tharavadu_posts_top_icon ON public.tharavadu_posts;
CREATE TRIGGER trg_tharavadu_posts_top_icon
AFTER INSERT OR UPDATE OF is_tharavadu_tag, is_deleted, is_moderated, likes_count OR DELETE
ON public.tharavadu_posts
FOR EACH ROW
EXECUTE FUNCTION public.fn_sync_tharavadu_top_icon();

-- 6. Trigger on Likes (Increment/Decrement post likes_count)
CREATE OR REPLACE FUNCTION public.fn_handle_tharavadu_like()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.tharavadu_posts
    SET likes_count = likes_count + 1
    WHERE id = NEW.post_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.tharavadu_posts
    SET likes_count = GREATEST(0, likes_count - 1)
    WHERE id = OLD.post_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_tharavadu_likes_count ON public.tharavadu_likes;
CREATE TRIGGER trg_tharavadu_likes_count
AFTER INSERT OR DELETE ON public.tharavadu_likes
FOR EACH ROW
EXECUTE FUNCTION public.fn_handle_tharavadu_like();

-- 7. Row Level Security (RLS) Policies
ALTER TABLE public.tharavadu_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tharavadu_likes ENABLE ROW LEVEL SECURITY;

-- Read policy: Everyone can view non-deleted posts
CREATE POLICY "Public Read Tharavadu Posts"
ON public.tharavadu_posts
FOR SELECT
TO authenticated, anon
USING (is_deleted = FALSE);

-- Insert policy: Only verified members belonging to the clan can post
CREATE POLICY "Verified Clan Members Can Post"
ON public.tharavadu_posts
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.verification_status = 'verified'
      AND (
        p.father_clan_id = tharavadu_posts.tharavadu_id OR
        p.mother_clan_id = tharavadu_posts.tharavadu_id OR
        p.role = 'admin'
      )
  )
);

-- Update policy: Author or Admin can update
CREATE POLICY "Author or Admin Can Update Post"
ON public.tharavadu_posts
FOR UPDATE
TO authenticated
USING (
  author_id = auth.uid() OR 
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Likes policies
CREATE POLICY "Public Read Likes"
ON public.tharavadu_likes
FOR SELECT
TO authenticated, anon
USING (TRUE);

CREATE POLICY "Authenticated Users Can Like"
ON public.tharavadu_likes
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users Can Unlike"
ON public.tharavadu_likes
FOR DELETE
TO authenticated
USING (user_id = auth.uid());
