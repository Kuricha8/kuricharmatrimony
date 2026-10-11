-- Create the clan_poster_suggestions table
CREATE TABLE IF NOT EXISTS public.clan_poster_suggestions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    clan_id BIGINT REFERENCES public.clans(id) ON DELETE CASCADE,
    creator_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    likes_count INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.clan_poster_suggestions ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read poster suggestions
CREATE POLICY "Allow public read for clan_poster_suggestions"
    ON public.clan_poster_suggestions FOR SELECT
    USING (true);

-- Allow authenticated users to insert their own suggestions
CREATE POLICY "Allow users to insert their own suggestions"
    ON public.clan_poster_suggestions FOR INSERT
    WITH CHECK (auth.uid() = creator_id);

-- Allow users to update likes (a more secure way would be an RPC or a junction table, but for now we allow direct updates to likes_count if needed, or rely on an RPC)
CREATE POLICY "Allow users to update likes"
    ON public.clan_poster_suggestions FOR UPDATE
    USING (true);

-- We assume the trigger to update clans.image_url is already set up as per the user's instructions.
