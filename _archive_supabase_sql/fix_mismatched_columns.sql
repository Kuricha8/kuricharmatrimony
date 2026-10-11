-- 1. Fix public.tharavad_master
ALTER TABLE public.tharavad_master ADD COLUMN IF NOT EXISTS image_url TEXT;

-- 2. Fix public.thug_dialogues
ALTER TABLE public.thug_dialogues ADD COLUMN IF NOT EXISTS dialogue_text TEXT;
UPDATE public.thug_dialogues SET dialogue_text = text WHERE dialogue_text IS NULL AND text IS NOT NULL;

-- 3. Fix public.community_history
ALTER TABLE public.community_history ADD COLUMN IF NOT EXISTS date TIMESTAMP WITH TIME ZONE;
ALTER TABLE public.community_history ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE public.community_history ADD COLUMN IF NOT EXISTS content TEXT;
ALTER TABLE public.community_history ADD COLUMN IF NOT EXISTS image_url TEXT;

-- 4. Fix public.legal_information
ALTER TABLE public.legal_information ADD COLUMN IF NOT EXISTS document_type TEXT;
ALTER TABLE public.legal_information ADD COLUMN IF NOT EXISTS display_order INT DEFAULT 0;
ALTER TABLE public.legal_information ADD COLUMN IF NOT EXISTS title_en TEXT;
ALTER TABLE public.legal_information ADD COLUMN IF NOT EXISTS title_ml TEXT;
ALTER TABLE public.legal_information ADD COLUMN IF NOT EXISTS title_hi TEXT;
ALTER TABLE public.legal_information ADD COLUMN IF NOT EXISTS heading TEXT;
ALTER TABLE public.legal_information ADD COLUMN IF NOT EXISTS content_en TEXT;
ALTER TABLE public.legal_information ADD COLUMN IF NOT EXISTS content_ml TEXT;
ALTER TABLE public.legal_information ADD COLUMN IF NOT EXISTS content_hi TEXT;
ALTER TABLE public.legal_information ADD COLUMN IF NOT EXISTS body TEXT;

UPDATE public.legal_information SET document_type = type WHERE document_type IS NULL AND type IS NOT NULL;
UPDATE public.legal_information SET title_en = title, heading = title WHERE title_en IS NULL AND title IS NOT NULL;
UPDATE public.legal_information SET content_en = content, body = content WHERE content_en IS NULL AND content IS NOT NULL;

-- 5. Enable Row Level Security (RLS) on system_settings and add access policies
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;

-- Allow public read access (SELECT) for everyone
DROP POLICY IF EXISTS "Allow public read access for system_settings" ON public.system_settings;
CREATE POLICY "Allow public read access for system_settings" 
ON public.system_settings 
FOR SELECT 
TO public 
USING (true);

-- Allow full access (ALL) for admin dashboard (or service_role backend)
DROP POLICY IF EXISTS "Allow admin all access for system_settings" ON public.system_settings;
CREATE POLICY "Allow admin all access for system_settings" 
ON public.system_settings 
FOR ALL 
TO public 
USING (
  auth.role() = 'service_role' 
  OR EXISTS (
    SELECT 1 FROM public.kurichiyar_profiles
    WHERE id = auth.uid() AND role = 'admin'
  )
)
WITH CHECK (
  auth.role() = 'service_role' 
  OR EXISTS (
    SELECT 1 FROM public.kurichiyar_profiles
    WHERE id = auth.uid() AND role = 'admin'
  )
);


-- 6. Fix public.subscription_plans missing columns
ALTER TABLE public.subscription_plans ADD COLUMN IF NOT EXISTS plan_name TEXT;
ALTER TABLE public.subscription_plans ADD COLUMN IF NOT EXISTS price_inr NUMERIC;
ALTER TABLE public.subscription_plans ADD COLUMN IF NOT EXISTS billing_cycle_months INT DEFAULT 1;
ALTER TABLE public.subscription_plans ADD COLUMN IF NOT EXISTS billing_cycle INT DEFAULT 1;
ALTER TABLE public.subscription_plans ADD COLUMN IF NOT EXISTS validity_months INT DEFAULT 1;
ALTER TABLE public.subscription_plans ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE public.subscription_plans ADD COLUMN IF NOT EXISTS tier_level INT DEFAULT 1;
ALTER TABLE public.subscription_plans ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE public.subscription_plans ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
-- 7. Create explicit view for profile views history
CREATE OR REPLACE VIEW public.profile_views_history_explicit AS
SELECT * FROM public.profile_views_history;
GRANT SELECT ON public.profile_views_history_explicit TO public;
