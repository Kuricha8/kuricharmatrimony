ALTER TABLE public.kurichiyar_profiles ADD COLUMN IF NOT EXISTS liveness_requested BOOLEAN DEFAULT false;
