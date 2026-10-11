-- Run this script in your Supabase SQL Editor to create the profile_edit_requests table

CREATE TABLE IF NOT EXISTS public.profile_edit_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    field_name TEXT NOT NULL,
    old_value TEXT,
    new_value TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.profile_edit_requests ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own requests
CREATE POLICY "Users can view their own requests"
ON public.profile_edit_requests FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Policy: Users can insert their own requests
CREATE POLICY "Users can insert their own requests"
ON public.profile_edit_requests FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Policy: Admins can do everything
CREATE POLICY "Admins can manage all requests"
ON public.profile_edit_requests FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM kurichiyar_profiles
        WHERE kurichiyar_profiles.id = auth.uid()
        AND (kurichiyar_profiles.role = 'admin' OR kurichiyar_profiles.is_admin = true)
    )
);

-- Turn on Realtime for profile_edit_requests
ALTER PUBLICATION supabase_realtime ADD TABLE public.profile_edit_requests;
