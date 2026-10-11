-- ============================================================================
-- KURICHIYAR MATRIMONY - PHASE 3 HIGH-VALUE FEATURE ROADMAP DATABASE SCHEMA
-- ============================================================================

-- 1. SHORTLISTED / STARRED PROFILES TABLE
CREATE TABLE IF NOT EXISTS public.profile_shortlists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
    shortlisted_profile_id UUID NOT NULL REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_user_shortlist UNIQUE (user_id, shortlisted_profile_id)
);

-- RLS for Shortlists
ALTER TABLE public.profile_shortlists ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own shortlists"
    ON public.profile_shortlists
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 2. PROFILE VISITORS TRACKING TABLE
CREATE TABLE IF NOT EXISTS public.profile_views_history_explicit (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    viewer_id UUID NOT NULL REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
    viewed_id UUID NOT NULL REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
    view_count INT DEFAULT 1,
    last_viewed_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_viewer_viewed UNIQUE (viewer_id, viewed_id)
);

-- RLS for Profile Visitors
ALTER TABLE public.profile_views_history_explicit ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view profile visitors of their own profile"
    ON public.profile_views_history_explicit
    FOR SELECT
    USING (auth.uid() = viewed_id OR auth.uid() = viewer_id);

CREATE POLICY "Users can record a view"
    ON public.profile_views_history_explicit
    FOR INSERT
    WITH CHECK (auth.uid() = viewer_id);

-- Stored Procedure to Log Profile View
CREATE OR REPLACE FUNCTION public.log_profile_view(
    p_viewer_id UUID,
    p_viewed_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF p_viewer_id = p_viewed_id THEN
        RETURN; -- Do not log self views
    END IF;

    INSERT INTO public.profile_views_history_explicit (viewer_id, viewed_id, view_count, last_viewed_at)
    VALUES (p_viewer_id, p_viewed_id, 1, NOW())
    ON CONFLICT (viewer_id, viewed_id)
    DO UPDATE SET 
        view_count = public.profile_views_history_explicit.view_count + 1,
        last_viewed_at = NOW();
END;
$$;

-- 3. SMART MATCH SCORE CALCULATION RPC (Includes Tharavadu Exogamy Rules)
CREATE OR REPLACE FUNCTION public.calculate_smart_match_score(
    p1_id UUID,
    p2_id UUID
)
RETURNS TABLE (
    match_score INT,
    is_exogamous_valid BOOLEAN,
    tharavadu_compatibility_reason TEXT,
    age_score INT,
    education_score INT,
    location_score INT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_p1 public.kurichiyar_profiles%ROWTYPE;
    v_p2 public.kurichiyar_profiles%ROWTYPE;
    v_total_score INT := 0;
    v_exogamous BOOLEAN := TRUE;
    v_reason TEXT := 'Valid Clan Exogamy';
    v_age_diff INT := 0;
    v_age_pts INT := 25;
    v_edu_pts INT := 20;
    v_loc_pts INT := 15;
BEGIN
    SELECT * INTO v_p1 FROM public.kurichiyar_profiles WHERE id = p1_id;
    SELECT * INTO v_p2 FROM public.kurichiyar_profiles WHERE id = p2_id;

    IF v_p1 IS NULL OR v_p2 IS NULL THEN
        RETURN QUERY SELECT 0, FALSE, 'Profile not found'::TEXT, 0, 0, 0;
        RETURN;
    END IF;

    -- THARAVADU EXOGAMY CHECK (Same Father Clan or Ineligible Clan Union = 0% Match)
    IF v_p1.father_clan IS NOT NULL AND v_p2.father_clan IS NOT NULL 
       AND LOWER(TRIM(v_p1.father_clan)) = LOWER(TRIM(v_p2.father_clan)) THEN
        v_exogamous := FALSE;
        v_reason := 'Same Tharavadu/Father Clan (Exogamy Violation - Sagothara Clan)';
        RETURN QUERY SELECT 0, FALSE, v_reason, 0, 0, 0;
        RETURN;
    END IF;

    -- Baseline Exogamy Score (40 Points)
    v_total_score := 40;

    -- AGE MATCH SCORE (Max 25 Points)
    v_age_diff := ABS(COALESCE(v_p1.age, 25) - COALESCE(v_p2.age, 25));
    IF v_age_diff BETWEEN 1 AND 4 THEN
        v_age_pts := 25;
    ELSIF v_age_diff BETWEEN 5 AND 7 THEN
        v_age_pts := 18;
    ELSIF v_age_diff BETWEEN 8 AND 10 THEN
        v_age_pts := 10;
    ELSE
        v_age_pts := 5;
    END IF;
    v_total_score := v_total_score + v_age_pts;

    -- EDUCATION MATCH SCORE (Max 20 Points)
    IF LOWER(TRIM(COALESCE(v_p1.education, ''))) = LOWER(TRIM(COALESCE(v_p2.education, ''))) THEN
        v_edu_pts := 20;
    ELSIF v_p1.education IS NOT NULL AND v_p2.education IS NOT NULL THEN
        v_edu_pts := 12;
    ELSE
        v_edu_pts := 5;
    END IF;
    v_total_score := v_total_score + v_edu_pts;

    -- LOCATION MATCH SCORE (Max 15 Points)
    IF LOWER(TRIM(COALESCE(v_p1.district, ''))) = LOWER(TRIM(COALESCE(v_p2.district, ''))) THEN
        v_loc_pts := 15;
    ELSIF LOWER(TRIM(COALESCE(v_p1.state, ''))) = LOWER(TRIM(COALESCE(v_p2.state, ''))) THEN
        v_loc_pts := 10;
    ELSE
        v_loc_pts := 5;
    END IF;
    v_total_score := v_total_score + v_loc_pts;

    RETURN QUERY SELECT 
        LEAST(v_total_score, 100) AS match_score,
        v_exogamous AS is_exogamous_valid,
        v_reason AS tharavadu_compatibility_reason,
        v_age_pts AS age_score,
        v_edu_pts AS education_score,
        v_loc_pts AS location_score;
END;
$$;

-- 4. AUTOMATED DAILY MATCHES DIGEST QUEUE
CREATE TABLE IF NOT EXISTS public.daily_match_digest_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
    recommended_profile_ids JSONB NOT NULL,
    scheduled_for DATE DEFAULT CURRENT_DATE,
    status VARCHAR(20) DEFAULT 'PENDING', -- PENDING, SENT, FAILED
    sent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_user_daily_digest UNIQUE (user_id, scheduled_for)
);

-- 5. ADMIN DASHBOARD ANALYTICS STORED PROCEDURE
CREATE OR REPLACE FUNCTION public.get_admin_dashboard_metrics()
RETURNS TABLE (
    daily_active_users INT,
    total_unlock_revenue NUMERIC,
    pending_verifications_count INT,
    open_tickets_count INT,
    avg_ticket_resolution_hours NUMERIC
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_dau INT := 0;
    v_revenue NUMERIC := 0.00;
    v_pending_verifications INT := 0;
    v_tickets INT := 0;
    v_avg_hours NUMERIC := 0.00;
BEGIN
    -- DAU (Active in past 24h)
    SELECT COUNT(DISTINCT id) INTO v_dau 
    FROM public.kurichiyar_profiles 
    WHERE last_seen_at >= NOW() - INTERVAL '24 hours';

    -- Revenue from ₹49 Contact Unlocks & Subscriptions
    SELECT COALESCE(SUM(amount), 0.00) INTO v_revenue 
    FROM public.payments 
    WHERE status = 'SUCCESS';

    -- Pending Verifications
    SELECT COUNT(*) INTO v_pending_verifications 
    FROM public.kurichiyar_profiles 
    WHERE verification_status = 'PENDING';

    -- Open Support Tickets
    SELECT COUNT(*) INTO v_tickets 
    FROM public.issue_reports 
    WHERE status = 'OPEN';

    -- Average Resolution Hours for Support Tickets
    SELECT COALESCE(AVG(EXTRACT(EPOCH FROM (updated_at - created_at)) / 3600), 0.0) INTO v_avg_hours
    FROM public.issue_reports
    WHERE status = 'RESOLVED';

    RETURN QUERY SELECT 
        v_dau,
        v_revenue,
        v_pending_verifications,
        v_tickets,
        ROUND(v_avg_hours, 1);
END;
$$;
