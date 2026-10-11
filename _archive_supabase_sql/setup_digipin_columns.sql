-- 1. profiles & kurichiyar_profiles ടേബിളുകളിലേക്ക് ആവശ്യമായ ലൊക്കേഷൻ കോളങ്ങൾ നിർമ്മിക്കുന്നു
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS pincode VARCHAR(20),
ADD COLUMN IF NOT EXISTS digipin VARCHAR(20),
ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

CREATE INDEX IF NOT EXISTS idx_profiles_pincode ON public.profiles(pincode);
CREATE INDEX IF NOT EXISTS idx_profiles_digipin ON public.profiles(digipin);

ALTER TABLE public.kurichiyar_profiles 
ADD COLUMN IF NOT EXISTS pincode VARCHAR(20),
ADD COLUMN IF NOT EXISTS digipin VARCHAR(20),
ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

CREATE INDEX IF NOT EXISTS idx_kurichiyar_profiles_pincode ON public.kurichiyar_profiles(pincode);
CREATE INDEX IF NOT EXISTS idx_kurichiyar_profiles_digipin ON public.kurichiyar_profiles(digipin);
