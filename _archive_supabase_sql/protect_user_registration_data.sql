-- അഡ്മിൻമാർക്ക് മാത്രം എഡിറ്റ് ചെയ്യാൻ അനുമതി നൽകുന്ന ട്രിഗർ (Protection for Clan, DOB, Gender)
CREATE OR REPLACE FUNCTION protect_user_registration_data()
RETURNS TRIGGER AS $$
DECLARE
  is_admin_user BOOLEAN := false;
BEGIN
  -- അപ്ഡേറ്റ് ചെയ്യുന്നത് അഡ്മിൻ ആണോ എന്ന് പരിശോധിക്കുന്നു
  SELECT is_admin INTO is_admin_user 
  FROM kurichiyar_profiles 
  WHERE id = auth.uid();

  -- അഡ്മിൻ ആണെങ്കിൽ എഡിറ്റ് ചെയ്യാൻ പൂർണ്ണ അനുമതി നൽകുന്നു
  IF is_admin_user = true THEN
    RETURN NEW;
  END IF;

  -- സാധാരണ യൂസർമാർ മാറ്റാൻ ശ്രമിച്ചാൽ പഴയ ഡാറ്റ നിലനിർത്തുന്നു (Immutability Gate)
  IF OLD.father_tharavad IS NOT NULL AND OLD.father_tharavad <> '' THEN
    NEW.father_tharavad := OLD.father_tharavad;
  END IF;

  IF OLD.mother_tharavad IS NOT NULL AND OLD.mother_tharavad <> '' THEN
    NEW.mother_tharavad := OLD.mother_tharavad;
  END IF;

  IF OLD.dob IS NOT NULL THEN
    NEW.dob := OLD.dob;
  END IF;

  IF OLD.gender IS NOT NULL AND OLD.gender <> '' THEN
    NEW.gender := OLD.gender;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_protect_user_registration_data ON kurichiyar_profiles;
CREATE TRIGGER tr_protect_user_registration_data
BEFORE UPDATE ON kurichiyar_profiles
FOR EACH ROW EXECUTE FUNCTION protect_user_registration_data();
