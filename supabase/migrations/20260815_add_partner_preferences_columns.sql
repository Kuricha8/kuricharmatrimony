-- Add 10 explicit Partner Preferences columns to kurichiyar_profiles
ALTER TABLE public.kurichiyar_profiles
ADD COLUMN IF NOT EXISTS pref_joint_family BOOLEAN DEFAULT NULL,
ADD COLUMN IF NOT EXISTS pref_relocate BOOLEAN DEFAULT NULL,
ADD COLUMN IF NOT EXISTS pref_manage_job_family BOOLEAN DEFAULT NULL,
ADD COLUMN IF NOT EXISTS pref_direct_talk BOOLEAN DEFAULT NULL,
ADD COLUMN IF NOT EXISTS pref_nuclear_family BOOLEAN DEFAULT NULL,
ADD COLUMN IF NOT EXISTS pref_share_finances BOOLEAN DEFAULT NULL,
ADD COLUMN IF NOT EXISTS pref_night_shift BOOLEAN DEFAULT NULL,
ADD COLUMN IF NOT EXISTS pref_consult_decisions BOOLEAN DEFAULT NULL,
ADD COLUMN IF NOT EXISTS pref_disclose_debts BOOLEAN DEFAULT NULL,
ADD COLUMN IF NOT EXISTS pref_travel_socialize BOOLEAN DEFAULT NULL;

-- Remove old generic columns if they were previously created
ALTER TABLE public.kurichiyar_profiles
DROP COLUMN IF EXISTS q1_response,
DROP COLUMN IF EXISTS q2_response,
DROP COLUMN IF EXISTS q3_response,
DROP COLUMN IF EXISTS q4_response,
DROP COLUMN IF EXISTS q5_response,
DROP COLUMN IF EXISTS q6_response,
DROP COLUMN IF EXISTS q7_response,
DROP COLUMN IF EXISTS q8_response,
DROP COLUMN IF EXISTS q9_response,
DROP COLUMN IF EXISTS q10_response;
