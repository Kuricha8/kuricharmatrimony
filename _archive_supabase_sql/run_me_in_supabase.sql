-- ==========================================
-- SUPABASE SCHEMA SYNCHRONIZATION SCRIPT
-- ==========================================
-- Please copy and paste this entire script into your Supabase SQL Editor and click "Run".
-- This will ensure ALL tables and columns your app needs exist, and it fixes the PGRST205 errors!

-- Enable uuid-ossp extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Add updated_at column
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 1. FIX MISSING PROFILES COLUMNS
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS full_name TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS age INT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS dob TIMESTAMP;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS photo_url TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS registration_status TEXT DEFAULT 'pending';
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS is_banned BOOLEAN DEFAULT false;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS report_count INT DEFAULT 0;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS subscription_tier TEXT DEFAULT 'Free';
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS allow_photo_in_ads BOOLEAN DEFAULT false;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS gender TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS account_status TEXT DEFAULT 'PENDING_LEAD';
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS q1_response BOOLEAN;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS q2_response BOOLEAN;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS q3_response BOOLEAN;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS q4_response BOOLEAN;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS q5_response BOOLEAN;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS q6_response BOOLEAN;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS q7_response BOOLEAN;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS q8_response BOOLEAN;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS q9_response BOOLEAN;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS q10_response BOOLEAN;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS pref_location TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS pref_occupation TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS delete_requested_at TIMESTAMP WITH TIME ZONE DEFAULT NULL;
-- 11. TRIGGER TO CANCEL DELETE REQUEST ON LOGIN
CREATE OR REPLACE FUNCTION public.cancel_delete_request_on_login()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.last_sign_in_at IS DISTINCT FROM OLD.last_sign_in_at THEN
        UPDATE public.kurichiyar_profiles 
        SET delete_requested_at = NULL 
        WHERE id = NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS cancel_delete_request_on_login_trigger ON auth.users;
CREATE TRIGGER cancel_delete_request_on_login_trigger
    AFTER UPDATE ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.cancel_delete_request_on_login();

-- 12. FUNCTION TO PURGE ACCOUNTS AFTER 7 DAYS
CREATE OR REPLACE FUNCTION public.purge_deleted_accounts_after_7_days()
RETURNS void AS $$
BEGIN
    DELETE FROM public.kurichiyar_profiles 
    WHERE delete_requested_at IS NOT NULL 
    AND delete_requested_at <= NOW() - INTERVAL '7 days';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 12.1 ACTIVE LIVENESS VERIFICATION
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS force_video_verification BOOLEAN DEFAULT false;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS video_verification_status TEXT DEFAULT 'none';
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS liveness_video_url TEXT;

-- 12.2 BROKER & ANTI-SPAM CONTROLS
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS device_id TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS daily_number_views_count INT DEFAULT 0;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS last_number_view_date DATE;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS is_broker_flagged BOOLEAN DEFAULT false;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS admin_call_notes TEXT;

-- 12.3 ADDITIONAL PROFILE DATA FOR ANALYTICS
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS is_out_of_caste BOOLEAN DEFAULT false;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS marital_status TEXT DEFAULT 'never_married';

-- 2. FIX MISSING THARAVAD MASTER COLUMNS
CREATE TABLE IF NOT EXISTS public.tharavad_master (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid()
);
ALTER TABLE public.tharavad_master ADD COLUMN IF NOT EXISTS name_ml TEXT;
ALTER TABLE public.tharavad_master ADD COLUMN IF NOT EXISTS name TEXT;

-- 3. CREATE REGISTRATION FEE SETTINGS TABLE
CREATE TABLE IF NOT EXISTS public.registration_fee_settings (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    fee_amount NUMERIC DEFAULT 0
);
ALTER TABLE public.registration_fee_settings ADD COLUMN IF NOT EXISTS gender TEXT UNIQUE;
ALTER TABLE public.registration_fee_settings ADD COLUMN IF NOT EXISTS validity_months INT DEFAULT 3;
ALTER TABLE public.registration_fee_settings ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.registration_fee_settings ADD COLUMN IF NOT EXISTS reason_text TEXT;
ALTER TABLE public.registration_fee_settings ADD COLUMN IF NOT EXISTS banner_url TEXT;
ALTER TABLE public.registration_fee_settings ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 4. CREATE SUBSCRIPTION PLANS TABLE
CREATE TABLE IF NOT EXISTS public.subscription_plans (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    name TEXT NOT NULL, 
    price NUMERIC DEFAULT 0,
    billing_cycle_months INT NOT NULL DEFAULT 1,
    is_active BOOLEAN DEFAULT true,
    tier_level INT DEFAULT 1,
    description TEXT
);

-- 5. CREATE COMMUNITY HISTORY TABLE
CREATE TABLE IF NOT EXISTS public.community_history (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    title TEXT,
    content TEXT,
    image_url TEXT
);

-- 6. CREATE APP DIALOGUES TABLE
CREATE TABLE IF NOT EXISTS public.app_dialogues (
    id BIGSERIAL PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    dialogue_key TEXT UNIQUE,
    message TEXT
);
ALTER TABLE public.app_dialogues ADD COLUMN IF NOT EXISTS yes_match TEXT;
ALTER TABLE public.app_dialogues ADD COLUMN IF NOT EXISTS no_match TEXT;

-- 7. CREATE APP POLICIES TABLE
CREATE TABLE IF NOT EXISTS public.kurichiyar_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    phone TEXT UNIQUE,
    full_name TEXT,
    age INT,
    region TEXT,
    father_tharavadu TEXT,
    mother_tharavadu TEXT,
    photo_url TEXT,
    registration_status TEXT DEFAULT 'pending',
    is_agent BOOLEAN DEFAULT false,
    referred_by UUID REFERENCES public.kurichiyar_profiles(id)
);

CREATE TABLE IF NOT EXISTS public.user_activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
    action_type TEXT NOT NULL,
    details JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.subscription_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    price NUMERIC NOT NULL,
    duration_days INT NOT NULL,
    features JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Seed initial subscription plans if table is empty
INSERT INTO public.subscription_plans (name, price, duration_days, features)
SELECT 'Free', 0, 36500, '["Basic matches", "Limited messages"]'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.subscription_plans WHERE name = 'Free');

INSERT INTO public.subscription_plans (name, price, duration_days, features)
SELECT 'Silver', 99, 30, '["Advanced matches", "Unlimited messages"]'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.subscription_plans WHERE name = 'Silver');

INSERT INTO public.subscription_plans (name, price, duration_days, features)
SELECT 'Gold', 199, 90, '["Premium AI matches", "Priority support", "Profile highlighting"]'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM public.subscription_plans WHERE name = 'Gold');

CREATE TABLE IF NOT EXISTS public.user_shortlists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
    shortlisted_profile_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    UNIQUE(user_id, shortlisted_profile_id)
);

-- 7.1 CREATE PROFILE MATCHES TABLE
CREATE TABLE IF NOT EXISTS public.profile_matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    receiver_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL CHECK (status IN ('LIKED', 'PASSED', 'REJECTED', 'AGREED', 'MATCHED', 'EXPIRED')),
    interaction_comment TEXT,
    is_bride_parent_verified BOOLEAN DEFAULT false,
    is_groom_parent_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(sender_id, receiver_id)
);

-- 8. CREATE FEATURE SETTINGS TABLE
CREATE TABLE IF NOT EXISTS public.feature_settings (
    feature_name TEXT PRIMARY KEY,
    display_label TEXT,
    is_premium_only BOOLEAN DEFAULT false
);

-- 9. CREATE SUBSCRIPTIONS TABLE
CREATE TABLE IF NOT EXISTS public.subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
    amount_paid NUMERIC NOT NULL,
    plan_name TEXT,
    status TEXT DEFAULT 'ACTIVE',
    order_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 10. RELOAD SCHEMA CACHE
NOTIFY pgrst;

-- 37. NEW VIEWS FOR ADMIN CONSOLE (SMART ROOM & ANALYTICS)
-- ==========================================

CREATE OR REPLACE VIEW public.recently_joined_users AS
SELECT 
    id, 
    full_name, 
    created_at, 
    account_status, 
    registration_status, 
    is_broker_flagged,
    gender
FROM public.kurichiyar_profiles
ORDER BY created_at DESC
LIMIT 50;

CREATE OR REPLACE VIEW public.advanced_app_analytics AS
SELECT 
    (SELECT COUNT(*) FROM public.kurichiyar_profiles WHERE gender = 'female') as total_girls,
    (SELECT COUNT(*) FROM public.kurichiyar_profiles WHERE gender = 'male') as total_boys,
    (SELECT COUNT(*) FROM public.kurichiyar_profiles WHERE is_out_of_caste = true) as total_out_of_caste,
    (SELECT COUNT(*) FROM public.kurichiyar_profiles WHERE marital_status = 'second_marriage') as total_second_marriages,
    (SELECT COUNT(*) FROM public.kurichiyar_profiles WHERE marital_status = 'second_marriage' AND is_out_of_caste = true) as second_marriage_out_of_caste,
    (SELECT COUNT(*) FROM public.kurichiyar_profiles WHERE registration_status = 'approved') as total_audited_profiles;

-- ==========================================
-- 36. NEW TABLES FOR ADMIN CONSOLE (PHASE 4 & 6)
-- ==========================================

-- Payments (for revenue chart)
CREATE TABLE public.payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE SET NULL,
    amount NUMERIC NOT NULL,
    currency VARCHAR(10) DEFAULT 'INR',
    status VARCHAR(50) DEFAULT 'success',
    plan_name VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins can view all payments" ON public.payments FOR SELECT USING (is_admin(auth.uid()));
CREATE POLICY "Users can view own payments" ON public.payments FOR SELECT USING (auth.uid() = user_id);

-- Support Messages (Admin Helpdesk Chat)
CREATE TABLE public.support_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
    admin_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE SET NULL,
    message TEXT NOT NULL,
    is_from_admin BOOLEAN DEFAULT false,
    read_by_admin BOOLEAN DEFAULT false,
    read_by_user BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.support_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view and insert own support messages" ON public.support_messages FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Admins can view and reply to support messages" ON public.support_messages FOR ALL USING (is_admin(auth.uid()));

-- Admin Notifications (Broadcast Center)
CREATE TABLE public.admin_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    target_audience VARCHAR(50) NOT NULL, -- 'all', 'guests', 'vips'
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    delivery_count INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.admin_notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins can manage broadcasts" ON public.admin_notifications FOR ALL USING (is_admin(auth.uid()));
CREATE POLICY "Users can view broadcasts" ON public.admin_notifications FOR SELECT USING (true);

-- 13. CREATE PROFILE CART TABLE
CREATE TABLE IF NOT EXISTS public.profile_cart (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    saved_profile_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, saved_profile_id)
);

-- 14. CREATE PROFILE VIEWS HISTORY TABLE
CREATE TABLE IF NOT EXISTS public.profile_views_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    viewer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    viewed_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
    view_count INT DEFAULT 1,
    last_viewed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(viewer_id, viewed_id)
);

-- 15. TRIGGER TO INCREMENT VIEW COUNT
CREATE OR REPLACE FUNCTION public.log_profile_view()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profile_views_history (viewer_id, viewed_id, view_count, last_viewed_at)
    VALUES (NEW.viewer_id, NEW.viewed_id, 1, NOW())
    ON CONFLICT (viewer_id, viewed_id)
    DO UPDATE SET 
        view_count = public.profile_views_history.view_count + 1,
        last_viewed_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 16. PREMIUM FEATURES
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS is_job_verified BOOLEAN DEFAULT false;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS confidential_photo_url TEXT;

CREATE TABLE IF NOT EXISTS public.one_time_photo_views (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    viewer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    photo_owner_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(viewer_id, photo_owner_id)
);

CREATE TABLE IF NOT EXISTS public.parent_confirmations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id UUID REFERENCES public.profile_matches(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    parent_phone TEXT NOT NULL,
    otp_code TEXT NOT NULL,
    is_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(match_id, user_id)
);

-- 17. ADMIN ONLY MEDIATOR MODE
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS admin_only_mediator BOOLEAN DEFAULT false;

-- 18. ADMIN NOTIFICATIONS (Express Interest + system events)
CREATE TABLE IF NOT EXISTS public.admin_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    receiver_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    type TEXT DEFAULT 'express_interest',
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 19. EXPRESS INTERESTS (for monthly limit tracking)
CREATE TABLE IF NOT EXISTS public.express_interests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    receiver_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(sender_id, receiver_id)
);

-- 20. KEEP-ALIVE AUTOMATED WORKFLOW (4-Day Alert & 5-Day Purge)
CREATE OR REPLACE FUNCTION public.keep_alive_and_purge()
RETURNS json AS $$
DECLARE
    purged_count INT;
    alert_count INT;
BEGIN
    -- 1. 4-DAY ALERT STATE
    -- Change status to 'INACTIVE_ALERT'
    UPDATE public.kurichiyar_profiles
    SET account_status = 'INACTIVE_ALERT'
    WHERE account_status IN ('PENDING_ADMIN_APPROVAL', 'pending')
      AND created_at <= (NOW() - INTERVAL '4 days')
      AND created_at > (NOW() - INTERVAL '5 days');
      
    GET DIAGNOSTICS alert_count = ROW_COUNT;

    -- Insert notifications for agents who own these profiles
    INSERT INTO public.agent_notices (agent_code, message, is_active)
    SELECT agent_code, 'Profile ' || COALESCE(name, 'Guest') || ' has been inactive for 4 days and will be purged tomorrow!', true
    FROM public.kurichiyar_profiles
    WHERE account_status = 'INACTIVE_ALERT'
      AND agent_code IS NOT NULL;

    -- 2. 5-DAY AUTOMATIC PURGE
    DELETE FROM public.kurichiyar_profiles
    WHERE account_status IN ('PENDING_ADMIN_APPROVAL', 'pending', 'INACTIVE_ALERT')
      AND created_at <= (NOW() - INTERVAL '5 days');
      
    GET DIAGNOSTICS purged_count = ROW_COUNT;

    RETURN json_build_object(
        'success', true,
        'alerts_triggered', alert_count,
        'profiles_purged', purged_count,
        'timestamp', NOW()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==========================================
-- 38. CLAN POSTS AND ANALYTICS (PHASE 7)
-- ==========================================

-- Create Clan Posts Table
CREATE TABLE IF NOT EXISTS clan_posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  creator_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create Clan Post Views Table
CREATE TABLE IF NOT EXISTS clan_post_views (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID REFERENCES clan_posts(id) ON DELETE CASCADE,
  viewer_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(post_id, viewer_id)
);

-- Create Clan Post Likes Table
CREATE TABLE IF NOT EXISTS clan_post_likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID REFERENCES clan_posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- Create Clan Post Comments Table
CREATE TABLE IF NOT EXISTS clan_post_comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID REFERENCES clan_posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create User-to-User Chat Messages Table
CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  sender_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
  receiver_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- View for clan posts with stats
CREATE OR REPLACE VIEW user_clan_posts_with_stats AS
SELECT 
  cp.id,
  cp.creator_id,
  cp.content,
  cp.image_url,
  cp.created_at,
  (SELECT COUNT(*) FROM clan_post_views WHERE post_id = cp.id) as views_count,
  (SELECT COUNT(*) FROM clan_post_likes WHERE post_id = cp.id) as likes_count,
  (SELECT COUNT(*) FROM clan_post_comments WHERE post_id = cp.id) as comments_count
FROM clan_posts cp;

-- View for clan post view demographics
CREATE OR REPLACE VIEW clan_post_views_demographics AS
SELECT 
  cpv.post_id,
  cpv.viewer_id,
  cpv.created_at as view_time,
  p.gender,
  p.region,
  p.job,
  p.age,
  p.father_clan_id,
  p.mother_clan_id,
  p.is_out_of_caste
FROM clan_post_views cpv
JOIN public.kurichiyar_profiles p ON cpv.viewer_id = p.id;

-- Dropped Lead / Incomplete Registration Tracking Table
CREATE TABLE IF NOT EXISTS public.incomplete_registrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name TEXT NOT NULL,
    phone_number TEXT NOT NULL,
    verification_status TEXT DEFAULT 'Pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS Policies for incomplete_registrations
ALTER TABLE public.incomplete_registrations ENABLE ROW LEVEL SECURITY;

-- Allow anonymous inserts (from registration wizard)
CREATE POLICY "Allow anon insert to incomplete_registrations"
ON public.incomplete_registrations
FOR INSERT TO anon
WITH CHECK (true);

-- Allow authenticated users to update/delete their own if needed (though we'll use anon/service role mostly)
CREATE POLICY "Allow anon update to incomplete_registrations"
ON public.incomplete_registrations
FOR UPDATE TO anon
USING (true);

CREATE POLICY "Allow anon delete to incomplete_registrations"
ON public.incomplete_registrations
FOR DELETE TO anon
USING (true);

-- Allow admins to select
CREATE POLICY "Allow admins select on incomplete_registrations"
ON public.incomplete_registrations
FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.kurichiyar_profiles 
        WHERE id = auth.uid() AND role = 'admin'
    )
);

-- ==========================================
-- 41. REWARD CONVERSION (CASHOUT) RPC
-- ==========================================

CREATE OR REPLACE FUNCTION request_agent_cashout(p_agent_id UUID, p_points_redeemed NUMERIC, p_cash_value NUMERIC)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_current_points NUMERIC;
BEGIN
    -- 1. Check if agent exists and get current points
    SELECT total_points INTO v_current_points
    FROM public.agent_rewards
    WHERE agent_id = p_agent_id
    FOR UPDATE; -- Lock row to prevent race conditions

    IF v_current_points IS NULL THEN
        RAISE EXCEPTION 'Agent wallet not found';
    END IF;

    IF v_current_points < p_points_redeemed THEN
        RAISE EXCEPTION 'Insufficient points balance';
    END IF;

    -- 2. Deduct points
    UPDATE public.agent_rewards
    SET total_points = total_points - p_points_redeemed
    WHERE agent_id = p_agent_id;

    -- 3. Insert DEBIT record in history
    INSERT INTO public.agent_reward_history(agent_id, points, transaction_type, description)
    VALUES (p_agent_id, p_points_redeemed, 'DEBIT', 'Cashout requested for ₹' || p_cash_value);

    -- 4. Insert into cashout requests
    INSERT INTO public.agent_cashout_requests(agent_id, points_redeemed, cash_value, status)
    VALUES (p_agent_id, p_points_redeemed, p_cash_value, 'PENDING');

    RETURN TRUE;
END;
$$;

-- ==========================================
-- 42. USER SETTINGS TABLE
-- ==========================================

CREATE TABLE IF NOT EXISTS public.user_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
    app_language TEXT DEFAULT 'ENGLISH' CHECK (app_language IN ('ENGLISH', 'MALAYALAM', 'HINDI')),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    UNIQUE(user_id)
);

ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own settings"
ON public.user_settings
FOR ALL TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- ==========================================
-- FEATURE: AUTOMATED MOTIVATION MESSAGING
-- ==========================================

-- 1. Create table for system settings to store Malayalam text
CREATE TABLE IF NOT EXISTS public.system_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key TEXT UNIQUE NOT NULL,
    value TEXT NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default Malayalam motivation message if it doesn't exist
INSERT INTO public.system_settings (key, value)
VALUES 
('motivation_title', 'പ്രത്യേക അറിയിപ്പ്!'),
('motivation_message', 'നിങ്ങളുടെ ജീവിതപങ്കാളിയെ കണ്ടെത്താൻ ഇന്നുതന്നെ പ്രീമിയം അക്കൗണ്ട് എടുക്കൂ!')
ON CONFLICT (key) DO NOTHING;

-- 2. Create motivation messages queue table
CREATE TABLE IF NOT EXISTS public.motivation_messages_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
    scheduled_at TIMESTAMP WITH TIME ZONE NOT NULL,
    sent_at TIMESTAMP WITH TIME ZONE,
    status TEXT DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'SENT', 'FAILED')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. RPC Function to Schedule Motivation Messages (Enforce 1-hour gap)
CREATE OR REPLACE FUNCTION public.fn_schedule_motivation_messages()
RETURNS void AS $$
DECLARE
    last_scheduled_time TIMESTAMP WITH TIME ZONE;
    eligible_user RECORD;
    next_schedule_time TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Find the latest scheduled time in the queue that is >= NOW()
    SELECT MAX(scheduled_at) INTO last_scheduled_time 
    FROM public.motivation_messages_queue 
    WHERE scheduled_at >= NOW();
    
    IF last_scheduled_time IS NULL THEN
        last_scheduled_time := NOW();
    END IF;

    -- Loop through free users who don't already have a pending message
    FOR eligible_user IN 
        SELECT id FROM public.kurichiyar_profiles 
        WHERE (subscription_tier = 'free' OR subscription_tier IS NULL)
        AND id NOT IN (
            SELECT user_id FROM public.motivation_messages_queue WHERE status = 'PENDING'
        )
        LIMIT 50 -- Batch size
    LOOP
        -- Add 1 hour to the last scheduled time
        next_schedule_time := last_scheduled_time + INTERVAL '1 hour';
        
        INSERT INTO public.motivation_messages_queue (user_id, scheduled_at, status)
        VALUES (eligible_user.id, next_schedule_time, 'PENDING');
        
        last_scheduled_time := next_schedule_time;
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. RPC Function to Dispatch (Move from PENDING to SENT) and create User Notifications
CREATE OR REPLACE FUNCTION public.fn_dispatch_motivation_messages()
RETURNS void AS $$
DECLARE
    msg_title TEXT;
    msg_body TEXT;
    queue_item RECORD;
BEGIN
    -- Fetch the configured Malayalam text
    SELECT value INTO msg_title FROM public.system_settings WHERE key = 'motivation_title';
    SELECT value INTO msg_body FROM public.system_settings WHERE key = 'motivation_message';

    FOR queue_item IN
        SELECT id, user_id FROM public.motivation_messages_queue
        WHERE status = 'PENDING' AND scheduled_at <= NOW()
    LOOP
        -- Create a notification for the user
        INSERT INTO public.user_notifications (user_id, title, message, is_read, created_at)
        VALUES (queue_item.user_id, msg_title, msg_body, false, NOW());
        
        -- Mark queue item as SENT
        UPDATE public.motivation_messages_queue
        SET status = 'SENT', sent_at = NOW()
        WHERE id = queue_item.id;
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Admin Custom Ads Table
CREATE TABLE IF NOT EXISTS admin_custom_ads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    image_url TEXT NOT NULL,
    redirect_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE admin_custom_ads ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read access" ON admin_custom_ads FOR SELECT USING (true);
CREATE POLICY "Admin full access" ON admin_custom_ads FOR ALL USING (auth.uid() IN (SELECT id FROM kurichiyar_profiles WHERE role = 'admin'));

CREATE TABLE IF NOT EXISTS public.admin_app_settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
