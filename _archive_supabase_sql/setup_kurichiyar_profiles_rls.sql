-- 1. Enable Row Level Security (RLS) on the table
ALTER TABLE public.kurichiyar_profiles ENABLE ROW LEVEL SECURITY;

-- 2. INSERT Policy: Allow users to insert their own profile during registration
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.kurichiyar_profiles;
CREATE POLICY "Users can insert their own profile" 
ON public.kurichiyar_profiles 
FOR INSERT 
WITH CHECK (auth.uid() = id);

-- 3. UPDATE Policy: Allow users to update their own profile, OR allow admins to update any profile
DROP POLICY IF EXISTS "Users and admins can update profiles" ON public.kurichiyar_profiles;
CREATE POLICY "Users and admins can update profiles" 
ON public.kurichiyar_profiles 
FOR UPDATE 
USING (
    auth.uid() = id OR 
    (SELECT role FROM public.kurichiyar_profiles WHERE id = auth.uid()) IN ('admin', 'super_admin')
);

-- 4. SELECT Policy: Allow authenticated users to view profiles, AND allow public/guests to view approved profiles
DROP POLICY IF EXISTS "Authenticated users can view profiles" ON public.kurichiyar_profiles;
DROP POLICY IF EXISTS "Guest view active profiles only" ON public.kurichiyar_profiles;
DROP POLICY IF EXISTS "Allow public read for approved profiles" ON public.kurichiyar_profiles;

CREATE POLICY "Allow public read for approved profiles" 
ON public.kurichiyar_profiles 
FOR SELECT 
TO public, anon, authenticated
USING (
  auth.uid() IS NOT NULL
  OR (
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

-- 5. DELETE Policy: Allow users to delete their own profile, OR allow admins to delete any profile
DROP POLICY IF EXISTS "Users and admins can delete profiles" ON public.kurichiyar_profiles;
CREATE POLICY "Users and admins can delete profiles" 
ON public.kurichiyar_profiles 
FOR DELETE 
USING (
    auth.uid() = id OR 
    (SELECT role FROM public.kurichiyar_profiles WHERE id = auth.uid()) IN ('admin', 'super_admin')
);
