-- Enable realtime for support_messages table
-- Run this in Supabase SQL Editor

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'support_messages'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.support_messages;
    RAISE NOTICE 'support_messages added to supabase_realtime publication';
  ELSE
    RAISE NOTICE 'support_messages already in supabase_realtime publication';
  END IF;
END $$;

ALTER TABLE IF EXISTS public.support_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own support messages" ON public.support_messages;
CREATE POLICY "Users can read own support messages"
  ON public.support_messages FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own support messages" ON public.support_messages;
CREATE POLICY "Users can insert own support messages"
  ON public.support_messages FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id OR is_from_admin = true);

DROP POLICY IF EXISTS "Admins can read all support messages" ON public.support_messages;
CREATE POLICY "Admins can read all support messages"
  ON public.support_messages FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.kurichiyar_profiles WHERE id = auth.uid() AND role IN ('admin','super_admin')));

DROP POLICY IF EXISTS "Admins can insert support messages" ON public.support_messages;
CREATE POLICY "Admins can insert support messages"
  ON public.support_messages FOR INSERT TO authenticated
  WITH CHECK (is_from_admin = true AND EXISTS (SELECT 1 FROM public.kurichiyar_profiles WHERE id = auth.uid() AND role IN ('admin','super_admin')));

DROP POLICY IF EXISTS "Admins can update support messages" ON public.support_messages;
CREATE POLICY "Admins can update support messages"
  ON public.support_messages FOR UPDATE TO authenticated
  USING (EXISTS (SELECT 1 FROM public.kurichiyar_profiles WHERE id = auth.uid() AND role IN ('admin','super_admin')));
