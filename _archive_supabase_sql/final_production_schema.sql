-- =========================================================================
-- KURICHIYAR MATRIMONY - UNIFIED PRODUCTION SCHEMA
-- Features: Core Profiles, 4-Room Exogamy Logic, Subscriptions, Admin Dashboards, etc.
-- =========================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==========================================
-- 1. CORE TABLES & MASTER DATA
-- ==========================================

-- Tharavad Master Table (Panthi / Bandhu)
CREATE TABLE IF NOT EXISTS public.tharavad_master (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    name_ml TEXT,
    category TEXT CHECK (category IN ('PANTHI', 'BANDHU'))
);

-- Seed Initial Tharavad Categories
INSERT INTO public.tharavad_master (name, name_ml, category) VALUES
('Kallara Karimpidi', 'കല്ലറ കരിമ്പിച്ചി', 'BANDHU'), 
('Mullil Panthi', 'മുള്ളിൽ പന്തി', 'PANTHI')
ON CONFLICT DO NOTHING;

-- Main Profiles Table
CREATE TABLE IF NOT EXISTS public.kurichiyar_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Core Identity
    phone TEXT UNIQUE,
    email TEXT UNIQUE,
    full_name TEXT NOT NULL,
    age INT,
    gender TEXT CHECK (gender IN ('male', 'female')),
    dob DATE,
    photo_url TEXT,
    
    -- Exogamy Tracking (References Tharavad Master)
    father_tharavadu UUID REFERENCES public.tharavad_master(id) ON DELETE SET NULL,
    mother_tharavadu UUID REFERENCES public.tharavad_master(id) ON DELETE SET NULL,
    
    -- Status & Roles
    registration_status TEXT DEFAULT 'pending' CHECK (registration_status IN ('pending', 'approved', 'rejected')),
    account_status TEXT DEFAULT 'PENDING_LEAD',
    role TEXT DEFAULT 'MEMBER' CHECK (role IN ('MEMBER', 'ADMIN')),
    is_agent BOOLEAN DEFAULT false,
    
    -- Demographics
    region TEXT,
    pref_location TEXT,
    pref_occupation TEXT,
    marital_status TEXT DEFAULT 'never_married',
    is_out_of_caste BOOLEAN DEFAULT false,
    
    -- System tracking
    subscription_tier TEXT DEFAULT 'Free',
    report_count INT DEFAULT 0
);

-- Profile Verification Queue (Incomplete / Dropped Leads)
CREATE TABLE IF NOT EXISTS public.incomplete_registrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number TEXT NOT NULL,
    full_name TEXT,
    last_completed_step INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==========================================
-- 2. 4-ROOM MATCHING ISOLATION VIEW LOGIC
-- ==========================================
-- Ensures strict exogamy by cross-verifying that neither the father's nor mother's 
-- clan of the bride matches the father's or mother's clan of the groom.

CREATE OR REPLACE VIEW public.four_room_compatible_matches AS
SELECT 
    v.id AS viewer_id,
    t.id AS target_id
FROM public.kurichiyar_profiles v
JOIN public.kurichiyar_profiles t 
  ON v.gender != t.gender 
  AND t.registration_status = 'approved'
  AND v.id != t.id
WHERE 
    -- Type-casting to text (f.id::text) as requested for strict isolation checking
    (v.father_tharavadu::text != t.father_tharavadu::text) AND
    (v.father_tharavadu::text != t.mother_tharavadu::text) AND
    (v.mother_tharavadu::text != t.father_tharavadu::text) AND
    (v.mother_tharavadu::text != t.mother_tharavadu::text);

-- ==========================================
-- 3. BUSINESS LOGIC & ADMIN FEATURES
-- ==========================================

-- Subscription Plans
CREATE TABLE IF NOT EXISTS public.subscription_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    price NUMERIC NOT NULL,
    duration_days INT NOT NULL,
    features JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Payment Logs
CREATE TABLE IF NOT EXISTS public.payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE SET NULL,
    amount NUMERIC NOT NULL,
    currency TEXT DEFAULT 'INR',
    status TEXT DEFAULT 'success',
    plan_name TEXT,
    gateway_order_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Reported Profiles
CREATE TABLE IF NOT EXISTS public.reported_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
    reported_user_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    status TEXT DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'RESOLVED', 'DISMISSED')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Support Tickets (Helpdesk)
CREATE TABLE IF NOT EXISTS public.support_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
    admin_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE SET NULL,
    message TEXT NOT NULL,
    is_from_admin BOOLEAN DEFAULT false,
    read_status BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Admin Dashboard Setup Views
CREATE TABLE IF NOT EXISTS public.admin_app_settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE OR REPLACE VIEW public.admin_dashboard_metrics AS
SELECT 
    (SELECT COUNT(*) FROM public.kurichiyar_profiles) AS total_users,
    (SELECT COUNT(*) FROM public.kurichiyar_profiles WHERE registration_status = 'pending') AS pending_approvals,
    (SELECT COUNT(*) FROM public.payments WHERE status = 'success') AS total_successful_payments,
    (SELECT COUNT(*) FROM public.support_messages WHERE is_from_admin = false AND read_status = false) AS open_tickets;

-- Profile Matching Activity (Swipes/Likes)
CREATE TABLE IF NOT EXISTS public.profile_matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    receiver_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL CHECK (status IN ('LIKED', 'PASSED', 'REJECTED', 'AGREED', 'MATCHED', 'EXPIRED')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(sender_id, receiver_id)
);

-- ==========================================
-- 4. PUBLIC STORAGE BUCKETS & POLICIES
-- ==========================================

-- Create Buckets
INSERT INTO storage.buckets (id, name, public) 
VALUES ('user_identity_documents', 'user_identity_documents', true) 
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public) 
VALUES ('user_documents', 'user_documents', true) 
ON CONFLICT (id) DO NOTHING;

-- Grant permissions to postgres so the SQL Editor can create policies
GRANT ALL ON storage.objects TO postgres;
GRANT ALL ON storage.buckets TO postgres;

-- Policies for user_identity_documents
DROP POLICY IF EXISTS "Public Read Identity Docs" ON storage.objects;
CREATE POLICY "Public Read Identity Docs" ON storage.objects FOR SELECT USING (bucket_id = 'user_identity_documents');

DROP POLICY IF EXISTS "Auth Insert Identity Docs" ON storage.objects;
CREATE POLICY "Auth Insert Identity Docs" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'user_identity_documents');

-- Policies for user_documents
DROP POLICY IF EXISTS "Public Read User Docs" ON storage.objects;
CREATE POLICY "Public Read User Docs" ON storage.objects FOR SELECT USING (bucket_id = 'user_documents');

DROP POLICY IF EXISTS "Auth Insert User Docs" ON storage.objects;
CREATE POLICY "Auth Insert User Docs" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'user_documents');
