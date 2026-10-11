-- =========================================================================
-- SECURITY MIGRATION: FIX AUTH_USERS_EXPOSED (SUPABASE SECURITY LINTER FIX)
-- =========================================================================

-- 1. Explicitly drop the exposed public view if it exists
DROP VIEW IF EXISTS public.auth_users_exposed CASCADE;

-- 2. Revoke any residual permissions on the view name across all roles
DO $$
BEGIN
    EXECUTE 'REVOKE ALL ON TABLE public.auth_users_exposed FROM PUBLIC, anon, authenticated';
EXCEPTION WHEN OTHERS THEN
    -- Ignore error if relation does not exist
    NULL;
END $$;

-- 3. Ensure all public views enforce security_invoker = true
-- (This prevents public views from bypassing Row Level Security policies on underlying tables)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_views WHERE schemaname = 'public' AND viewname = 'guest_profiles_feed') THEN
        ALTER VIEW public.guest_profiles_feed SET (security_invoker = true);
    END IF;
    IF EXISTS (SELECT 1 FROM pg_views WHERE schemaname = 'public' AND viewname = 'recently_joined_users') THEN
        ALTER VIEW public.recently_joined_users SET (security_invoker = true);
    END IF;
    IF EXISTS (SELECT 1 FROM pg_views WHERE schemaname = 'public' AND viewname = 'admin_dashboard_metrics') THEN
        ALTER VIEW public.admin_dashboard_metrics SET (security_invoker = true);
    END IF;
    IF EXISTS (SELECT 1 FROM pg_views WHERE schemaname = 'public' AND viewname = 'four_room_compatible_matches') THEN
        ALTER VIEW public.four_room_compatible_matches SET (security_invoker = true);
    END IF;
END $$;

-- 4. Force PostgREST schema cache reload
NOTIFY pgrst, 'reload schema';
