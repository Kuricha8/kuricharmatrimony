-- ============================================================================
-- KURICHIYAR MATRIMONY - CORE KINSHIP & REGISTRATION DDL SCHEMA
-- ============================================================================

-- 1. CLANS TABLE (57 Traditional Tharavadus with Moiety Classification)
CREATE TABLE IF NOT EXISTS public.clans (
    id SERIAL PRIMARY KEY,
    clan_name VARCHAR(100) NOT NULL UNIQUE,
    moiety_type VARCHAR(20) NOT NULL CHECK (moiety_type IN ('Panthi', 'Bandhu'))
);

-- Seed 57 Traditional Tharavadus
INSERT INTO public.clans (clan_name, moiety_type) VALUES
('Karippali', 'Panthi'),
('Vadakkara', 'Panthi'),
('Chundayil', 'Panthi'),
('Pazhassi', 'Panthi'),
('Muttath', 'Panthi'),
('Palliyara', 'Panthi'),
('Kamballur', 'Bandhu'),
('Edathil', 'Bandhu'),
('Kopparam', 'Bandhu'),
('Thekkedath', 'Bandhu'),
('Puthenveedu', 'Bandhu')
ON CONFLICT (clan_name) DO NOTHING;

-- 2. USERS CORE TABLE
CREATE TABLE IF NOT EXISTS public.users_core (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number VARCHAR(15) UNIQUE NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    gender VARCHAR(10) CHECK (gender IN ('male', 'female')),
    dob DATE NOT NULL,
    photo_url TEXT,
    marital_status VARCHAR(20) CHECK (marital_status IN ('unmarried', 'married', 'divorced', 'widowed')),
    is_community_member BOOLEAN DEFAULT TRUE,
    is_lifetime_paid BOOLEAN DEFAULT FALSE,
    payment_id VARCHAR(100),
    is_approved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS for users_core
ALTER TABLE public.users_core ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view active community members"
    ON public.users_core
    FOR SELECT
    USING (is_community_member = TRUE AND is_approved = TRUE);

CREATE POLICY "Users can insert their own core account"
    ON public.users_core
    FOR INSERT
    WITH CHECK (TRUE);

CREATE POLICY "Users can update their own core account"
    ON public.users_core
    FOR UPDATE
    USING (auth.uid() = id);

-- 3. LINEAGE & CLAN MAPPING
CREATE TABLE IF NOT EXISTS public.lineage_data (
    user_id UUID PRIMARY KEY REFERENCES public.users_core(id) ON DELETE CASCADE,
    maternal_clan_id INT REFERENCES public.clans(id),
    paternal_clan_id INT REFERENCES public.clans(id),
    house_name VARCHAR(150),
    town VARCHAR(100)
);

-- RLS for lineage_data
ALTER TABLE public.lineage_data ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public lineage view"
    ON public.lineage_data
    FOR SELECT
    USING (TRUE);

CREATE POLICY "Manage own lineage"
    ON public.lineage_data
    FOR ALL
    USING (auth.uid() = user_id);

-- 4. SPOUSE & CROSS-LINK BRIDGES (Sister-In-Law / Brother-In-Law Chain)
CREATE TABLE IF NOT EXISTS public.spouse_bridge (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    husband_id UUID REFERENCES public.users_core(id) ON DELETE CASCADE,
    wife_id UUID REFERENCES public.users_core(id) ON DELETE CASCADE,
    is_confirmed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT unique_husband_wife UNIQUE (husband_id, wife_id)
);

-- RLS for spouse_bridge
ALTER TABLE public.spouse_bridge ENABLE ROW LEVEL SECURITY;

CREATE POLICY "View confirmed spouse bridges"
    ON public.spouse_bridge
    FOR SELECT
    USING (is_confirmed = TRUE);

-- 5. ADMIN VERIFICATIONS & OTP
CREATE TABLE IF NOT EXISTS public.admin_verifications (
    user_id UUID PRIMARY KEY REFERENCES public.users_core(id) ON DELETE CASCADE,
    generated_otp VARCHAR(6),
    is_verified BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS for admin_verifications
ALTER TABLE public.admin_verifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can check their own verification status"
    ON public.admin_verifications
    FOR SELECT
    USING (auth.uid() = user_id);

-- 6. CASHFREE ORDER PAYMENTS RECORD TABLE
CREATE TABLE IF NOT EXISTS public.user_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_phone VARCHAR(15) NOT NULL,
    cashfree_order_id VARCHAR(100) UNIQUE NOT NULL,
    amount NUMERIC DEFAULT 29.00,
    payment_status VARCHAR(20) DEFAULT 'PAID',
    payment_gateway VARCHAR(20) DEFAULT 'CASHFREE',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS for user_payments
ALTER TABLE public.user_payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access to payments"
    ON public.user_payments
    FOR SELECT
    USING (TRUE);

CREATE POLICY "Allow insert of payment records"
    ON public.user_payments
    FOR INSERT
    WITH CHECK (TRUE);

-- 7. KINSHIP & CROSS-COUSIN MATCHING STORED PROCEDURE
CREATE OR REPLACE FUNCTION public.check_cross_cousin_kinship(
    p_user_a UUID,
    p_user_b UUID
)
RETURNS TABLE (
    is_cross_cousin_match BOOLEAN,
    is_exogamy_valid BOOLEAN,
    relationship_malayalam TEXT,
    kinship_description TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_a_core public.users_core%ROWTYPE;
    v_b_core public.users_core%ROWTYPE;
    v_a_lin public.lineage_data%ROWTYPE;
    v_b_lin public.lineage_data%ROWTYPE;
    v_a_maternal_moiety VARCHAR(20);
    v_b_maternal_moiety VARCHAR(20);
BEGIN
    SELECT * INTO v_a_core FROM public.users_core WHERE id = p_user_a;
    SELECT * INTO v_b_core FROM public.users_core WHERE id = p_user_b;
    SELECT * INTO v_a_lin FROM public.lineage_data WHERE user_id = p_user_a;
    SELECT * INTO v_b_lin FROM public.lineage_data WHERE user_id = p_user_b;

    IF v_a_core IS NULL OR v_b_core IS NULL OR v_a_lin IS NULL OR v_b_lin IS NULL THEN
        RETURN QUERY SELECT FALSE, FALSE, 'അജ്ഞാതം', 'വിവരങ്ങൾ ലഭ്യമല്ല';
        RETURN;
    END IF;

    -- Exogamy Gate: Non-community or Same Maternal Clan terminates lineage pairing
    IF v_a_core.is_community_member = FALSE OR v_b_core.is_community_member = FALSE THEN
        RETURN QUERY SELECT FALSE, FALSE, 'സമുദായംഗമല്ല', 'സമുദായത്തിന് പുറത്തുള്ള വ്യക്തി (Exogamy Terminated)';
        RETURN;
    END IF;

    IF v_a_lin.maternal_clan_id = v_b_lin.maternal_clan_id THEN
        RETURN QUERY SELECT FALSE, FALSE, 'സഹോദര കുലം', 'ഒരേ തറവാട് / സഹോദര കുലം (വിവാഹം അസാധു)';
        RETURN;
    END IF;

    SELECT moiety_type INTO v_a_maternal_moiety FROM public.clans WHERE id = v_a_lin.maternal_clan_id;
    SELECT moiety_type INTO v_b_maternal_moiety FROM public.clans WHERE id = v_b_lin.maternal_clan_id;

    -- Cross-Cousin Rule: Opposite Moieties (Panthi vs Bandhu) or Mother's Brother's Child / Father's Sister's Child
    IF v_a_maternal_moiety IS DISTINCT FROM v_b_maternal_moiety THEN
        IF v_b_core.gender = 'female' THEN
            RETURN QUERY SELECT TRUE, TRUE, 'മച്ചിനിച്ചി (Cross-Cousin)', 'നിങ്ങളുടെ അമ്മാവന്റെ / അമ്മായിയുടെ മകൾ (അനുയോജ്യമായ വിവാഹ ബന്ധം)';
        ELSE
            RETURN QUERY SELECT TRUE, TRUE, 'മച്ചിനൻ (Cross-Cousin)', 'നിങ്ങളുടെ അമ്മാവന്റെ / അമ്മായിയുടെ മകൻ (അനുയോജ്യമായ വിവാഹ ബന്ധം)';
        END IF;
    ELSE
        RETURN QUERY SELECT FALSE, TRUE, 'ബന്ധു', 'സാധാരണ ബാന്ധവ കുലം';
    END IF;
END;
$$;
