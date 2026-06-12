-- Alter the check constraint on profiles.language_preference to support 'tr' (Turkish)
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT tc.constraint_name 
        FROM information_schema.table_constraints tc
        JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name
        WHERE tc.table_name = 'profiles' AND ccu.column_name = 'language_preference' AND tc.constraint_type = 'CHECK'
    LOOP
        EXECUTE 'ALTER TABLE public.profiles DROP CONSTRAINT ' || quote_ident(r.constraint_name);
    END LOOP;
END $$;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_language_preference_check 
  CHECK (language_preference IN ('en', 'ar', 'tr'));
