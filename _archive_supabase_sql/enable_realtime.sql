-- Safe script to enable realtime & triggers in Supabase
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

-- Trigger for auth.users -> kurichiyar_profiles
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.kurichiyar_profiles (
    id, email, phone, account_status, registration_status, status, role, created_at, updated_at
  )
  VALUES (
    NEW.id, NEW.email, NEW.phone, 'pending', 'pending', 'pending', 'MEMBER', NOW(), NOW()
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

-- Enable RLS
ALTER TABLE public.kurichiyar_profiles ENABLE ROW LEVEL SECURITY;
