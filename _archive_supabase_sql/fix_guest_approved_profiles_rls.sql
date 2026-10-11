-- =========================================================================
-- FIX SUPABASE RLS: ALLOW GUEST / ANON TO READ ALL APPROVED PROFILES
-- =========================================================================

-- 1. Ensure RLS is active on kurichiyar_profiles
ALTER TABLE public.kurichiyar_profiles ENABLE ROW LEVEL SECURITY;

-- 2. Drop any previous restrictive select policies
DROP POLICY IF EXISTS "Authenticated users can view profiles" ON public.kurichiyar_profiles;
DROP POLICY IF EXISTS "Guest view active profiles only" ON public.kurichiyar_profiles;
DROP POLICY IF EXISTS "Allow guest public read approved profiles" ON public.kurichiyar_profiles;
DROP POLICY IF EXISTS "Allow public read for approved profiles" ON public.kurichiyar_profiles;

-- 3. Create the comprehensive policy allowing authenticated users and public guests to view approved profiles
CREATE POLICY "Allow public read for approved profiles" 
ON public.kurichiyar_profiles 
FOR SELECT 
TO public, anon, authenticated
USING (
  -- Logged-in users (and admins) can read profiles
  auth.uid() IS NOT NULL
  OR
  -- Unauthenticated guests can read all approved, non-blocked, non-banned profiles
  (
    COALESCE(is_blocked, false) = false
    AND COALESCE(is_banned, false) = false
    AND (
      is_approved = true
      OR LOWER(COALESCE(status, '')) IN ('approved', 'active', 'live', 'verified')
      OR LOWER(COALESCE(approval_status, '')) IN ('approved', 'verified')
      OR LOWER(COALESCE(account_status, '')) IN ('approved', 'active', 'live')
      OR LOWER(COALESCE(verification_status, '')) IN ('approved', 'verified')
      OR LOWER(COALESCE(registration_status, '')) IN ('approved', 'active', 'live')
    )
  )
);
