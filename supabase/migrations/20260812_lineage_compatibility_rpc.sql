-- Migration: Lineage Compatibility RPC Stored Procedure
-- Purpose: Verify traditional Kurichiyar matrimony exogamous clan & moiety rules in Supabase

CREATE OR REPLACE FUNCTION check_lineage_compatibility(
  p_candidate_id UUID,
  p_target_clan_id INT
)
RETURNS TABLE (
  is_compatible BOOLEAN,
  reason TEXT,
  candidate_moiety TEXT,
  target_moiety TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_father_clan_id INT;
  v_mother_clan_id INT;
  v_father_moiety TEXT;
  v_target_moiety TEXT;
BEGIN
  -- Fetch candidate father_clan_id and mother_clan_id from kurichiyar_profiles
  SELECT father_clan_id, mother_clan_id
  INTO v_father_clan_id, v_mother_clan_id
  FROM kurichiyar_profiles
  WHERE id = p_candidate_id;

  -- 1. Check if target clan is candidate's own father or mother clan
  IF p_target_clan_id = v_father_clan_id OR p_target_clan_id = v_mother_clan_id THEN
    RETURN QUERY SELECT FALSE, 'Own Exogamous Tharavad (സ്വന്തം തറവാട്)'::TEXT, ''::TEXT, ''::TEXT;
    RETURN;
  END IF;

  -- Fetch candidate father's clan group/moiety (e.g. PANTHI vs BANDHU)
  SELECT UPPER(group_name) INTO v_father_moiety
  FROM kurichiyar_clans
  WHERE id = v_father_clan_id;

  -- Fetch target clan group/moiety (e.g. PANTHI vs BANDHU)
  SELECT UPPER(group_name) INTO v_target_moiety
  FROM kurichiyar_clans
  WHERE id = p_target_clan_id;

  -- 2. Check if moieties are identical (PANTHI & PANTHI or BANDHU & BANDHU = Incompatible)
  IF (v_father_moiety LIKE '%PANDI%' OR v_father_moiety LIKE '%PANTHI%') AND
     (v_target_moiety LIKE '%PANDI%' OR v_target_moiety LIKE '%PANTHI%') THEN
    RETURN QUERY SELECT FALSE, 'Same Exogamous Moiety (PANDI-PANDI)'::TEXT, 'PANDI'::TEXT, 'PANDI'::TEXT;
    RETURN;
  ELSIF (v_father_moiety NOT LIKE '%PANDI%' AND v_father_moiety NOT LIKE '%PANTHI%') AND
        (v_target_moiety NOT LIKE '%PANDI%' AND v_target_moiety NOT LIKE '%PANTHI%') THEN
    RETURN QUERY SELECT FALSE, 'Same Exogamous Moiety (BANDHU-BANDHU)'::TEXT, 'BANDHU'::TEXT, 'BANDHU'::TEXT;
    RETURN;
  END IF;

  -- 3. Marriage is compatible across opposite moieties (PANDI <-> BANDHU)
  RETURN QUERY SELECT TRUE, 'Eligible for Marriage (വിവാഹ പൊരുത്തമുണ്ട്)'::TEXT, COALESCE(v_father_moiety, 'PANDI')::TEXT, COALESCE(v_target_moiety, 'BANDHU')::TEXT;
END;
$$;
