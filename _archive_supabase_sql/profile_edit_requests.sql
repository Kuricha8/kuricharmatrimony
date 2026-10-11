-- Migration: Create profile_edit_requests table for admin approval workflow
CREATE TABLE IF NOT EXISTS public.profile_edit_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    field_name TEXT NOT NULL,
    old_value TEXT,
    new_value TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    admin_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.profile_edit_requests ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Users can view and create own edit requests" ON public.profile_edit_requests;
DROP POLICY IF EXISTS "Admins have full access to profile_edit_requests" ON public.profile_edit_requests;

-- Policy 1: Authenticated users can view and create their own edit requests
CREATE POLICY "Users can view and create own edit requests" ON public.profile_edit_requests
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Policy 2: Admins have full access to all edit requests
CREATE POLICY "Admins have full access to profile_edit_requests" ON public.profile_edit_requests
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.admin_users WHERE id = auth.uid()
        ) OR EXISTS (
            SELECT 1 FROM public.kurichiyar_profiles WHERE id = auth.uid() AND (is_admin = true OR role IN ('ADMIN', 'SUPER_ADMIN', 'ADMINISTRATOR'))
        )
    );

-- Add table to Realtime Publication if available
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.profile_edit_requests;
    END IF;
EXCEPTION WHEN OTHERS THEN
    NULL;
END $$;
