-- SQL Script to Permanently Purge User Profiles from Supabase Auth & Public Database Tables

-- Drop previous function signatures to prevent parameter name change errors (Error 42P13)
DROP FUNCTION IF EXISTS delete_user_completely(UUID) CASCADE;
DROP FUNCTION IF EXISTS delete_user_permanently(UUID) CASCADE;
DROP FUNCTION IF EXISTS admin_delete_user(UUID) CASCADE;
DROP FUNCTION IF EXISTS delete_user_profile(UUID) CASCADE;
DROP FUNCTION IF EXISTS admin_delete_user_profile(UUID) CASCADE;

CREATE OR REPLACE FUNCTION delete_user_completely(target_user_id UUID)
RETURNS void AS $$
BEGIN
    -- 1. Financial & Subscription Tables
    BEGIN DELETE FROM payments WHERE user_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM manual_payments WHERE user_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM subscriptions WHERE user_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM user_subscriptions WHERE user_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM hide_profile_subscriptions WHERE user_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM hide_profile_logs WHERE user_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;

    -- 2. Agent & Referral Tables
    BEGIN DELETE FROM agent_reward_history WHERE agent_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM agent_rewards WHERE agent_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM agent_cashout_requests WHERE agent_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM agents WHERE id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;

    -- 3. Social, Feed, Posts & Comments
    BEGIN DELETE FROM clan_post_comments WHERE user_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM clan_post_likes WHERE user_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM clan_post_views WHERE user_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM clan_posts WHERE creator_id = target_user_id OR user_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM clan_feed_comments WHERE user_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM clan_feed_likes WHERE user_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM clan_feed_posts WHERE creator_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM clan_poster_suggestions WHERE user_id = target_user_id OR suggested_by = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;

    -- 4. Matching, Cart, Shortlist & Activity
    BEGIN DELETE FROM profile_cart WHERE user_id = target_user_id OR shortlisted_profile_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM user_shortlists WHERE user_id = target_user_id OR shortlisted_profile_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM shortlist WHERE user_id = target_user_id OR shortlisted_profile_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM profile_matches WHERE user_id = target_user_id OR target_user_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM saved_matches WHERE user_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM express_interests WHERE sender_id = target_user_id OR receiver_id = target_user_id OR user_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM profile_views_history WHERE viewer_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM one_time_photo_views WHERE viewer_id = target_user_id OR owner_id = target_user_id OR user_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM user_activity_logs WHERE user_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM tharavadu_photo_requests WHERE user_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;

    -- 5. Messaging, Calls, Reports & Notifications
    BEGIN DELETE FROM chat_messages WHERE sender_id = target_user_id OR receiver_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM webrtc_calls WHERE caller_id = target_user_id OR receiver_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM calls WHERE caller_id = target_user_id OR receiver_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM post_reports WHERE reporter_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM notifications WHERE user_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM admin_notifications WHERE user_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM likes WHERE user_id = target_user_id OR liked_user_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM banned_users WHERE user_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM disputes WHERE user_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM parent_confirmations WHERE user_id = target_user_id OR parent_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM support_messages WHERE user_id = target_user_id OR sender_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;

    -- 6. Core Profile & Auth System Purge
    BEGIN DELETE FROM incomplete_registrations WHERE id = target_user_id OR user_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM profile_corrections WHERE user_id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM kurichiyar_profiles WHERE id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM user_profiles WHERE user_id = target_user_id OR id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM auth.users WHERE id = target_user_id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Aliases for full backwards and RPC compatibility
CREATE OR REPLACE FUNCTION admin_delete_user(target_user_id UUID)
RETURNS void AS $$
BEGIN
    PERFORM delete_user_completely(target_user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION delete_user_permanently(target_user_id UUID)
RETURNS void AS $$
BEGIN
    PERFORM delete_user_completely(target_user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION delete_user_profile(target_user_id UUID)
RETURNS void AS $$
BEGIN
    PERFORM delete_user_completely(target_user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION admin_delete_user_profile(target_user_id UUID)
RETURNS void AS $$
BEGIN
    PERFORM delete_user_completely(target_user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ensure Admins have RLS rights on kurichiyar_profiles
DO $$
BEGIN
    DROP POLICY IF EXISTS "Admins can delete profiles" ON kurichiyar_profiles;
    
    CREATE POLICY "Admins can delete profiles" 
    ON kurichiyar_profiles 
    FOR DELETE
    USING (true);
END;
$$;

-- 7. Database Engine Trigger for Automatic Cascading Deletion
CREATE OR REPLACE FUNCTION trigger_cascade_user_deletion()
RETURNS TRIGGER AS $$
BEGIN
    BEGIN DELETE FROM payments WHERE user_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM subscriptions WHERE user_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM user_subscriptions WHERE user_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM hide_profile_subscriptions WHERE user_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM hide_profile_logs WHERE user_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM agent_reward_history WHERE agent_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM agent_rewards WHERE agent_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM agent_cashout_requests WHERE agent_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM agents WHERE id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM clan_post_comments WHERE user_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM clan_post_likes WHERE user_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM clan_post_views WHERE user_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM clan_posts WHERE creator_id = OLD.id OR user_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM clan_feed_comments WHERE user_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM clan_feed_likes WHERE user_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM clan_feed_posts WHERE creator_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM clan_poster_suggestions WHERE user_id = OLD.id OR suggested_by = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM profile_cart WHERE user_id = OLD.id OR shortlisted_profile_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM user_shortlists WHERE user_id = OLD.id OR shortlisted_profile_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM shortlist WHERE user_id = OLD.id OR shortlisted_profile_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM profile_matches WHERE user_id = OLD.id OR target_user_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM saved_matches WHERE user_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM express_interests WHERE sender_id = OLD.id OR receiver_id = OLD.id OR user_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM profile_views_history WHERE viewer_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM one_time_photo_views WHERE viewer_id = OLD.id OR owner_id = OLD.id OR user_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM user_activity_logs WHERE user_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM tharavadu_photo_requests WHERE user_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM chat_messages WHERE sender_id = OLD.id OR receiver_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM webrtc_calls WHERE caller_id = OLD.id OR receiver_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM calls WHERE caller_id = OLD.id OR receiver_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM post_reports WHERE reporter_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM notifications WHERE user_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM admin_notifications WHERE user_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM likes WHERE user_id = OLD.id OR liked_user_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM banned_users WHERE user_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM disputes WHERE user_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM parent_confirmations WHERE user_id = OLD.id OR parent_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM support_messages WHERE user_id = OLD.id OR sender_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM incomplete_registrations WHERE id = OLD.id OR user_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    BEGIN DELETE FROM profile_corrections WHERE user_id = OLD.id; EXCEPTION WHEN undefined_table OR undefined_column THEN NULL; END;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_cascade_user_deletion_profiles ON public.kurichiyar_profiles;
CREATE TRIGGER trg_cascade_user_deletion_profiles
BEFORE DELETE ON public.kurichiyar_profiles
FOR EACH ROW EXECUTE FUNCTION trigger_cascade_user_deletion();

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'users') THEN
        DROP TRIGGER IF EXISTS trg_cascade_user_deletion_auth ON auth.users;
        CREATE TRIGGER trg_cascade_user_deletion_auth
        BEFORE DELETE ON auth.users
        FOR EACH ROW EXECUTE FUNCTION trigger_cascade_user_deletion();
    END IF;
END $$;
