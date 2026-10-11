-- =============================================================================
-- APP ISSUE REPORTS & SHAKE TELEMETRY SCHEMA
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.app_issue_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE SET NULL,
    user_name TEXT,
    user_phone TEXT,
    page_title TEXT,
    screenshot_url TEXT,
    screenshot_base64 TEXT,
    route_hierarchy JSONB DEFAULT '[]'::jsonb,
    error_message TEXT,
    debug_metadata JSONB DEFAULT '{}'::jsonb,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'fixed', 'dismissed')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.app_issue_reports ENABLE ROW LEVEL SECURITY;

-- Policies
DROP POLICY IF EXISTS "Authenticated users can submit issue reports" ON public.app_issue_reports;
CREATE POLICY "Authenticated users can submit issue reports"
ON public.app_issue_reports FOR INSERT
TO authenticated, anon
WITH CHECK (true);

DROP POLICY IF EXISTS "Admins have full access on issue reports" ON public.app_issue_reports;
CREATE POLICY "Admins have full access on issue reports"
ON public.app_issue_reports FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.admin_users WHERE admin_users.id = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.kurichiyar_profiles WHERE kurichiyar_profiles.id = auth.uid() AND kurichiyar_profiles.role = 'admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.admin_users WHERE admin_users.id = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.kurichiyar_profiles WHERE kurichiyar_profiles.id = auth.uid() AND kurichiyar_profiles.role = 'admin'
  )
);

-- Realtime publication
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.app_issue_reports;
  END IF;
EXCEPTION WHEN OTHERS THEN
  NULL;
END $$;
