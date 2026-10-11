
-- ==========================================
-- FEATURE: AUTOMATED MOTIVATION MESSAGING
-- ==========================================

-- 1. Create table for system settings to store Malayalam text
CREATE TABLE IF NOT EXISTS public.system_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key TEXT UNIQUE NOT NULL,
    value TEXT NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default Malayalam motivation message if it doesn't exist
INSERT INTO public.system_settings (key, value)
VALUES 
('motivation_title', 'പ്രത്യേക അറിയിപ്പ്!'),
('motivation_message', 'നിങ്ങളുടെ ജീവിതപങ്കാളിയെ കണ്ടെത്താൻ ഇന്നുതന്നെ പ്രീമിയം അക്കൗണ്ട് എടുക്കൂ!')
ON CONFLICT (key) DO NOTHING;

-- 2. Create motivation messages queue table
CREATE TABLE IF NOT EXISTS public.motivation_messages_queue (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.kurichiyar_profiles(id) ON DELETE CASCADE,
    scheduled_at TIMESTAMP WITH TIME ZONE NOT NULL,
    sent_at TIMESTAMP WITH TIME ZONE,
    status TEXT DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'SENT', 'FAILED')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. RPC Function to Schedule Motivation Messages (Enforce 1-hour gap)
CREATE OR REPLACE FUNCTION public.fn_schedule_motivation_messages()
RETURNS void AS $$
DECLARE
    last_scheduled_time TIMESTAMP WITH TIME ZONE;
    eligible_user RECORD;
    next_schedule_time TIMESTAMP WITH TIME ZONE;
BEGIN
    -- Find the latest scheduled time in the queue that is >= NOW()
    SELECT MAX(scheduled_at) INTO last_scheduled_time 
    FROM public.motivation_messages_queue 
    WHERE scheduled_at >= NOW();
    
    IF last_scheduled_time IS NULL THEN
        last_scheduled_time := NOW();
    END IF;

    -- Loop through free users who don't already have a pending message
    FOR eligible_user IN 
        SELECT id FROM public.kurichiyar_profiles 
        WHERE (subscription_tier = 'free' OR subscription_tier IS NULL)
        AND id NOT IN (
            SELECT user_id FROM public.motivation_messages_queue WHERE status = 'PENDING'
        )
        LIMIT 50 -- Batch size
    LOOP
        -- Add 1 hour to the last scheduled time
        next_schedule_time := last_scheduled_time + INTERVAL '1 hour';
        
        INSERT INTO public.motivation_messages_queue (user_id, scheduled_at, status)
        VALUES (eligible_user.id, next_schedule_time, 'PENDING');
        
        last_scheduled_time := next_schedule_time;
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. RPC Function to Dispatch (Move from PENDING to SENT) and create User Notifications
CREATE OR REPLACE FUNCTION public.fn_dispatch_motivation_messages()
RETURNS void AS $$
DECLARE
    msg_title TEXT;
    msg_body TEXT;
    queue_item RECORD;
BEGIN
    -- Fetch the configured Malayalam text
    SELECT value INTO msg_title FROM public.system_settings WHERE key = 'motivation_title';
    SELECT value INTO msg_body FROM public.system_settings WHERE key = 'motivation_message';

    FOR queue_item IN
        SELECT id, user_id FROM public.motivation_messages_queue
        WHERE status = 'PENDING' AND scheduled_at <= NOW()
    LOOP
        -- Create a notification for the user
        INSERT INTO public.user_notifications (user_id, title, message, is_read, created_at)
        VALUES (queue_item.user_id, msg_title, msg_body, false, NOW());
        
        -- Mark queue item as SENT
        UPDATE public.motivation_messages_queue
        SET status = 'SENT', sent_at = NOW()
        WHERE id = queue_item.id;
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
