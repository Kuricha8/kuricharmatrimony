-- ==========================================
-- SCHEMA PATCH V2 FOR ALL REMAINING COLUMNS
-- ==========================================
-- This script adds EVERY REMAINING missing column from the Dart payload 
-- that was not covered in the previous patch or setup script.

ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS public_display_number TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS height TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS height_cm INT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS weight TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS blood_group TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS physical_status TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS education_level TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS education_other_text TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS career_sector TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS job TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS smoking_habit TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS drinking_habit TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS hobbies JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS marriage_timeline TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS has_children BOOLEAN;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS children_count INT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS children_details JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS pref_age_min INT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS pref_age_max INT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS pref_education TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS pref_career TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS pref_district TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS pref_habits TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS pref_relocate_to_bride_home TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS residence_preference TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS parent_care_preference TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS pref_income TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS agent_code TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS id_document_url TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS bio TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS accept_children_status TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS adoption_preference TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS groom_staying_at_wifes_house_preference TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS bride_husband_staying_at_home_preference TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS first_marriage_open_to_remarriage_preference TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS first_marriage_adopt_children_preference TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS first_marriage_max_children_count TEXT;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS is_profile_hidden BOOLEAN DEFAULT false;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS privacy_expiry_date TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS is_auto_renewal_enabled BOOLEAN DEFAULT false;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS hide_contact_info BOOLEAN DEFAULT false;
ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS is_marketing_allowed BOOLEAN DEFAULT true;

-- Refresh the PostgREST cache so the API recognizes the new columns immediately
NOTIFY pgrst, 'reload schema';
