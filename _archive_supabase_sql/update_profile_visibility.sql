-- Add columns to user_profiles
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS is_profile_hidden BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS hidden_until_date TIMESTAMP WITH TIME ZONE;

-- Update the RLS policy for select_matching_profiles
DROP POLICY IF EXISTS select_matching_profiles ON public.user_profiles;
CREATE POLICY select_matching_profiles ON public.user_profiles
FOR SELECT
TO authenticated
USING (
    auth.uid() = user_id
    OR
    (SELECT role FROM public.user_profiles WHERE user_id = auth.uid()) = 'ADMIN'
    OR
    (
        registration_status = 'ACTIVE'
        AND gender != (SELECT gender FROM public.user_profiles WHERE user_id = auth.uid())
        AND user_category != (SELECT user_category FROM public.user_profiles WHERE user_id = auth.uid())
        AND NOT (is_profile_hidden = true AND hidden_until_date > NOW())
    )
);

-- Create hide_profile_subscriptions table
CREATE TABLE IF NOT EXISTS public.hide_profile_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(user_id) ON DELETE CASCADE,
    payment_status TEXT NOT NULL DEFAULT 'PENDING',
    expiry_date TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.hide_profile_subscriptions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS select_hide_profile_logs ON public.hide_profile_subscriptions;
CREATE POLICY select_hide_profile_logs ON public.hide_profile_subscriptions
FOR SELECT TO authenticated
USING ((SELECT role FROM public.user_profiles WHERE user_id = auth.uid()) = 'ADMIN');

-- Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
