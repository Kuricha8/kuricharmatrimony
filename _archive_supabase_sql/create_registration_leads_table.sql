-- ============================================================================
-- REALTIME LEAD AUTO-SAVE & ABANDONMENT TRACKING TABLE
-- Table: registration_leads
-- Description: Tracks incoming customer registration leads in real time,
--              capturing field changes (phone, name, current_step),
--              detecting drop-offs/abandonment, and recording completions.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.registration_leads (
    phone TEXT PRIMARY KEY,
    name TEXT,
    current_step INTEGER DEFAULT 1,
    status TEXT NOT NULL DEFAULT 'typing' CHECK (status IN ('typing', 'abandoned', 'completed')),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Comments on table & columns
COMMENT ON TABLE public.registration_leads IS 'Realtime registration leads tracking input keystrokes, drop-offs, and completions';
COMMENT ON COLUMN public.registration_leads.phone IS 'User mobile phone number (primary key / unique identifier)';
COMMENT ON COLUMN public.registration_leads.name IS 'Full Name typed in registration flow';
COMMENT ON COLUMN public.registration_leads.current_step IS 'The current step (1-9) the user reached in registration wizard';
COMMENT ON COLUMN public.registration_leads.status IS 'Current lead status: typing, abandoned, or completed';
COMMENT ON COLUMN public.registration_leads.updated_at IS 'Timestamp of last activity / debounced input / state transition';
COMMENT ON COLUMN public.registration_leads.created_at IS 'Timestamp when lead was first recorded';

-- Performance Indexes
CREATE INDEX IF NOT EXISTS idx_registration_leads_status ON public.registration_leads (status);
CREATE INDEX IF NOT EXISTS idx_registration_leads_current_step ON public.registration_leads (current_step);
CREATE INDEX IF NOT EXISTS idx_registration_leads_updated_at ON public.registration_leads (updated_at DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE public.registration_leads ENABLE ROW LEVEL SECURITY;

-- Allow anonymous and authenticated users to insert, upsert, and update their registration leads
DROP POLICY IF EXISTS "Allow anon and auth full access to registration_leads" ON public.registration_leads;
CREATE POLICY "Allow anon and auth full access to registration_leads"
ON public.registration_leads
FOR ALL
TO anon, authenticated
USING (true)
WITH CHECK (true);

-- Enable Realtime publication so admin dashboards can listen to lead updates live
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
        AND schemaname = 'public'
        AND tablename = 'registration_leads'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.registration_leads;
    END IF;
EXCEPTION WHEN OTHERS THEN
    -- In case supabase_realtime publication is not configured or fails, ignore
    NULL;
END $$;
