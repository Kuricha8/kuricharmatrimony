-- =========================================================================
-- KURICHIYAR MATRIMONY - SCALE & PRIVACY SCHEMA UPGRADES
-- Run this in the Supabase SQL Editor to add the required columns.
-- =========================================================================

-- Add willing_to_stay_at_bride_home to kurichiyar_profiles
ALTER TABLE public.kurichiyar_profiles 
ADD COLUMN IF NOT EXISTS willing_to_stay_at_bride_home BOOLEAN DEFAULT false;

-- Add filter_by_bride_home_willingness to kurichiyar_profiles
ALTER TABLE public.kurichiyar_profiles 
ADD COLUMN IF NOT EXISTS filter_by_bride_home_willingness BOOLEAN DEFAULT false;

-- Add boosted_until to kurichiyar_profiles
ALTER TABLE public.kurichiyar_profiles 
ADD COLUMN IF NOT EXISTS boosted_until TIMESTAMP WITH TIME ZONE;

-- Add has_family_restriction to kurichiyar_profiles
ALTER TABLE public.kurichiyar_profiles 
ADD COLUMN IF NOT EXISTS has_family_restriction BOOLEAN DEFAULT false;

-- Add restricted_tharavads to kurichiyar_profiles
ALTER TABLE public.kurichiyar_profiles 
ADD COLUMN IF NOT EXISTS restricted_tharavads INT[] DEFAULT '{}';
