-- FAILSAFE FIX FOR RESIDENT_ID COLUMN
-- Run this in the Supabase SQL Editor

-- 1. Try to add to 'special_collections' (plural)
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'special_collections') THEN
        -- Add column if missing
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'special_collections' AND column_name = 'resident_id') THEN
            ALTER TABLE special_collections ADD COLUMN resident_id TEXT;
        ELSE
            -- Ensure it is TEXT (not UUID)
            ALTER TABLE special_collections ALTER COLUMN resident_id TYPE TEXT USING resident_id::text;
        END IF;
    END IF;
END $$;

-- 2. Try to add to 'special_collection' (singular - just in case)
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'special_collection') THEN
        -- Add column if missing
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'special_collection' AND column_name = 'resident_id') THEN
            ALTER TABLE special_collection ADD COLUMN resident_id TEXT;
        ELSE
            -- Ensure it is TEXT (not UUID)
            ALTER TABLE special_collection ALTER COLUMN resident_id TYPE TEXT USING resident_id::text;
        END IF;
    END IF;
END $$;

-- 3. Ensure other required columns exist in 'special_collections'
ALTER TABLE special_collections ADD COLUMN IF NOT EXISTS resident_name TEXT;
ALTER TABLE special_collections ADD COLUMN IF NOT EXISTS resident_barangay TEXT;
ALTER TABLE special_collections ADD COLUMN IF NOT EXISTS resident_purok TEXT;
ALTER TABLE special_collections ADD COLUMN IF NOT EXISTS waste_type TEXT;
ALTER TABLE special_collections ADD COLUMN IF NOT EXISTS estimated_quantity TEXT;
ALTER TABLE special_collections ADD COLUMN IF NOT EXISTS pickup_location TEXT;
ALTER TABLE special_collections ADD COLUMN IF NOT EXISTS message TEXT;

-- 4. Open RLS for anonymous inserts
ALTER TABLE special_collections ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can insert special_collections" ON special_collections;
CREATE POLICY "Anyone can insert special_collections" ON special_collections FOR INSERT TO public WITH CHECK (true);
DROP POLICY IF EXISTS "Anyone can select special_collections" ON special_collections;
CREATE POLICY "Anyone can select special_collections" ON special_collections FOR SELECT TO public USING (true);

-- 5. Force Schema Cache Reload
NOTIFY pgrst, 'reload schema';
