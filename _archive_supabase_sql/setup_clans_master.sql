-- =============================================================================
-- KURICHIYAR MATRIMONY - SUPABASE CLANS MASTER SCHEMA & SEED
-- Clean single source of truth for 57 Kurichiyar Clans (28 Bandhu + 29 Pandi)
-- =============================================================================

-- 1. Create public.clans table
CREATE TABLE IF NOT EXISTS public.clans (
    id INT PRIMARY KEY,
    name_ml TEXT NOT NULL,
    name_en TEXT,
    name TEXT GENERATED ALWAYS AS (COALESCE(name_ml, name_en)) STORED,
    type TEXT NOT NULL CHECK (LOWER(type) IN ('bandhu', 'pandi')),
    group_name TEXT NOT NULL,
    location TEXT,
    description TEXT,
    image_url TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Ensure updated_at updates automatically
CREATE OR REPLACE FUNCTION public.trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_clans_timestamp ON public.clans;
CREATE TRIGGER set_clans_timestamp
BEFORE UPDATE ON public.clans
FOR EACH ROW
EXECUTE PROCEDURE public.trigger_set_timestamp();

-- 2. Enable Row Level Security (RLS)
ALTER TABLE public.clans ENABLE ROW LEVEL SECURITY;

-- 3. RLS Policies
DROP POLICY IF EXISTS "Public can view active clans" ON public.clans;
CREATE POLICY "Public can view active clans"
ON public.clans FOR SELECT
TO anon, authenticated
USING (true);

DROP POLICY IF EXISTS "Admins have full access on clans" ON public.clans;
CREATE POLICY "Admins have full access on clans"
ON public.clans FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.admin_users
    WHERE admin_users.id = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.kurichiyar_profiles
    WHERE kurichiyar_profiles.id = auth.uid() AND kurichiyar_profiles.role = 'admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.admin_users
    WHERE admin_users.id = auth.uid()
  )
  OR
  EXISTS (
    SELECT 1 FROM public.kurichiyar_profiles
    WHERE kurichiyar_profiles.id = auth.uid() AND kurichiyar_profiles.role = 'admin'
  )
);

-- 4. Enable Realtime Replication for Clans
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'clans'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.clans;
  END IF;
END $$;

-- 5. Seed baseline 57 Kurichiyar Clans (28 Bandhu + 29 Pandi)
INSERT INTO public.clans (id, name_ml, name_en, type, group_name, location) VALUES
-- BANDHU (28 Clans - Even IDs)
(2, 'നെല്ലേരി മരടി മരടി നെല്ലേരി', 'Nelleri Maradi (Maradi Nelleri)', 'bandhu', 'ബന്ധു ഗ്രൂപ്പ്', 'മരടി നെല്ലേരി'),
(4, 'നെല്ലുകുടിയൻ കാക്കോത്തറ', 'Nellukudiyan (Kakkottara)', 'bandhu', 'ബന്ധു ഗ്രൂപ്പ്', 'കാക്കോത്തറ'),
(6, 'ചെന്നാക്കണ്ടൻ വളാടൻ ഒറ്റമലച്ചി', 'Chennakandan Valadan (Ottamalachi)', 'bandhu', 'ബന്ധു ഗ്രൂപ്പ്', 'ഒറ്റമലച്ചി'),
(8, 'ചേരക്കര കോലിമൂല', 'Cherakkara (Kolimoola)', 'bandhu', 'ബന്ധു ഗ്രൂപ്പ്', 'കോലിമൂല'),
(10, 'പൂച്ചിയേരി ചായിമ്മൽ', 'Puchiyeri (Chayimmal)', 'bandhu', 'ബന്ധു ഗ്രൂപ്പ്', 'ചായിമ്മൽ'),
(12, 'കൂടൻ വളമടക്കിൽ', 'Koodan (Valamadakkil)', 'bandhu', 'ബന്ധു ഗ്രൂപ്പ്', 'വളമടക്കിൽ'),
(14, 'ഒതയോം കൊലൻ ഒതയോത്ത്', 'Othayam Kolan (Othayoth)', 'bandhu', 'ബന്ധു ഗ്രൂപ്പ്', 'ഒതയോത്ത്'),
(16, 'പാലോടൻ പാലോട്ട്', 'Palodan (Palot)', 'bandhu', 'ബന്ധു ഗ്രൂപ്പ്', 'പാലോട്ട്'),
(18, 'ചെന്നലര കുറ്റിയോടൻ ചെന്നലര', 'Chennalara Kuttyodan (Chennalara)', 'bandhu', 'ബന്ധു ഗ്രൂപ്പ്', 'ചെന്നലര'),
(20, 'കോലിയൻ നിറ്റാര', 'Koliyen (Nittara)', 'bandhu', 'ബന്ധു ഗ്രൂപ്പ്', 'നിറ്റാര'),
(22, 'മങ്ങാനി പുത്തൂർ മങ്ങാനി', 'Mangani Puthoor (Mangani)', 'bandhu', 'ബന്ധു ഗ്രൂപ്പ്', 'മങ്ങാനി'),
(24, 'ചെറുമ്പാലൻ കാക്കൻ ചിറ', 'Cherumpalan (Kakkan Chira)', 'bandhu', 'ബന്ധു ഗ്രൂപ്പ്', 'കാക്കൻ ചിറ'),
(26, 'കൊടിയേരി പൂലായ്ക്കൽ', 'Kodiyeri (Poolaykkal)', 'bandhu', 'ബന്ധു ഗ്രൂപ്പ്', 'പൂലായ്ക്കൽ'),
(28, 'കരിമ്പിച്ചി കോടങ്ങേല', 'Karimbichi (Kodangela)', 'bandhu', 'ബന്ധു ഗ്രൂപ്പ്', 'കോടങ്ങേല'),
(30, 'കല്ലാറ കരിമ്പിച്ചി പറമ്മൂല', 'Kallara Karimbichi (Parammoola)', 'bandhu', 'ബന്ധു ഗ്രൂപ്പ്', 'പറമ്മൂല'),
(32, 'കർക്കോടൻ തലക്കര കർക്കേറ്റിൽ', 'Karkodan Thalakkara (Karkettil)', 'bandhu', 'ബന്ധു ഗ്രൂപ്പ്', 'കർക്കേറ്റിൽ'),
(34, 'പൂരിഞ്ഞി മിലിയാടി പൂരിഞ്ഞിൽ', 'Poorinji Miliyadi (Purinjil)', 'bandhu', 'ബന്ധു ഗ്രൂപ്പ്', 'പൂരിഞ്ഞിൽ'),
(36, 'വെള്ളരി മിലിയാടി വെള്ളരി', 'Vellari Miliyadi (Vellari)', 'bandhu', 'ബന്ധു ഗ്രൂപ്പ്', 'വെള്ളരി'),
(38, 'തോട്ടായി എടലകുനി', 'Thottayi (Edalakuni)', 'bandhu', 'ബന്ധു ഗ്രൂപ്പ്', 'എടലകുനി'),
(40, 'തെറ്റ വേങ്ങലോട്ട്', 'Thetta (Vengalot)', 'bandhu', 'ബന്ധു ഗ്രൂപ്പ്', 'വേങ്ങലോട്ട്'),
(42, 'പെരലാഞ്ചി മുതുവട്ടിൽ', 'Peralanji (Muthuvattil)', 'bandhu', 'ബന്ധു ഗ്രൂപ്പ്', 'മുതുവട്ടിൽ'),
(44, 'ഇടുണി കിഴക്കുംപാട്ട് - ഇടുണി', 'Iduni (Kizhakkoompatt - Iduni)', 'bandhu', 'ബന്ധു ഗ്രൂപ്പ്', 'കിഴക്കുംപാട്ട് - ഇടുണി'),
(46, 'പുതിയിടം ചമ്മിയേരി പുതിയിടം', 'Puthiyidam Chammiyeri (Puthiyidam)', 'bandhu', 'ബന്ധു ഗ്രൂപ്പ്', 'പുതിയിടം'),
(48, 'പരക്കടൻ വെള്ളോട്ട്', 'Parakkadan (Vellottil)', 'bandhu', 'ബന്ധു ഗ്രൂപ്പ്', 'വെള്ളോട്ട്'),
(50, 'എരിശേരി ചേരള', 'Ericheri (Cherala)', 'bandhu', 'ബന്ധു ഗ്രൂപ്പ്', 'ചേരള'),
(52, 'ചാൽപ്പ പിൽപ്പിടി - പള്ളിയറ', 'Chalpa (Pilpidi - Palliyara)', 'bandhu', 'ബന്ധു ഗ്രൂപ്പ്', 'പിൽപ്പിടി - പള്ളിയറ'),
(54, 'പാലിയേരി പാലേരി', 'Paliyeri (Palereri)', 'bandhu', 'ബന്ധു ഗ്രൂപ്പ്', 'പാലേരി'),
(56, 'പെരിഞ്ചോല പെരിഞ്ചോല', 'Perinchola Perinchola', 'bandhu', 'ബന്ധു ഗ്രൂപ്പ്', 'പെരിഞ്ചോല'),

-- PANDI (29 Clans - Odd IDs)
(1, 'മരടി പുതുരുതൊമ്പിൽ', 'Maradi (Puthuruthombil)', 'pandi', 'പന്തി ഗ്രൂപ്പ്', 'പുതുരുതൊമ്പിൽ'),
(3, 'കരിമ്പിലിച്ചി നെടുമ്പിലാശ്ശേരി', 'Karimbilichi (Nedumbilassery)', 'pandi', 'പന്തി ഗ്രൂപ്പ്', 'നെടുമ്പിലാശ്ശേരി'),
(5, 'വളാടൻ ഇല്ലത്തുമൂല', 'Valadan (Illathummoola)', 'pandi', 'പന്തി ഗ്രൂപ്പ്', 'ഇല്ലത്തുമൂല'),
(7, 'എടത്തണ എടത്തണ', 'Edathana (Edathana)', 'pandi', 'പന്തി ഗ്രൂപ്പ്', 'എടത്തണ'),
(9, 'കല്ലിയോടൻ കല്ലിയോട്ട്', 'Kalliyodan (Kalliyot)', 'pandi', 'പന്തി ഗ്രൂപ്പ്', 'കല്ലിയോട്ട്'),
(11, 'കുണ്ടര കുണ്ടര മൂല', 'Kundara (Kundara Moola)', 'pandi', 'പന്തി ഗ്രൂപ്പ്', 'കുണ്ടര മൂല'),
(13, 'കുന്നംകൊലൻ ചേരിമ്മൽ', 'Kunnamkolan (Cherimmal)', 'pandi', 'പന്തി ഗ്രൂപ്പ്', 'ചേരിമ്മൽ'),
(15, 'എടപ്പിടി എടപ്പിടി', 'Edappidi (Edapidi)', 'pandi', 'പന്തി ഗ്രൂപ്പ്', 'എടപ്പിടി'),
(17, 'കാവ് പാലോടൻ കാവില്', 'Kavu Palodan (Kavil)', 'pandi', 'പന്തി ഗ്രൂപ്പ്', 'കാവില്'),
(19, 'കുറ്റിയോട്ട് കുറ്റിയോടൻ കുറ്റിയോട്ട്', 'Kuttyottu Kuttyodan (Kuttyottu)', 'pandi', 'പന്തി ഗ്രൂപ്പ്', 'കുറ്റിയോട്ട്'),
(21, 'പുത്തൂർ കൊമ്മയാട്', 'Puthoor (Kommayad)', 'pandi', 'പന്തി ഗ്രൂപ്പ്', 'കൊമ്മയാട്'),
(23, 'വെണ്ണിയോറ വെണ്ണിയോറ', 'Venniyora (Venniyora)', 'pandi', 'പന്തി ഗ്രൂപ്പ്', 'വെണ്ണിയോറ'),
(25, 'വേമോത്ത് പുച്ചേരി വയമോത്ത്', 'Vemoth Pucherri (Vayemoth)', 'pandi', 'പന്തി ഗ്രൂപ്പ്', 'വയമോത്ത്'),
(27, 'മൂത്തേടൻ മൂത്തേടത്ത്', 'Moothedan (Moothedath)', 'pandi', 'പന്തി ഗ്രൂപ്പ്', 'മൂത്തേടത്ത്'),
(29, 'മത്തളം കരിമ്പിച്ചി മട്ടിലിയം', 'Mattalam Karimbichi (Mattiliyam)', 'pandi', 'പന്തി ഗ്രൂപ്പ്', 'മട്ടിലിയം'),
(31, 'ആനി തലക്കര ആന്നി', 'Aani Thalakkara (Aanni)', 'pandi', 'പന്തി ഗ്രൂപ്പ്', 'ആന്നി'),
(33, 'കൊടുമ തലക്കര കെടുംമയിൽ', 'Koduma Thalakkara (Kedumayil)', 'pandi', 'പന്തി ഗ്രൂപ്പ്', 'കെടുംമയിൽ'),
(35, 'കുനിമൽ മിലിയാടി കുനിയമ്മൽ', 'Kunimal Miliyadi (Kuniyammal)', 'pandi', 'പന്തി ഗ്രൂപ്പ്', 'കുനിയമ്മൽ'),
(37, 'അതിരും കൊലൻ പഞ്ചേരി', 'Athirum Kolan (Pancheri)', 'pandi', 'പന്തി ഗ്രൂപ്പ്', 'പഞ്ചേരി'),
(39, 'കൊന്നിയോടൻ കൊന്നിയോട്ട്', 'Konniyodan (Konniyott)', 'pandi', 'പന്തി ഗ്രൂപ്പ്', 'കൊന്നിയോട്ട്'),
(41, 'പാടിയേരി ഞാരലോട്ട്', 'Padiyeri (Njaralot)', 'pandi', 'പന്തി ഗ്രൂപ്പ്', 'ഞാരലോട്ട്'),
(43, 'എടമന എടമന', 'Edamana (Edamana)', 'pandi', 'പന്തി ഗ്രൂപ്പ്', 'എടമന'),
(45, 'ചമ്മിയേരി താഴെ തലപ്പുഴ', 'Chammiyeri (Thazhe Thalappuzha)', 'pandi', 'പന്തി ഗ്രൂപ്പ്', 'താഴെ തലപ്പുഴ'),
(47, 'കാക്കിലി ഓടുടുമ്പിൽ', 'Kakkili (Odudumbil)', 'pandi', 'പന്തി ഗ്രൂപ്പ്', 'ഓടുടുമ്പിൽ'),
(49, 'ചെരൂല് മേനരത്ത്', 'Cheroolu (Menerath)', 'pandi', 'പന്തി ഗ്രൂപ്പ്', 'മേനരത്ത്'),
(51, 'അയിനിയാടൻ ചെന്നംപാടി', 'Ayiniyadan (Chennampadi)', 'pandi', 'പന്തി ഗ്രൂപ്പ്', 'ചെന്നംപാടി'),
(53, 'പടനി കുഴികണ്ടം', 'Padani (Kuzhikandam)', 'pandi', 'പന്തി ഗ്രൂപ്പ്', 'കുഴികണ്ടം'),
(55, 'കുക്കോടൻ കുക്കോട്ടിൽ', 'Kukkodan (Kookkottil)', 'pandi', 'പന്തി ഗ്രൂപ്പ്', 'കുക്കോട്ടിൽ'),
(57, 'ചേലപ്പേരോൻ ഈരനകൊല്ലി', 'Chelaperon (Eranakolli)', 'pandi', 'പന്തി ഗ്രൂപ്പ്', 'ഈരനകൊല്ലി')
ON CONFLICT (id) DO UPDATE SET
  name_ml = EXCLUDED.name_ml,
  name_en = EXCLUDED.name_en,
  type = EXCLUDED.type,
  group_name = EXCLUDED.group_name,
  location = EXCLUDED.location,
  updated_at = NOW();

-- 6. Legacy Sync: Mirror changes to legacy tharavad_master table if it exists
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'tharavad_master') THEN
    INSERT INTO public.tharavad_master (id, name, name_ml, group_name, type, is_active)
    SELECT id, name, name_ml, group_name, UPPER(type), is_active
    FROM public.clans
    ON CONFLICT (id) DO UPDATE SET
      name = EXCLUDED.name,
      name_ml = EXCLUDED.name_ml,
      group_name = EXCLUDED.group_name,
      type = EXCLUDED.type,
      is_active = EXCLUDED.is_active;
  END IF;
END $$;
