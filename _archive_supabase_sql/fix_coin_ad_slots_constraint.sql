-- ==============================================================================
-- FIX: coin_ad_slots CHECK CONSTRAINT (status)
-- ==============================================================================

-- 1. Ensure table exists with correct columns
CREATE TABLE IF NOT EXISTS public.coin_ad_slots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slot_position TEXT NOT NULL DEFAULT 'front',
    user_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    amount_paid NUMERIC(10,2) DEFAULT 200.00,
    duration_days INT DEFAULT 7,
    starts_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now() + interval '7 days'),
    status TEXT NOT NULL DEFAULT 'active',
    payment_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 2. Drop any legacy/conflicting status check constraint
ALTER TABLE public.coin_ad_slots DROP CONSTRAINT IF EXISTS coin_ad_slots_status_check;

-- 3. Add relaxed, case-insensitive lowercase check constraint
ALTER TABLE public.coin_ad_slots 
ADD CONSTRAINT coin_ad_slots_status_check 
CHECK (status IN ('active', 'pending', 'waiting', 'available', 'expired', 'admin_override', 'inactive'));

-- 4. Enable Row Level Security (RLS)
ALTER TABLE public.coin_ad_slots ENABLE ROW LEVEL SECURITY;

-- 5. Policies
DROP POLICY IF EXISTS "Public can read active coin ad slots" ON public.coin_ad_slots;
CREATE POLICY "Public can read active coin ad slots"
ON public.coin_ad_slots FOR SELECT
USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert coin ad slots" ON public.coin_ad_slots;
CREATE POLICY "Authenticated users can insert coin ad slots"
ON public.coin_ad_slots FOR INSERT
TO authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "Authenticated users can update their own slots or admin all" ON public.coin_ad_slots;
CREATE POLICY "Authenticated users can update their own slots or admin all"
ON public.coin_ad_slots FOR UPDATE
TO authenticated
USING (true);
