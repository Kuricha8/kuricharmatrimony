-- 1. തറവാട് മാറുമ്പോൾ ഗ്രൂപ്പ് ഓട്ടോമാറ്റിക്കായി അപ്ഡേറ്റ് ചെയ്യുന്ന ഫങ്ക്ഷൻ
CREATE OR REPLACE FUNCTION trg_sync_user_clan_group()
RETURNS TRIGGER 
LANGUAGE plpgsql
AS $$
BEGIN
    -- മാതൃ തറവാട് ബന്ധു ഗ്രൂപ്പിൽ ഉള്ളതാണോ എന്ന് നോക്കുന്നു
    IF EXISTS (
        SELECT 1 FROM public.bandhu_groups 
        WHERE tharavadu_ml = NEW.maternal_clan OR id::text = NEW.maternal_clan
    ) THEN
        NEW.maternal_group := 'bandhu';
        NEW.group_type := 'bandhu';
    -- മാതൃ തറവാട് പന്തി ഗ്രൂപ്പിൽ ഉള്ളതാണോ എന്ന് നോക്കുന്നു
    ELSIF EXISTS (
        SELECT 1 FROM public.panthi_groups 
        WHERE tharavadu_ml = NEW.maternal_clan OR id::text = NEW.maternal_clan
    ) THEN
        NEW.maternal_group := 'panthi';
        NEW.group_type := 'panthi';
    END IF;

    -- ഔട്ട്കാസ്റ്റ് ആണോ എന്ന് പരിശോധിക്കുന്നു (അച്ഛനും അമ്മയും ഒരേ ഗ്രൂപ്പ് ആണെങ്കിൽ)
    IF NEW.maternal_group = NEW.paternal_group AND NEW.maternal_group IS NOT NULL THEN
        NEW.group_type := 'outcast';
        NEW.channel_type := 3;
    END IF;

    RETURN NEW;
END;
$$;

-- 2. യൂസർ ടേബിളിൽ അപ്ഡേറ്റ് നടക്കുമ്പോൾ ഈ ഫങ്ക്ഷൻ പ്രവർത്തിക്കാൻ ട്രിഗർ വെക്കുന്നു
DROP TRIGGER IF EXISTS trigger_sync_user_group ON public.users_core;

CREATE TRIGGER trigger_sync_user_group
BEFORE INSERT OR UPDATE OF maternal_clan, paternal_clan, maternal_group, paternal_group
ON public.users_core
FOR EACH ROW
EXECUTE FUNCTION trg_sync_user_clan_group();
