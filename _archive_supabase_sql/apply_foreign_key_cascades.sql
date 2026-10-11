-- DDL Migration Script: Automatically configure ON DELETE CASCADE on ALL foreign key constraints linking to auth.users and public profile tables.

DO $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN 
        SELECT 
            tc.table_schema, 
            tc.table_name, 
            kcu.column_name, 
            tc.constraint_name,
            ccu.table_schema AS foreign_table_schema,
            ccu.table_name AS foreign_table_name,
            ccu.column_name AS foreign_column_name
        FROM 
            information_schema.table_constraints AS tc 
            JOIN information_schema.key_column_usage AS kcu
              ON tc.constraint_name = kcu.constraint_name
              AND tc.table_schema = kcu.table_schema
            JOIN information_schema.constraint_column_usage AS ccu
              ON ccu.constraint_name = tc.constraint_name
              AND ccu.table_schema = tc.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY'
          AND ccu.table_name IN ('users', 'kurichiyar_profiles', 'user_profiles')
    LOOP
        BEGIN
            EXECUTE format('ALTER TABLE %I.%I DROP CONSTRAINT IF EXISTS %I;', rec.table_schema, rec.table_name, rec.constraint_name);
            EXECUTE format('ALTER TABLE %I.%I ADD CONSTRAINT %I FOREIGN KEY (%I) REFERENCES %I.%I(%I) ON DELETE CASCADE;',
                rec.table_schema, rec.table_name, rec.constraint_name, rec.column_name, rec.foreign_table_schema, rec.foreign_table_name, rec.foreign_column_name);
            RAISE NOTICE 'Updated FK constraint % on %.% to ON DELETE CASCADE', rec.constraint_name, rec.table_schema, rec.table_name;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Could not alter constraint %: %', rec.constraint_name, SQLERRM;
        END;
    END LOOP;
END $$;
