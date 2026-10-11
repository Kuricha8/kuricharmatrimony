-- Create support_media bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('support_media', 'support_media', true)
ON CONFLICT (id) DO NOTHING;

-- Policy to allow public read access to support media
DROP POLICY IF EXISTS "Public Read Support Media" ON storage.objects;
CREATE POLICY "Public Read Support Media" ON storage.objects 
FOR SELECT 
USING (bucket_id = 'support_media');

-- Policy to allow authenticated/anon users to insert support media
DROP POLICY IF EXISTS "Anyone Insert Support Media" ON storage.objects;
CREATE POLICY "Anyone Insert Support Media" ON storage.objects 
FOR INSERT 
WITH CHECK (bucket_id = 'support_media');
