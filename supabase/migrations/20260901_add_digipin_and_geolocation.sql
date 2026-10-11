-- =========================================================================
-- MIGRATION: ADD PINCODE, DIGIPIN & GEOLOCATION (LAT/LONG) COLUMNS
-- =========================================================================

-- 1. profiles ടേബിളിലേക്ക് ആവശ്യമായ ലൊക്കേഷൻ കോളങ്ങൾ നിർമ്മിക്കുന്നു
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'profiles') THEN
        ALTER TABLE public.profiles 
        ADD COLUMN IF NOT EXISTS pincode VARCHAR(20),
        ADD COLUMN IF NOT EXISTS digipin VARCHAR(20),
        ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
        ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

        CREATE INDEX IF NOT EXISTS idx_profiles_pincode ON public.profiles(pincode);
        CREATE INDEX IF NOT EXISTS idx_profiles_digipin ON public.profiles(digipin);
    END IF;
END $$;

-- 2. kurichiyar_profiles ടേബിളിലേക്കും (Primary Table) കോളങ്ങൾ ചേർക്കുന്നു
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'kurichiyar_profiles') THEN
        ALTER TABLE public.kurichiyar_profiles 
        ADD COLUMN IF NOT EXISTS pincode VARCHAR(20),
        ADD COLUMN IF NOT EXISTS digipin VARCHAR(20),
        ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
        ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

        CREATE INDEX IF NOT EXISTS idx_kurichiyar_profiles_pincode ON public.kurichiyar_profiles(pincode);
        CREATE INDEX IF NOT EXISTS idx_kurichiyar_profiles_digipin ON public.kurichiyar_profiles(digipin);
    END IF;
END $$;
