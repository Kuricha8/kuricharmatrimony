-- 1. CLEAN UP EXISTING TABLES / VIEWS
DROP VIEW IF EXISTS public.guest_profiles_feed CASCADE;
DROP TRIGGER IF EXISTS trg_user_category_lookup ON public.user_profiles;
DROP TRIGGER IF EXISTS trg_activate_pending_profiles ON public.taravadu_list;
DROP TABLE IF EXISTS public.user_profiles CASCADE;
DROP TABLE IF EXISTS public.taravadu_list CASCADE;

-- 2. CREATE TARAVADU LIST TABLE
CREATE TABLE public.taravadu_list (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    taravadu_name TEXT UNIQUE NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('PANTHI', 'BANDHU')),
    is_approved BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. CREATE USER PROFILES TABLE
CREATE TABLE public.user_profiles (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    phone_number TEXT NOT NULL,
    full_name TEXT NOT NULL,
    nickname TEXT,
    gender TEXT NOT NULL CHECK (gender IN ('MALE', 'FEMALE')),
    dob DATE NOT NULL,
    taravadu_id UUID REFERENCES public.taravadu_list(id) ON DELETE SET NULL,
    user_category TEXT, -- System-generated
    photo_url TEXT NOT NULL,
    registration_status TEXT NOT NULL DEFAULT 'PENDING' CHECK (registration_status IN ('PENDING', 'ACTIVE', 'BLOCKED')),
    role TEXT NOT NULL DEFAULT 'MEMBER' CHECK (role IN ('MEMBER', 'ADMIN')),
    is_profile_hidden BOOLEAN NOT NULL DEFAULT false,
    hidden_until_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. DYNAMIC CATEGORY LOOKUP TRIGGER
CREATE OR REPLACE FUNCTION lookup_user_category()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.taravadu_id IS NOT NULL THEN
        SELECT category INTO NEW.user_category 
        FROM public.taravadu_list 
        WHERE id = NEW.taravadu_id;
    ELSE
        NEW.user_category := NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_user_category_lookup
BEFORE INSERT OR UPDATE ON public.user_profiles
FOR EACH ROW
EXECUTE FUNCTION lookup_user_category();

-- 5. CUSTOM TARAVADU PROFILE ACTIVATION TRIGGER
CREATE OR REPLACE FUNCTION activate_pending_profiles_on_approval()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_approved = true AND OLD.is_approved = false THEN
        UPDATE public.user_profiles
        SET registration_status = 'ACTIVE'
        WHERE taravadu_id = NEW.id AND registration_status = 'PENDING';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_activate_pending_profiles
AFTER UPDATE OF is_approved ON public.taravadu_list
FOR EACH ROW
EXECUTE FUNCTION activate_pending_profiles_on_approval();

-- 6. INSERT 57 MASTER SEED DATA
INSERT INTO public.taravadu_list (taravadu_name, category, is_approved) VALUES
-- ബന്ധു ഗ്രൂപ്പുകൾ (30)
('കരിമ്പിച്ചി (കൊടങ്ങേല)', 'BANDHU', true),
('മട്ടലം കരിമ്പിച്ചി (മട്ടിലിയം)', 'BANDHU', true),
('കല്ലറ കരിമ്പിച്ചി (പാറമൂല)', 'BANDHU', true),
('ആനി തലക്കറ (ആന്നി)', 'BANDHU', true),
('കാർക്കോടൻ തലക്കറ (കാർക്കേട്ടിൽ)', 'BANDHU', true),
('കൊടുമതലക്കറ (കെടുമയിൽ)', 'BANDHU', true),
('പൂരിഞ്ഞി മിലിയാടി (പുരിഞ്ഞിൽ)', 'BANDHU', true),
('കുനിമൽ മിലിയാടി (കുനിയമ്മൽ)', 'BANDHU', true),
('വെള്ളരി മിലിയാടി (വെള്ളരി)', 'BANDHU', true),
('അതിരും കോലൻ (പാഞ്ചേരി)', 'BANDHU', true),
('തോട്ടായി (എടലകുനി)', 'BANDHU', true),
('കൊന്നിയോടൻ (കൊന്നിയോട്ട്)', 'BANDHU', true),
('തേറ്റ (വെങ്ങലോട്ട്)', 'BANDHU', true),
('പടിയേരി (ഞാറലോട്ട്)', 'BANDHU', true),
('പെറളഞ്ഞി (മുതുവാട്ടിൽ)', 'BANDHU', true),
('എടമന (എടമന)', 'BANDHU', true),
('ഇടുനി (കിഴക്കുംപാട്ട് - ഇടുനി)', 'BANDHU', true),
('ചമ്മിയേരി (താഴെ തലപ്പുഴ)', 'BANDHU', true),
('പുതിയിടം ചമ്മിയേരി (പുതിയിടം)', 'BANDHU', true),
('കാക്കിലി (ഓടുടുംബിൽ)', 'BANDHU', true),
('പറക്കാടൻ (വെള്ളോട്ടിൽ)', 'BANDHU', true),
('ചെറൂല് (മെനരത്ത്)', 'BANDHU', true),
('എരിചേരി (ചേറാല)', 'BANDHU', true),
('അയിനിയാടൻ (ചെന്നംമ്പാടി)', 'BANDHU', true),
('ചല്പ (പിൽപ്പിടി - പള്ളിയറ)', 'BANDHU', true),
('പാടണി (കുഴിക്കണ്ടം)', 'BANDHU', true),
('പാലിയേരി (പാലേരി)', 'BANDHU', true),
('കുക്കോടൻ (കൂക്കോട്ടിൽ)', 'BANDHU', true),
('പെരിഞ്ചോല പെരിഞ്ചോല', 'BANDHU', true),
('ചെലപെറോൻ (എരണകൊല്ലി)', 'BANDHU', true),
-- പന്തി ഗ്രൂപ്പുകൾ (27)
('മറാടി (പുതുറുത്തോമ്പിൽ)', 'PANTHI', true),
('നെല്ലേരി മറാടി (മറാടി നെല്ലേരി)', 'PANTHI', true),
('കരിമ്പിലിച്ചി (നെടുമ്പിലാശ്ശേരി)', 'PANTHI', true),
('നെല്ല് കുടിയൻ (കക്കോട്ടറ)', 'PANTHI', true),
('വാളാടൻ (ഇല്ലത്തുംമൂല)', 'PANTHI', true),
('ചെന്നകണ്ടൻ വാളാടൻ (ഒറ്റമലച്ചി)', 'PANTHI', true),
('എടത്തന (എടത്തന)', 'PANTHI', true),
('ചെറക്കര (കോളിമൂല)', 'PANTHI', true),
('കല്ലിയോടൻ (കല്ലിയോട്ട്)', 'PANTHI', true),
('പുച്ചിയേരി (ചയിമ്മൽ)', 'PANTHI', true),
('കുണ്ടറ (കുണ്ടറ മൂല)', 'PANTHI', true),
('കൂടൻ (വാളമടക്കിൽ)', 'PANTHI', true),
('കുന്നംകോലൻ (ചേരിമ്മൽ)', 'PANTHI', true),
('ഒതയം കോലൻ (ഒതയോത്ത്)', 'PANTHI', true),
('എടപ്പിടി (എടപ്പിടി)', 'PANTHI', true),
('പലോടൻ (പാലോട്ട്)', 'PANTHI', true),
('കാവ് പലോടൻ (കാവിൽ)', 'PANTHI', true),
('ചെന്നലാറ കുറ്റിയോടൻ (ചെന്നലാറ)', 'PANTHI', true),
('കുറ്റിയോട്ട് കുറ്റിയോടൻ (കുറ്റിയോട്ട്)', 'PANTHI', true),
('കോലിയേൻ (നിട്ടറ)', 'PANTHI', true),
('പുത്തൂറ് (കൊമ്മയാട്)', 'PANTHI', true),
('മാങ്ങണി പുത്തൂറ് (മാങ്ങണി)', 'PANTHI', true),
('വെണ്ണിയോറ (വെണ്ണിയോറ)', 'PANTHI', true),
('ചെരുംപാലൻ (കാക്കൻ ചിറ)', 'PANTHI', true),
('വേമോത്ത് പുച്ചേരി (വേമോത്ത്)', 'PANTHI', true),
('കൊടിയേരി (പൂളയ്ക്കൽ)', 'PANTHI', true),
('മൂത്തേടൻ (മൂത്തേടത്ത്)', 'PANTHI', true);

-- 7. ENABLE ROW LEVEL SECURITY
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- 8. RLS POLICY FOR SELECT (EXOGAMY COMPATIBILITY & ADMIN BYPASS)
CREATE POLICY select_matching_profiles ON public.user_profiles
FOR SELECT
TO authenticated
USING (
    auth.uid() = user_id
    OR
    (SELECT role FROM public.user_profiles WHERE user_id = auth.uid()) = 'ADMIN'
    OR
    (
        registration_status = 'ACTIVE'
        AND gender != (SELECT gender FROM public.user_profiles WHERE user_id = auth.uid())
        AND user_category != (SELECT user_category FROM public.user_profiles WHERE user_id = auth.uid())
        AND NOT (is_profile_hidden = true AND hidden_until_date > NOW())
    )
);

-- Policy for INSERT (own profile only)
CREATE POLICY insert_own_profile ON public.user_profiles
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Policy for UPDATE (own profile only, or admin)
CREATE POLICY update_own_profile ON public.user_profiles
FOR UPDATE
TO authenticated
USING (
    auth.uid() = user_id
    OR
    (SELECT role FROM public.user_profiles WHERE user_id = auth.uid()) = 'ADMIN'
)
WITH CHECK (
    auth.uid() = user_id
    OR
    (SELECT role FROM public.user_profiles WHERE user_id = auth.uid()) = 'ADMIN'
);

-- Policy for DELETE (own profile or admin)
CREATE POLICY delete_profile ON public.user_profiles
FOR DELETE
TO authenticated
USING (
    auth.uid() = user_id
    OR
    (SELECT role FROM public.user_profiles WHERE user_id = auth.uid()) = 'ADMIN'
);

-- 9. GUEST VIEW FOR UNAUTHENTICATED USERS
CREATE OR REPLACE VIEW public.guest_profiles_feed WITH (security_invoker = false) AS
SELECT 
    full_name,
    EXTRACT(YEAR FROM age(dob))::int AS age
FROM public.user_profiles
WHERE registration_status = 'ACTIVE';

GRANT SELECT ON public.guest_profiles_feed TO anon;
GRANT SELECT ON public.guest_profiles_feed TO authenticated;

-- RELOAD SCHEMA CACHE
NOTIFY pgrst, 'reload schema';

-- 10. HIDE PROFILE SUBSCRIPTIONS LOG
CREATE TABLE public.hide_profile_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    payment_status TEXT NOT NULL DEFAULT 'PENDING',
    expiry_date TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.hide_profile_subscriptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY select_hide_profile_logs ON public.hide_profile_subscriptions
FOR SELECT TO authenticated
USING ((SELECT role FROM public.user_profiles WHERE user_id = auth.uid()) = 'ADMIN');
