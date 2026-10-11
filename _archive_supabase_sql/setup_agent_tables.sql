-- 1. Create Agent Rewards Wallet Table
CREATE TABLE IF NOT EXISTS public.agent_rewards (
    agent_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    total_points NUMERIC DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create Agent Reward History Ledger
CREATE TABLE IF NOT EXISTS public.agent_reward_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    client_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE SET NULL,
    points NUMERIC NOT NULL,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('CREDIT', 'DEBIT')),
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Create Agent Cashout Requests
CREATE TABLE IF NOT EXISTS public.agent_cashout_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    points_redeemed NUMERIC NOT NULL,
    cash_value NUMERIC NOT NULL,
    status TEXT DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Create Agent Notice Board
CREATE TABLE IF NOT EXISTS public.agent_notices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Trigger for updated_at in agent_rewards
CREATE OR REPLACE FUNCTION update_agent_rewards_updated_at()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_agent_rewards_updated_at ON public.agent_rewards;
CREATE TRIGGER update_agent_rewards_updated_at
BEFORE UPDATE ON public.agent_rewards
FOR EACH ROW
EXECUTE FUNCTION update_agent_rewards_updated_at();

-- Provide access
ALTER TABLE public.agent_rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agent_reward_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agent_cashout_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agent_notices ENABLE ROW LEVEL SECURITY;

CREATE POLICY select_agent_rewards ON public.agent_rewards FOR SELECT TO authenticated USING (auth.uid() = agent_id OR (SELECT role FROM public.kurichiyar_profiles WHERE id = auth.uid()) = 'admin');
CREATE POLICY select_agent_reward_history ON public.agent_reward_history FOR SELECT TO authenticated USING (auth.uid() = agent_id OR (SELECT role FROM public.kurichiyar_profiles WHERE id = auth.uid()) = 'admin');
CREATE POLICY insert_cashout ON public.agent_cashout_requests FOR INSERT TO authenticated WITH CHECK (auth.uid() = agent_id);
CREATE POLICY select_cashout ON public.agent_cashout_requests FOR SELECT TO authenticated USING (auth.uid() = agent_id OR (SELECT role FROM public.kurichiyar_profiles WHERE id = auth.uid()) = 'admin');
CREATE POLICY select_notices ON public.agent_notices FOR SELECT TO authenticated USING (true);

NOTIFY pgrst, 'reload schema';
