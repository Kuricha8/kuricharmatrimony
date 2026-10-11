-- ==============================================================================
-- DYNAMIC THARAVADU DP LOGIC BASED ON TOP-LIKED POSTS
-- ==============================================================================

-- 1. Function to retrieve the current dynamic DP for a Tharavadu
CREATE OR REPLACE FUNCTION public.get_tharavadu_dynamic_dp(
    p_clan_id INT, 
    p_viewer_id UUID DEFAULT NULL
)
RETURNS TABLE (
    image_url TEXT,
    post_id UUID,
    like_count INT,
    is_member_visible BOOLEAN
) AS $$
DECLARE
    v_is_member BOOLEAN := false;
BEGIN
    -- Check if viewer is a verified member of this clan or admin
    IF p_viewer_id IS NOT NULL THEN
        SELECT EXISTS (
            SELECT 1 FROM public.kurichiyar_profiles
            WHERE id = p_viewer_id 
              AND (
                mother_clan_id = p_clan_id 
                OR father_clan_id = p_clan_id 
                OR role IN ('admin', 'super_admin', 'administrator', 'system')
                OR is_admin = true
              )
        ) INTO v_is_member;
    END IF;

    -- If not a clan member, DP visibility is restricted to clan members only
    IF NOT v_is_member THEN
        RETURN QUERY SELECT NULL::TEXT, NULL::UUID, 0::INT, false;
        RETURN;
    END IF;

    -- Query top-liked photo post from tharavadu_feed_posts (Tie-breaker: created_at ASC)
    RETURN QUERY
    SELECT 
        p.media_url::TEXT,
        p.id AS post_id,
        COALESCE(p.likes_count, p.likes, 0)::INT AS like_count,
        true AS is_member_visible
    FROM public.tharavadu_feed_posts p
    WHERE (p.clan_id = p_clan_id OR p.tharavadu_id = p_clan_id::text)
      AND p.media_url IS NOT NULL 
      AND p.media_url != ''
      AND COALESCE(p.is_video, false) = false
      AND COALESCE(p.media_type, 'photo') != 'video'
    ORDER BY COALESCE(p.likes_count, p.likes, 0) DESC, p.created_at ASC
    LIMIT 1;

    -- Fallback to tharavadu_posts if no feed post found
    IF NOT FOUND THEN
        RETURN QUERY
        SELECT 
            tp.media_url::TEXT,
            tp.id AS post_id,
            COALESCE(tp.likes_count, tp.likes, 0)::INT AS like_count,
            true AS is_member_visible
        FROM public.tharavadu_posts tp
        WHERE (tp.clan_id = p_clan_id OR tp.tharavadu_id = p_clan_id::text)
          AND tp.media_url IS NOT NULL 
          AND tp.media_url != ''
          AND COALESCE(tp.is_video, false) = false
          AND COALESCE(tp.media_type, 'photo') != 'video'
        ORDER BY COALESCE(tp.likes_count, tp.likes, 0) DESC, tp.created_at ASC
        LIMIT 1;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Trigger Function: Sync Tharavadu DP when a post is updated, deleted, or liked
CREATE OR REPLACE FUNCTION public.sync_tharavadu_top_dp()
RETURNS TRIGGER AS $$
DECLARE
    v_clan_id INT;
    v_top_image TEXT;
    v_top_id UUID;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_clan_id := COALESCE(OLD.clan_id, (OLD.tharavadu_id)::INT, 0);
    ELSE
        v_clan_id := COALESCE(NEW.clan_id, (NEW.tharavadu_id)::INT, 0);
    END IF;

    IF v_clan_id > 0 THEN
        -- Find the new highest-liked photo (with created_at ASC tie-breaker)
        SELECT media_url, id INTO v_top_image, v_top_id
        FROM public.tharavadu_feed_posts
        WHERE (clan_id = v_clan_id OR tharavadu_id = v_clan_id::text)
          AND media_url IS NOT NULL 
          AND media_url != ''
          AND COALESCE(is_video, false) = false
          AND COALESCE(media_type, 'photo') != 'video'
        ORDER BY COALESCE(likes_count, likes, 0) DESC, created_at ASC
        LIMIT 1;

        -- Update the clan's top photo in kurichiyar_clans
        UPDATE public.kurichiyar_clans
        SET 
            image_url = v_top_image,
            profile_image_url = v_top_image,
            icon_url = v_top_image,
            icon_post_id = v_top_id,
            updated_at = NOW()
        WHERE id = v_clan_id;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Attach Triggers to automatic photo updates / deletions
DROP TRIGGER IF EXISTS trigger_sync_tharavadu_dp_on_feed ON public.tharavadu_feed_posts;
CREATE TRIGGER trigger_sync_tharavadu_dp_on_feed
AFTER INSERT OR UPDATE OR DELETE ON public.tharavadu_feed_posts
FOR EACH ROW EXECUTE FUNCTION public.sync_tharavadu_top_dp();
