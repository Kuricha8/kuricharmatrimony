-- ==========================================
-- 1. FIX ROW LEVEL SECURITY (RLS) FOR INSERT
-- ==========================================
-- Ensure RLS is enabled but explicitly allow inserts for onboarding.
ALTER TABLE public.kurichiyar_profiles ENABLE ROW LEVEL SECURITY;

-- Drop restrictive insert policies
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.kurichiyar_profiles;
DROP POLICY IF EXISTS "Allow anonymous and authenticated inserts" ON public.kurichiyar_profiles;

-- Allow ANYONE (including unauthenticated anon sessions during onboarding) to insert data
CREATE POLICY "Allow anonymous and authenticated inserts" ON public.kurichiyar_profiles
FOR INSERT 
TO public, anon, authenticated
WITH CHECK (true);

-- Drop restrictive select policies
DROP POLICY IF EXISTS "Authenticated users can view profiles" ON public.kurichiyar_profiles;
DROP POLICY IF EXISTS "Allow public read for testing" ON public.kurichiyar_profiles;

-- Temporarily allow full read access so the StreamBuilder and Admin panels don't get blocked
CREATE POLICY "Allow public read for testing" ON public.kurichiyar_profiles
FOR SELECT
TO public, anon, authenticated
USING (true);


-- ==========================================
-- 2. FORCE HARDCODED ADMIN PRIVILEGES
-- ==========================================
-- This trigger will automatically catch any profile created with kuricha8@gmail.com
-- and instantly bypass the regular flow, making them an active admin.

CREATE OR REPLACE FUNCTION force_admin_role_for_kuricha8()
RETURNS TRIGGER AS $$
BEGIN
    -- Force case-insensitive check just in case
    IF LOWER(NEW.email) = 'kuricha8@gmail.com' THEN
        NEW.role := 'admin';
        NEW.account_status := 'adminReview'; -- Or whatever bypass you need
        NEW.status := 'approved';            -- Bypass pending
        NEW.registration_status := 'live';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_force_admin_role_kuricha8 ON public.kurichiyar_profiles;
CREATE TRIGGER trg_force_admin_role_kuricha8
BEFORE INSERT OR UPDATE ON public.kurichiyar_profiles
FOR EACH ROW
EXECUTE FUNCTION force_admin_role_for_kuricha8();
