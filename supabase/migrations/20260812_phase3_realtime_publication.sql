-- =========================================================================
-- PHASE 3: ADMIN <--> USER APP REAL-TIME SYNC & TRIGGER CONFIGURATION
-- =========================================================================

-- 1. Ensure handle_new_user() trigger auto-creates profile upon auth.users INSERT
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

DROP TRIGGER IF EXISTS trg_on_auth_user_created ON auth.users;
CREATE TRIGGER trg_on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- 2. Ensure supabase_realtime publication includes kurichiyar_profiles and all active tables
DO $$
DECLARE
    tbl TEXT;
    target_tables TEXT[] := ARRAY[
        'kurichiyar_profiles',
        'messages',
        'chat_messages',
        'user_shortlists',
        'user_express_interests',
        'clan_posters',
        'clan_post_comments',
        'clan_post_likes',
        'payments',
        'app_error_logs'
    ];
BEGIN
    FOREACH tbl IN ARRAY target_tables
    LOOP
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = tbl) THEN
            IF NOT EXISTS (
                SELECT 1 FROM pg_publication_tables 
                WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = tbl
            ) THEN
                EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', tbl);
            END IF;
        END IF;
    END LOOP;
END $$;

-- 3. Force PostgREST schema cache reload
NOTIFY pgrst, 'reload schema';
