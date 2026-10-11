-- Create profile_views_history table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.profile_views_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    viewer_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
    viewed_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
    view_count INT DEFAULT 1,
    last_viewed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(viewer_id, viewed_id)
);

-- Enable RLS
ALTER TABLE public.profile_views_history ENABLE ROW LEVEL SECURITY;

-- Allow users to read their own views (who they viewed, or who viewed them)
CREATE POLICY "Allow users to read their own view history"
    ON public.profile_views_history FOR SELECT
    USING (auth.uid() = viewer_id OR auth.uid() = viewed_id);

-- Admins can read everything
CREATE POLICY "Admins can read all view history"
    ON public.profile_views_history FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.kurichiyar_profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Create RPC to securely record profile views
CREATE OR REPLACE FUNCTION record_profile_view(p_viewer_id UUID, p_viewed_id UUID)
RETURNS void AS $$
BEGIN
    -- Only allow if the caller is the actual viewer
    IF auth.uid() != p_viewer_id THEN
        RAISE EXCEPTION 'Unauthorized view tracking';
    END IF;

    -- Prevent self-view tracking
    IF p_viewer_id = p_viewed_id THEN
        RETURN;
    END IF;

    INSERT INTO public.profile_views_history (viewer_id, viewed_id, view_count, last_viewed_at)
    VALUES (p_viewer_id, p_viewed_id, 1, NOW())
    ON CONFLICT (viewer_id, viewed_id)
    DO UPDATE SET 
        view_count = profile_views_history.view_count + 1,
        last_viewed_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
