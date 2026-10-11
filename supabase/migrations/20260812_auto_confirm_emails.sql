-- Auto-confirm all existing unconfirmed users in auth.users (e.g. asmadhu299@gmail.com)
UPDATE auth.users 
SET email_confirmed_at = COALESCE(email_confirmed_at, NOW())
WHERE email_confirmed_at IS NULL;

-- Function to automatically set email_confirmed_at = NOW() upon registration
CREATE OR REPLACE FUNCTION public.auto_confirm_user_email()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.email_confirmed_at IS NULL THEN
    NEW.email_confirmed_at := NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger firing BEFORE INSERT on auth.users
DROP TRIGGER IF EXISTS trigger_auto_confirm_user_email ON auth.users;
CREATE TRIGGER trigger_auto_confirm_user_email
BEFORE INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.auto_confirm_user_email();
