-- =========================================================================
-- PHASE 2: COMPREHENSIVE SUPABASE DATABASE RLS SECURITY HARDENING
-- =========================================================================

-- 0. DROP INSECURE PUBLIC VIEWS
DROP VIEW IF EXISTS public.auth_users_exposed CASCADE;

-- 1. KURICHIYAR_PROFILES RLS
ALTER TABLE IF EXISTS public.kurichiyar_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can read and update all profiles" ON public.kurichiyar_profiles;
CREATE POLICY "Admins can read and update all profiles"
ON public.kurichiyar_profiles FOR ALL TO authenticated
USING (
  (SELECT role FROM public.kurichiyar_profiles WHERE id = auth.uid()) IN ('admin', 'super_admin', 'ADMIN')
  OR (SELECT email FROM auth.users WHERE id = auth.uid()) = 'kuricha8@gmail.com'
)
WITH CHECK (
  (SELECT role FROM public.kurichiyar_profiles WHERE id = auth.uid()) IN ('admin', 'super_admin', 'ADMIN')
  OR (SELECT email FROM auth.users WHERE id = auth.uid()) = 'kuricha8@gmail.com'
);

DROP POLICY IF EXISTS "Authenticated users read update own profile" ON public.kurichiyar_profiles;
CREATE POLICY "Authenticated users read update own profile"
ON public.kurichiyar_profiles FOR ALL TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Guest view active profiles only" ON public.kurichiyar_profiles;
CREATE POLICY "Guest view active profiles only"
ON public.kurichiyar_profiles FOR SELECT TO public, anon
USING (
  LOWER(COALESCE(account_status, '')) IN ('live', 'approved', 'active')
  AND LOWER(COALESCE(registration_status, '')) IN ('live', 'approved', 'active')
);

-- 2. MESSAGES & CHAT_MESSAGES TABLE RLS
ALTER TABLE IF EXISTS public.messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read their own messages" ON public.messages;
CREATE POLICY "Users can read their own messages"
ON public.messages FOR SELECT TO authenticated
USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

DROP POLICY IF EXISTS "Users can send messages" ON public.messages;
CREATE POLICY "Users can send messages"
ON public.messages FOR INSERT TO authenticated
WITH CHECK (auth.uid() = sender_id);

ALTER TABLE IF EXISTS public.chat_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read their own chat_messages" ON public.chat_messages;
CREATE POLICY "Users can read their own chat_messages"
ON public.chat_messages FOR SELECT TO authenticated
USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

DROP POLICY IF EXISTS "Users can send chat_messages" ON public.chat_messages;
CREATE POLICY "Users can send chat_messages"
ON public.chat_messages FOR INSERT TO authenticated
WITH CHECK (auth.uid() = sender_id);

-- 3. USER_SHORTLISTS TABLE RLS
ALTER TABLE IF EXISTS public.user_shortlists ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own shortlists" ON public.user_shortlists;
CREATE POLICY "Users manage own shortlists"
ON public.user_shortlists FOR ALL TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 4. USER_EXPRESS_INTERESTS TABLE RLS
ALTER TABLE IF EXISTS public.user_express_interests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users view own interest interactions" ON public.user_express_interests;
CREATE POLICY "Users view own interest interactions"
ON public.user_express_interests FOR SELECT TO authenticated
USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

DROP POLICY IF EXISTS "Users send interest" ON public.user_express_interests;
CREATE POLICY "Users send interest"
ON public.user_express_interests FOR INSERT TO authenticated
WITH CHECK (auth.uid() = sender_id);

-- 5. PAYMENTS TABLE RLS
ALTER TABLE IF EXISTS public.payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users view own payments" ON public.payments;
CREATE POLICY "Users view own payments"
ON public.payments FOR SELECT TO authenticated
USING (
  auth.uid() = user_id 
  OR (SELECT role FROM public.kurichiyar_profiles WHERE id = auth.uid()) IN ('admin', 'super_admin', 'ADMIN')
);

-- 6. CLAN POSTS & FEEDS RLS
ALTER TABLE IF EXISTS public.clan_posters ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users view clan posts" ON public.clan_posters;
CREATE POLICY "Authenticated users view clan posts"
ON public.clan_posters FOR SELECT TO authenticated
USING (true);

DROP POLICY IF EXISTS "Users create own clan posts" ON public.clan_posters;
CREATE POLICY "Users create own clan posts"
ON public.clan_posters FOR INSERT TO authenticated
WITH CHECK (auth.uid() = creator_id);

DROP POLICY IF EXISTS "Creators or admins delete clan posts" ON public.clan_posters;
CREATE POLICY "Creators or admins delete clan posts"
ON public.clan_posters FOR DELETE TO authenticated
USING (
  auth.uid() = creator_id 
  OR (SELECT role FROM public.kurichiyar_profiles WHERE id = auth.uid()) IN ('admin', 'super_admin', 'ADMIN')
);

-- 7. RELOAD SCHEMA CACHE
NOTIFY pgrst, 'reload schema';
