-- Migration: Create a Postgres Trigger to automatically apply approved profile edits
-- This trigger listens for changes to profile_edit_requests.
-- When an admin sets status = 'approved', it updates the corresponding field in kurichiyar_profiles.
-- This ensures real-time updates flow through to the user's matches automatically.

CREATE OR REPLACE FUNCTION public.process_profile_edit_request()
RETURNS TRIGGER AS $$
DECLARE
  v_clan_id INT;
BEGIN
  -- Only proceed if the status is changing to 'approved'
  IF NEW.status = 'approved' AND OLD.status != 'approved' THEN
    
    IF NEW.field_name = 'Gender' THEN
      UPDATE public.kurichiyar_profiles
      SET gender = NEW.proposed_value,
          updated_at = NOW()
      WHERE id = NEW.user_id;

    ELSIF NEW.field_name = 'Full Name' THEN
      UPDATE public.kurichiyar_profiles
      SET full_name = NEW.proposed_value,
          name = NEW.proposed_value,
          updated_at = NOW()
      WHERE id = NEW.user_id;
      
    ELSIF NEW.field_name = 'Father''s Tharavad' THEN
      -- Lookup clan id
      SELECT id INTO v_clan_id FROM public.clans WHERE name = NEW.proposed_value LIMIT 1;
      IF v_clan_id IS NOT NULL THEN
        UPDATE public.kurichiyar_profiles
        SET father_clan_id = v_clan_id,
            father_tharavadu = NEW.proposed_value,
            updated_at = NOW()
        WHERE id = NEW.user_id;
      END IF;
      
    ELSIF NEW.field_name = 'Mother''s Tharavad' THEN
      -- Lookup clan id
      SELECT id INTO v_clan_id FROM public.clans WHERE name = NEW.proposed_value LIMIT 1;
      IF v_clan_id IS NOT NULL THEN
        UPDATE public.kurichiyar_profiles
        SET mother_clan_id = v_clan_id,
            mother_tharavadu = NEW.proposed_value,
            mothers_tarawad = NEW.proposed_value,
            updated_at = NOW()
        WHERE id = NEW.user_id;
      END IF;

    ELSIF NEW.field_name = 'Date of Birth & Age' THEN
      -- Expected format: YYYY-MM-DD
      -- We will update dob and calculate age
      UPDATE public.kurichiyar_profiles
      SET dob = NEW.proposed_value::DATE,
          date_of_birth = NEW.proposed_value::DATE,
          age = EXTRACT(YEAR FROM age(NEW.proposed_value::DATE)),
          updated_at = NOW()
      WHERE id = NEW.user_id;
    END IF;

  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger if exists
DROP TRIGGER IF EXISTS trg_process_profile_edit_request ON public.profile_edit_requests;

-- Create the trigger
CREATE TRIGGER trg_process_profile_edit_request
AFTER UPDATE ON public.profile_edit_requests
FOR EACH ROW
EXECUTE FUNCTION public.process_profile_edit_request();
