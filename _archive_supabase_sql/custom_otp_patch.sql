-- 1. Add custom OTP tracking columns to kurichiyar_profiles
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS whatsapp_otp VARCHAR;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS otp_generated_at TIMESTAMP WITH TIME ZONE;

-- 2. Create the secure RPC function to handle the 24-hour expiry and password reset
CREATE OR REPLACE FUNCTION public.reset_password_with_custom_otp(p_phone text, p_otp text, p_new_password text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER -- Required to bypass RLS and update auth.users table
AS $$
DECLARE
    v_user_id uuid;
    v_generated_at timestamp with time zone;
    v_stored_otp text;
BEGIN
    -- 1. Find the user profile matching the phone
    SELECT id, whatsapp_otp, otp_generated_at 
    INTO v_user_id, v_stored_otp, v_generated_at
    FROM public.kurichiyar_profiles 
    WHERE guardian_phone = p_phone OR public_display_number = p_phone
    LIMIT 1;

    -- 2. Check if user exists
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'No matching profile found';
    END IF;

    -- 3. Verify OTP exists and matches
    IF v_stored_otp IS NULL OR v_stored_otp != p_otp THEN
        RAISE EXCEPTION 'Invalid OTP';
    END IF;

    -- 4. Check strict 24-hour expiry logic
    IF v_generated_at IS NULL OR NOW() > (v_generated_at + interval '24 hours') THEN
        -- Auto-clear expired OTP for security
        UPDATE public.kurichiyar_profiles 
        SET whatsapp_otp = NULL, otp_generated_at = NULL 
        WHERE id = v_user_id;
        
        RAISE EXCEPTION 'OTP Expired (Valid for 24 hours only)';
    END IF;

    -- 5. OTP is valid! Reset the password securely in auth.users
    UPDATE auth.users 
    SET encrypted_password = crypt(p_new_password, gen_salt('bf'))
    WHERE id = v_user_id;

    -- 6. Clear the OTP so it cannot be reused
    UPDATE public.kurichiyar_profiles 
    SET whatsapp_otp = NULL, otp_generated_at = NULL 
    WHERE id = v_user_id;

END;
$$;
