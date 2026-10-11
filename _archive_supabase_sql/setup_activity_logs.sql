-- =====================================================================
-- Setup: user_activity_logs table
-- Run this in your Supabase SQL Editor
-- =====================================================================

-- 1. Create the table
CREATE TABLE IF NOT EXISTS public.user_activity_logs (
  id            uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id       uuid REFERENCES public.kurichiyar_profiles(id) ON DELETE SET NULL,
  action_type   text NOT NULL,           -- e.g. 'login', 'profile_view', 'express_interest', 'subscription', 'report', 'block'
  description   text,                    -- Human-readable description of the action
  ip_address    text,                    -- Optional: user IP for audit trails
  device_info   text,                    -- Optional: device/platform string
  metadata      jsonb DEFAULT '{}',      -- Optional: extra structured data (e.g., target_user_id, amount, etc.)
  created_at    timestamptz DEFAULT now() NOT NULL
);

-- 2. Index for fast admin queries (most recent first, per user)
CREATE INDEX IF NOT EXISTS idx_user_activity_logs_created_at ON public.user_activity_logs (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_activity_logs_user_id    ON public.user_activity_logs (user_id);
CREATE INDEX IF NOT EXISTS idx_user_activity_logs_action     ON public.user_activity_logs (action_type);

-- 3. Enable Row Level Security
ALTER TABLE public.user_activity_logs ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies
-- Allow authenticated users to INSERT their own activity
CREATE POLICY "Users can log their own activity"
  ON public.user_activity_logs
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- Allow admins (service role) full access for the Admin Console
-- Service role bypasses RLS by default, so no extra policy needed.

-- Allow users to read their own logs only
CREATE POLICY "Users can view their own logs"
  ON public.user_activity_logs
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- 5. Reload PostgREST schema cache so the table & FK appear immediately
NOTIFY pgrst, 'reload schema';

-- =====================================================================
-- VERIFY: Run this to confirm the table and FK are set up correctly
-- =====================================================================
-- SELECT
--   tc.table_name,
--   kcu.column_name,
--   ccu.table_name AS foreign_table,
--   ccu.column_name AS foreign_column
-- FROM information_schema.table_constraints AS tc
-- JOIN information_schema.key_column_usage AS kcu
--   ON tc.constraint_name = kcu.constraint_name
-- JOIN information_schema.constraint_column_usage AS ccu
--   ON ccu.constraint_name = tc.constraint_name
-- WHERE tc.constraint_type = 'FOREIGN KEY'
--   AND tc.table_name = 'user_activity_logs';
