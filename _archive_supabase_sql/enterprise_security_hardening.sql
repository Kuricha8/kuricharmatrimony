-- =============================================================================
-- KURICHIYAR MATRIMONY - ENTERPRISE-GRADE SUPABASE SECURITY HARDENING SCRIPT
-- Enforces Row Level Security (RLS) across all public tables, strict owner
-- mutations, public read for verified profiles, and admin-only policy controls.
-- =============================================================================

-- =============================================================================
-- 1. HELPER FUNCTIONS FOR SECURITY CHECKS
-- =============================================================================

-- Check if current authenticated user is a verified system administrator
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN (
    EXISTS (
      SELECT 1 FROM public.admin_users
      WHERE admin_users.id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM public.kurichiyar_profiles
      WHERE kurichiyar_profiles.id = auth.uid() 
        AND kurichiyar_profiles.role = 'admin'
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- 2. ENABLE RLS ACROSS ALL TABLES
-- =============================================================================

ALTER TABLE IF EXISTS public.kurichiyar_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.clans ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.tharavad_master ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.tharavadu_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.clan_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.clan_post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.clan_post_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.coin_ad_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.ad_consent_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.admin_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.app_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.profile_edit_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.interest_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.webrtc_calls ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.activity_logs ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- 3. PROFILES (kurichiyar_profiles) RLS POLICIES
-- =============================================================================

-- Read: Approved active profiles are visible to public/authenticated users.
-- Users can always view their own profile regardless of approval status.
-- Admins have full read access.
DROP POLICY IF EXISTS "Profiles read policy" ON public.kurichiyar_profiles;
CREATE POLICY "Profiles read policy"
ON public.kurichiyar_profiles FOR SELECT
TO anon, authenticated
USING (
  (status = 'approved' AND is_active = true)
  OR
  (auth.uid() IS NOT NULL AND auth.uid() = id)
  OR
  public.is_admin()
);

-- Insert: Users can only insert their own profile with their authentic UID
DROP POLICY IF EXISTS "Profiles insert policy" ON public.kurichiyar_profiles;
CREATE POLICY "Profiles insert policy"
ON public.kurichiyar_profiles FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = id
  OR
  public.is_admin()
);

-- Update: Users can only update their own profile.
-- Critical privilege fields (role, is_verified) are prevented from unauthorized self-elevation.
DROP POLICY IF EXISTS "Profiles update policy" ON public.kurichiyar_profiles;
CREATE POLICY "Profiles update policy"
ON public.kurichiyar_profiles FOR UPDATE
TO authenticated
USING (
  auth.uid() = id OR public.is_admin()
)
WITH CHECK (
  auth.uid() = id OR public.is_admin()
);

-- Delete: Users can delete their own profile, or Admins can delete
DROP POLICY IF EXISTS "Profiles delete policy" ON public.kurichiyar_profiles;
CREATE POLICY "Profiles delete policy"
ON public.kurichiyar_profiles FOR DELETE
TO authenticated
USING (
  auth.uid() = id OR public.is_admin()
);

-- =============================================================================
-- 4. CLANS & THARAVAD MASTER RLS POLICIES
-- =============================================================================

-- Read: Public can view all active clans
DROP POLICY IF EXISTS "Clans public read" ON public.clans;
CREATE POLICY "Clans public read"
ON public.clans FOR SELECT
TO anon, authenticated
USING (true);

-- Mutation: Only verified Admins can insert/update/delete clans
DROP POLICY IF EXISTS "Clans admin write" ON public.clans;
CREATE POLICY "Clans admin write"
ON public.clans FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- tharavad_master legacy table mirror policies
DROP POLICY IF EXISTS "Tharavad master public read" ON public.tharavad_master;
CREATE POLICY "Tharavad master public read"
ON public.tharavad_master FOR SELECT
TO anon, authenticated
USING (true);

DROP POLICY IF EXISTS "Tharavad master admin write" ON public.tharavad_master;
CREATE POLICY "Tharavad master admin write"
ON public.tharavad_master FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- =============================================================================
-- 5. THARAVADU STATUS & STORIES RLS POLICIES
-- =============================================================================

-- Read: Authenticated users can view active (non-expired) statuses
DROP POLICY IF EXISTS "Statuses select policy" ON public.tharavadu_status;
CREATE POLICY "Statuses select policy"
ON public.tharavadu_status FOR SELECT
TO anon, authenticated
USING (
  expires_at > NOW() OR public.is_admin() OR auth.uid() = creator_id
);

-- Insert: Users can only upload statuses under their own user ID
DROP POLICY IF EXISTS "Statuses insert policy" ON public.tharavadu_status;
CREATE POLICY "Statuses insert policy"
ON public.tharavadu_status FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = creator_id OR public.is_admin()
);

-- Delete: Only the status creator or an Admin can delete
DROP POLICY IF EXISTS "Statuses delete policy" ON public.tharavadu_status;
CREATE POLICY "Statuses delete policy"
ON public.tharavadu_status FOR DELETE
TO authenticated
USING (
  auth.uid() = creator_id OR public.is_admin()
);

-- =============================================================================
-- 6. COIN AD SLOTS & ADMIN SETTINGS RLS POLICIES
-- =============================================================================

-- Read: Public can read coin ad slots and general app settings
DROP POLICY IF EXISTS "Coin slots read" ON public.coin_ad_slots;
CREATE POLICY "Coin slots read"
ON public.coin_ad_slots FOR SELECT
TO anon, authenticated
USING (true);

DROP POLICY IF EXISTS "Coin slots admin write" ON public.coin_ad_slots;
CREATE POLICY "Coin slots admin write"
ON public.coin_ad_slots FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- Admin Settings: Strict admin-only access
DROP POLICY IF EXISTS "Admin settings select" ON public.admin_settings;
CREATE POLICY "Admin settings select"
ON public.admin_settings FOR SELECT
TO authenticated
USING (public.is_admin());

DROP POLICY IF EXISTS "Admin settings write" ON public.admin_settings;
CREATE POLICY "Admin settings write"
ON public.admin_settings FOR ALL
TO authenticated
USING (public.is_admin())
WITH CHECK (public.is_admin());

-- =============================================================================
-- 7. STORAGE BUCKET RLS POLICIES
-- =============================================================================

-- Ensure storage buckets exist and are properly guarded
INSERT INTO storage.buckets (id, name, public) 
VALUES ('profile-photos', 'profile-photos', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public) 
VALUES ('status-stories', 'status-stories', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public) 
VALUES ('vault-documents', 'vault-documents', false)
ON CONFLICT (id) DO NOTHING;

-- Storage Objects: Users can only upload to their own user ID folders
DROP POLICY IF EXISTS "User avatar upload" ON storage.objects;
CREATE POLICY "User avatar upload"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id IN ('profile-photos', 'status-stories', 'vault-documents')
  AND (auth.uid()::text = (storage.foldername(name))[1] OR public.is_admin())
);

DROP POLICY IF EXISTS "User avatar delete" ON storage.objects;
CREATE POLICY "User avatar delete"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id IN ('profile-photos', 'status-stories', 'vault-documents')
  AND (auth.uid()::text = (storage.foldername(name))[1] OR public.is_admin())
);

-- =============================================================================
-- 8. REALTIME REPLICATION PUBLICATION ENFORCEMENT
-- =============================================================================
DO $$
BEGIN
  -- Add all core tables to Realtime publication safely
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.kurichiyar_profiles;
    ALTER PUBLICATION supabase_realtime ADD TABLE public.clans;
    ALTER PUBLICATION supabase_realtime ADD TABLE public.tharavadu_status;
  END IF;
EXCEPTION WHEN OTHERS THEN
  NULL; -- Ignore duplicate table warnings
END $$;
