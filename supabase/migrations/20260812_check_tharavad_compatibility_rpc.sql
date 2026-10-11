-- Migration: check_tharavad_compatibility RPC Stored Procedure
-- Purpose: Validates marriage compatibility between a candidate's Tharavad and target Chat Tharavad

CREATE OR REPLACE FUNCTION check_tharavad_compatibility(
  candidate_tharavad_id INT,
  target_chat_tharavad_id INT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_candidate_moiety TEXT;
  v_target_moiety TEXT;
BEGIN
  -- 1. Same Tharavad ID is strictly incompatible (same exogamous clan)
  IF candidate_tharavad_id = target_chat_tharavad_id THEN
    RETURN FALSE;
  END IF;

  -- Fetch candidate Tharavad moiety (group_name)
  SELECT UPPER(group_name) INTO v_candidate_moiety
  FROM kurichiyar_clans
  WHERE id = candidate_tharavad_id;

  -- Fetch target chat Tharavad moiety (group_name)
  SELECT UPPER(group_name) INTO v_target_moiety
  FROM kurichiyar_clans
  WHERE id = target_chat_tharavad_id;

  -- 2. Identical moieties (PANTHI & PANTHI or BANDHU & BANDHU) are strictly incompatible
  IF (v_candidate_moiety LIKE '%PANDI%' OR v_candidate_moiety LIKE '%PANTHI%') AND
     (v_target_moiety LIKE '%PANDI%' OR v_target_moiety LIKE '%PANTHI%') THEN
    RETURN FALSE;
  ELSIF (v_candidate_moiety NOT LIKE '%PANDI%' AND v_candidate_moiety NOT LIKE '%PANTHI%') AND
        (v_target_moiety NOT LIKE '%PANDI%' AND v_target_moiety NOT LIKE '%PANTHI%') THEN
    RETURN FALSE;
  END IF;

  -- 3. Marriage allowed across opposite moieties (PANDI <-> BANDHU)
  RETURN TRUE;
END;
$$;
