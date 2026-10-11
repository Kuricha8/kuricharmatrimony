-- =============================================================================
-- REWRITE COMPLETE INTEREST & MATCH STATUS ENGINE (SUPABASE RPC FUNCTIONS)
-- =============================================================================

-- 1. RPC: get_interest_relationship_status
-- Returns: 'NONE', 'I_SENT', 'THEY_SENT', or 'MUTUAL'
CREATE OR REPLACE FUNCTION public.get_interest_relationship_status(target_user_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_current_user_id UUID := auth.uid();
  v_me_to_target TEXT;
  v_target_to_me TEXT;
BEGIN
  IF v_current_user_id IS NULL THEN
    RETURN 'NONE';
  END IF;

  -- Check interest sent from me to target
  SELECT status INTO v_me_to_target
  FROM public.profile_interests
  WHERE sender_id = v_current_user_id AND receiver_id = target_user_id
  LIMIT 1;

  -- Check interest sent from target to me
  SELECT status INTO v_target_to_me
  FROM public.profile_interests
  WHERE sender_id = target_user_id AND receiver_id = v_current_user_id
  LIMIT 1;

  -- If either record is mutual_accepted or both sent pending -> MUTUAL
  IF v_me_to_target = 'mutual_accepted' OR v_target_to_me = 'mutual_accepted' OR 
     (v_me_to_target = 'pending' AND v_target_to_me = 'pending') THEN
    RETURN 'MUTUAL';
  END IF;

  -- If target sent interest to me -> THEY_SENT
  IF v_target_to_me = 'pending' THEN
    RETURN 'THEY_SENT';
  END IF;

  -- If me sent interest to target -> I_SENT
  IF v_me_to_target = 'pending' THEN
    RETURN 'I_SENT';
  END IF;

  RETURN 'NONE';
END;
$$;

-- 2. RPC: toggle_profile_interest
-- Atomically toggles profile interest and returns the updated status ('NONE', 'I_SENT', 'THEY_SENT', 'MUTUAL')
CREATE OR REPLACE FUNCTION public.toggle_profile_interest(target_user_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_current_user_id UUID := auth.uid();
  v_current_status TEXT;
  v_new_status TEXT;
BEGIN
  IF v_current_user_id IS NULL THEN
    RAISE EXCEPTION 'User must be authenticated to toggle interest';
  END IF;

  -- Get current status
  v_current_status := public.get_interest_relationship_status(target_user_id);

  IF v_current_status = 'NONE' THEN
    -- If target had sent interest, converting to mutual match
    IF EXISTS (
      SELECT 1 FROM public.profile_interests 
      WHERE sender_id = target_user_id AND receiver_id = v_current_user_id
    ) THEN
      UPDATE public.profile_interests
      SET status = 'mutual_accepted'
      WHERE sender_id = target_user_id AND receiver_id = v_current_user_id;

      INSERT INTO public.profile_interests (sender_id, receiver_id, status, type)
      VALUES (v_current_user_id, target_user_id, 'mutual_accepted', 'interest')
      ON CONFLICT DO NOTHING;

      v_new_status := 'MUTUAL';
    ELSE
      INSERT INTO public.profile_interests (sender_id, receiver_id, status, type)
      VALUES (v_current_user_id, target_user_id, 'pending', 'interest');

      v_new_status := 'I_SENT';
    END IF;

  ELSIF v_current_status = 'I_SENT' THEN
    -- Cancel interest sent by me
    DELETE FROM public.profile_interests
    WHERE sender_id = v_current_user_id AND receiver_id = target_user_id;

    v_new_status := 'NONE';

  ELSIF v_current_status = 'THEY_SENT' THEN
    -- Accept incoming interest -> Convert to Mutual Match
    UPDATE public.profile_interests
    SET status = 'mutual_accepted'
    WHERE sender_id = target_user_id AND receiver_id = v_current_user_id;

    INSERT INTO public.profile_interests (sender_id, receiver_id, status, type)
    VALUES (v_current_user_id, target_user_id, 'mutual_accepted', 'interest')
    ON CONFLICT DO NOTHING;

    v_new_status := 'MUTUAL';

  ELSIF v_current_status = 'MUTUAL' THEN
    -- Remove my side of mutual match
    DELETE FROM public.profile_interests
    WHERE sender_id = v_current_user_id AND receiver_id = target_user_id;

    -- Revert target's side to pending
    UPDATE public.profile_interests
    SET status = 'pending'
    WHERE sender_id = target_user_id AND receiver_id = v_current_user_id;

    v_new_status := 'THEY_SENT';
  END IF;

  RETURN v_new_status;
END;
$$;
