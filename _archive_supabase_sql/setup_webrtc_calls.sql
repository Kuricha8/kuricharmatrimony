-- Create the webrtc_calls table for signaling
CREATE TABLE public.webrtc_calls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    caller_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    offer JSONB,
    answer JSONB,
    caller_candidates JSONB DEFAULT '[]'::jsonb,
    receiver_candidates JSONB DEFAULT '[]'::jsonb,
    status TEXT DEFAULT 'ringing' CHECK (status IN ('ringing', 'connected', 'rejected', 'ended', 'timeout')),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Add index for fast querying
CREATE INDEX idx_webrtc_calls_caller ON public.webrtc_calls(caller_id);
CREATE INDEX idx_webrtc_calls_receiver ON public.webrtc_calls(receiver_id);
CREATE INDEX idx_webrtc_calls_status ON public.webrtc_calls(status);

-- Set up Row Level Security (RLS)
ALTER TABLE public.webrtc_calls ENABLE ROW LEVEL SECURITY;

-- Allow users to view calls they are involved in
CREATE POLICY "Users can view their own calls"
ON public.webrtc_calls
FOR SELECT
USING (auth.uid() = caller_id OR auth.uid() = receiver_id);

-- Allow users to create calls where they are the caller
CREATE POLICY "Users can create calls"
ON public.webrtc_calls
FOR INSERT
WITH CHECK (auth.uid() = caller_id);

-- Allow users to update calls they are involved in (e.g. adding answer or candidates)
CREATE POLICY "Users can update their own calls"
ON public.webrtc_calls
FOR UPDATE
USING (auth.uid() = caller_id OR auth.uid() = receiver_id);

-- Turn on Realtime for the table
ALTER PUBLICATION supabase_realtime ADD TABLE public.webrtc_calls;
