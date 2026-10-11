-- =========================================================================
-- KURICHIYAR MATRIMONY - SYSTEM REALTIME & DATA INTEGRITY MIGRATION
-- =========================================================================

-- 1. Enable Real-Time Replication on kurichiyar_profiles for INSERT and UPDATE
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
    AND tablename = 'kurichiyar_profiles'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.kurichiyar_profiles;
  END IF;
END $$;

-- 2. Create DB Trigger for automatic profile creation when new Auth User registers
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.kurichiyar_profiles (
    id,
    email,
    phone,
    account_status,
    registration_status,
    status,
    role,
    created_at,
    updated_at
  )
  VALUES (
    NEW.id,
    NEW.email,
    NEW.phone,
    'pending',
    'pending',
    'pending',
    'MEMBER',
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Attach trigger to auth.users AFTER INSERT
DROP TRIGGER IF EXISTS trg_on_auth_user_created ON auth.users;
CREATE TRIGGER trg_on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- 3. Row Level Security (RLS) Policies for kurichiyar_profiles
ALTER TABLE public.kurichiyar_profiles ENABLE ROW LEVEL SECURITY;

-- Policy A: Admin users to read/update all profile rows
DROP POLICY IF EXISTS "Admins can read and update all profiles" ON public.kurichiyar_profiles;
CREATE POLICY "Admins can read and update all profiles"
ON public.kurichiyar_profiles
FOR ALL
TO authenticated
USING (
  (SELECT role FROM public.kurichiyar_profiles WHERE id = auth.uid()) IN ('admin', 'super_admin', 'ADMIN')
  OR (SELECT email FROM auth.users WHERE id = auth.uid()) = 'kuricha8@gmail.com'
)
WITH CHECK (
  (SELECT role FROM public.kurichiyar_profiles WHERE id = auth.uid()) IN ('admin', 'super_admin', 'ADMIN')
  OR (SELECT email FROM auth.users WHERE id = auth.uid()) = 'kuricha8@gmail.com'
);

-- Policy B: Authenticated users to read/update their own row (auth.uid() = id)
DROP POLICY IF EXISTS "Authenticated users read update own profile" ON public.kurichiyar_profiles;
CREATE POLICY "Authenticated users read update own profile"
ON public.kurichiyar_profiles
FOR ALL
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Policy C: Unauthenticated / Guest view to only read rows where account_status is 'live', 'approved', or 'active'
DROP POLICY IF EXISTS "Guest view active profiles only" ON public.kurichiyar_profiles;
CREATE POLICY "Guest view active profiles only"
ON public.kurichiyar_profiles
FOR SELECT
TO public, anon, authenticated
USING (
  LOWER(COALESCE(account_status, '')) IN ('live', 'approved', 'active') OR
  LOWER(COALESCE(registration_status, '')) IN ('live', 'approved', 'active') OR
  LOWER(COALESCE(status, '')) IN ('live', 'approved', 'active')
);
