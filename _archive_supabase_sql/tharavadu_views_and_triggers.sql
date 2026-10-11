-- SQL script to define active_panthi_groups, active_bandhu_groups views, RLS policies, and cascade triggers

-- 1. Create OR Replace tharavad_master RLS Policies
ALTER TABLE IF EXISTS tharavad_master ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    DROP POLICY IF EXISTS "Allow public read on tharavad_master" ON tharavad_master;
    CREATE POLICY "Allow public read on tharavad_master" 
    ON tharavad_master 
    FOR SELECT 
    USING (true);

    DROP POLICY IF EXISTS "Allow admin full access on tharavad_master" ON tharavad_master;
    CREATE POLICY "Allow admin full access on tharavad_master" 
    ON tharavad_master 
    FOR ALL 
    USING (true);
END;
$$;

-- Grant SELECT permissions to public/authenticated/service roles
GRANT SELECT ON TABLE tharavad_master TO anon, authenticated, service_role;

-- 2. Create OR Replace active_panthi_groups view
CREATE OR REPLACE VIEW active_panthi_groups AS
SELECT 
    id,
    name,
    name_ml,
    COALESCE(group_name, 'പന്തി') AS group_name,
    COALESCE(type, 'PANTHI') AS type,
    is_active
FROM tharavad_master
WHERE (type = 'PANDI' OR type = 'PANTHI' OR group_name = 'പന്തി' OR group_name = 'PANTHI')
  AND is_active = true;

GRANT SELECT ON active_panthi_groups TO anon, authenticated, service_role;

-- 3. Create OR Replace active_bandhu_groups view
CREATE OR REPLACE VIEW active_bandhu_groups AS
SELECT 
    id,
    name,
    name_ml,
    COALESCE(group_name, 'ബന്ധു') AS group_name,
    COALESCE(type, 'BANDHU') AS type,
    is_active
FROM tharavad_master
WHERE (type = 'BANDHU' OR group_name = 'ബന്ധു' OR group_name = 'BANDHU')
  AND is_active = true;

GRANT SELECT ON active_bandhu_groups TO anon, authenticated, service_role;

-- 4. Trigger to propagate tharavad_master updates to kurichiyar_profiles
CREATE OR REPLACE FUNCTION propagate_tharavad_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.name IS DISTINCT FROM NEW.name THEN
        UPDATE kurichiyar_profiles 
        SET mother_tharavadu = NEW.name 
        WHERE lower(mother_tharavadu) = lower(OLD.name);

        UPDATE kurichiyar_profiles 
        SET father_tharavadu = NEW.name 
        WHERE lower(father_tharavadu) = lower(OLD.name);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    DROP TRIGGER IF EXISTS trg_propagate_tharavad_changes ON tharavad_master;
    CREATE TRIGGER trg_propagate_tharavad_changes
    AFTER UPDATE ON tharavad_master
    FOR EACH ROW
    EXECUTE FUNCTION propagate_tharavad_changes();
END;
$$;
