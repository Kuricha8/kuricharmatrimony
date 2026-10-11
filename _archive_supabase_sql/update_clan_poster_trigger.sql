-- Create the function to update image_url based on highest likes
CREATE OR REPLACE FUNCTION update_winning_clan_poster()
RETURNS TRIGGER AS $$
DECLARE
    winning_image_url TEXT;
    target_clan_id BIGINT;
BEGIN
    -- Handle DELETE vs INSERT/UPDATE
    IF TG_OP = 'DELETE' THEN
        target_clan_id := OLD.clan_id;
    ELSE
        target_clan_id := NEW.clan_id;
    END IF;

    -- Find the image_url with the highest likes_count for this clan
    SELECT image_url INTO winning_image_url
    FROM public.clan_poster_suggestions
    WHERE clan_id = target_clan_id
    ORDER BY likes_count DESC, created_at ASC
    LIMIT 1;

    -- Update the clans table (if it exists)
    BEGIN
        UPDATE public.clans
        SET image_url = winning_image_url
        WHERE id = target_clan_id;
    EXCEPTION WHEN undefined_table THEN
        -- Ignore if public.clans doesn't exist
    END;
    
    -- Update the tharavad_master table (if it exists as a separate table)
    BEGIN
        UPDATE public.tharavad_master
        SET image_url = winning_image_url
        WHERE id = target_clan_id;
    EXCEPTION WHEN undefined_table THEN
        -- Ignore if public.tharavad_master doesn't exist
    END;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger on clan_poster_suggestions
DROP TRIGGER IF EXISTS trg_update_winning_clan_poster ON public.clan_poster_suggestions;

CREATE TRIGGER trg_update_winning_clan_poster
AFTER INSERT OR UPDATE OF likes_count OR DELETE ON public.clan_poster_suggestions
FOR EACH ROW
EXECUTE FUNCTION update_winning_clan_poster();
