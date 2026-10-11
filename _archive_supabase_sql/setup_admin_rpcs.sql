-- 1. Security Trigger: Block Non-Admins from updating sensitive columns
CREATE OR REPLACE FUNCTION check_admin_privileges()
RETURNS TRIGGER AS $$
DECLARE
  caller_role TEXT;
BEGIN
  -- Allow service_role (backend) or migrations to bypass
  IF auth.uid() IS NULL THEN
    RETURN NEW;
  END IF;

  -- Get the custom role of the user making the request
  SELECT role INTO caller_role FROM public.kurichiyar_profiles WHERE id = auth.uid();
  
  -- If the user is an admin, they can modify anything.
  IF caller_role = 'admin' THEN
    RETURN NEW;
  END IF;

  -- Otherwise, block changes to sensitive columns
  IF NEW.role IS DISTINCT FROM OLD.role OR
     NEW.subscription_tier IS DISTINCT FROM OLD.subscription_tier OR
     NEW.is_banned IS DISTINCT FROM OLD.is_banned OR
     NEW.is_agent IS DISTINCT FROM OLD.is_agent THEN
    RAISE EXCEPTION 'Unauthorized: Only admins can modify sensitive profile fields.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS enforce_admin_privileges ON public.kurichiyar_profiles;
CREATE TRIGGER enforce_admin_privileges
BEFORE UPDATE ON public.kurichiyar_profiles
FOR EACH ROW
EXECUTE FUNCTION check_admin_privileges();


-- 2. Secure RPCs for Admin Actions

-- Admin Ban User
CREATE OR REPLACE FUNCTION admin_ban_user(target_user_id UUID, ban_status BOOLEAN)
RETURNS VOID AS $$
DECLARE
  caller_role TEXT;
BEGIN
  SELECT role INTO caller_role FROM public.kurichiyar_profiles WHERE id = auth.uid();
  IF caller_role != 'admin' THEN
    RAISE EXCEPTION 'Unauthorized: Must be an admin.';
  END IF;
  
  UPDATE public.kurichiyar_profiles SET is_banned = ban_status WHERE id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Admin Set Subscription
CREATE OR REPLACE FUNCTION admin_set_subscription(target_user_id UUID, tier TEXT)
RETURNS VOID AS $$
DECLARE
  caller_role TEXT;
BEGIN
  SELECT role INTO caller_role FROM public.kurichiyar_profiles WHERE id = auth.uid();
  IF caller_role != 'admin' THEN
    RAISE EXCEPTION 'Unauthorized: Must be an admin.';
  END IF;
  
  UPDATE public.kurichiyar_profiles SET subscription_tier = tier WHERE id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Admin Set Role
CREATE OR REPLACE FUNCTION admin_set_role(target_user_id UUID, new_role TEXT)
RETURNS VOID AS $$
DECLARE
  caller_role TEXT;
BEGIN
  SELECT role INTO caller_role FROM public.kurichiyar_profiles WHERE id = auth.uid();
  IF caller_role != 'admin' THEN
    RAISE EXCEPTION 'Unauthorized: Must be an admin.';
  END IF;
  
  UPDATE public.kurichiyar_profiles SET role = new_role WHERE id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Admin Set Agent Status
CREATE OR REPLACE FUNCTION admin_set_agent(target_user_id UUID, is_agent_status BOOLEAN)
RETURNS VOID AS $$
DECLARE
  caller_role TEXT;
BEGIN
  SELECT role INTO caller_role FROM public.kurichiyar_profiles WHERE id = auth.uid();
  IF caller_role != 'admin' THEN
    RAISE EXCEPTION 'Unauthorized: Must be an admin.';
  END IF;
  
  UPDATE public.kurichiyar_profiles SET is_agent = is_agent_status WHERE id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Admin Update Profile Status (e.g. approved, rejected)
CREATE OR REPLACE FUNCTION admin_update_profile_status(target_user_id UUID, new_status TEXT)
RETURNS VOID AS $$
DECLARE
  caller_role TEXT;
BEGIN
  SELECT role INTO caller_role FROM public.kurichiyar_profiles WHERE id = auth.uid();
  IF caller_role != 'admin' THEN
    RAISE EXCEPTION 'Unauthorized: Must be an admin.';
  END IF;
  
  UPDATE public.kurichiyar_profiles SET profile_status = new_status WHERE id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Admin Update Registration Status
CREATE OR REPLACE FUNCTION admin_update_registration_status(target_user_id UUID, acc_status TEXT, reg_status TEXT)
RETURNS VOID AS $$
DECLARE
  caller_role TEXT;
BEGIN
  SELECT role INTO caller_role FROM public.kurichiyar_profiles WHERE id = auth.uid();
  IF caller_role != 'admin' THEN
    RAISE EXCEPTION 'Unauthorized: Must be an admin.';
  END IF;
  
  UPDATE public.kurichiyar_profiles SET account_status = acc_status, registration_status = reg_status WHERE id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Admin Ban Device
CREATE OR REPLACE FUNCTION admin_ban_device(target_device_id TEXT)
RETURNS VOID AS $$
DECLARE
  caller_role TEXT;
BEGIN
  SELECT role INTO caller_role FROM public.kurichiyar_profiles WHERE id = auth.uid();
  IF caller_role != 'admin' THEN
    RAISE EXCEPTION 'Unauthorized: Must be an admin.';
  END IF;
  
  UPDATE public.kurichiyar_profiles SET is_banned = true, registration_status = 'banned' WHERE device_id = target_device_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Admin Remove Flag
CREATE OR REPLACE FUNCTION admin_remove_flag(target_user_id UUID)
RETURNS VOID AS $$
DECLARE
  caller_role TEXT;
BEGIN
  SELECT role INTO caller_role FROM public.kurichiyar_profiles WHERE id = auth.uid();
  IF caller_role != 'admin' THEN
    RAISE EXCEPTION 'Unauthorized: Must be an admin.';
  END IF;
  
  UPDATE public.kurichiyar_profiles SET is_broker_flagged = false WHERE id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Admin Update Video Verification
CREATE OR REPLACE FUNCTION admin_update_video_verification(target_user_id UUID, verif_status TEXT)
RETURNS VOID AS $$
DECLARE
  caller_role TEXT;
BEGIN
  SELECT role INTO caller_role FROM public.kurichiyar_profiles WHERE id = auth.uid();
  IF caller_role != 'admin' THEN
    RAISE EXCEPTION 'Unauthorized: Must be an admin.';
  END IF;
  
  UPDATE public.kurichiyar_profiles SET video_verification_status = verif_status WHERE id = target_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
