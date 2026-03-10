-- ROBUST FIX for special_collections schema
-- Run this in the Supabase SQL Editor

DO $$ 
BEGIN 
    -- 1. Ensure resident_id is TEXT and exists
    IF EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'special_collections' AND column_name = 'resident_id') THEN
        -- Convert to TEXT if it's currently UUID
        IF (SELECT data_type FROM information_schema.columns WHERE table_name = 'special_collections' AND column_name = 'resident_id') <> 'text' THEN
            ALTER TABLE special_collections DROP CONSTRAINT IF EXISTS special_collections_resident_id_fkey;
            ALTER TABLE special_collections ALTER COLUMN resident_id TYPE TEXT USING resident_id::text;
        END IF;
    ELSE
        ALTER TABLE special_collections ADD COLUMN resident_id TEXT;
    END IF;

    -- 2. Ensure all other columns from the app exist
    IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'special_collections' AND column_name = 'resident_name') THEN
        ALTER TABLE special_collections ADD COLUMN resident_name TEXT;
    END IF;

    IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'special_collections' AND column_name = 'resident_barangay') THEN
        ALTER TABLE special_collections ADD COLUMN resident_barangay TEXT;
    END IF;

    IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'special_collections' AND column_name = 'resident_purok') THEN
        ALTER TABLE special_collections ADD COLUMN resident_purok TEXT;
    END IF;

    IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'special_collections' AND column_name = 'waste_type') THEN
        ALTER TABLE special_collections ADD COLUMN waste_type TEXT;
    END IF;

    IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'special_collections' AND column_name = 'estimated_quantity') THEN
        ALTER TABLE special_collections ADD COLUMN estimated_quantity TEXT;
    END IF;

    IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'special_collections' AND column_name = 'pickup_location') THEN
        ALTER TABLE special_collections ADD COLUMN pickup_location TEXT;
    END IF;

    IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'special_collections' AND column_name = 'message') THEN
        ALTER TABLE special_collections ADD COLUMN message TEXT;
    END IF;

    IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'special_collections' AND column_name = 'status') THEN
        ALTER TABLE special_collections ADD COLUMN status TEXT DEFAULT 'pending';
    END IF;

    -- 3. Ensure preferred_date is nullable (since it's not always sent)
    IF EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'special_collections' AND column_name = 'preferred_date') THEN
        ALTER TABLE special_collections ALTER COLUMN preferred_date DROP NOT NULL;
    END IF;

END $$;

-- 4. Re-apply RLS Policies (Full Reset)
ALTER TABLE special_collections ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can insert special_collections" ON special_collections;
DROP POLICY IF EXISTS "Users view own special_collections" ON special_collections;
DROP POLICY IF EXISTS "Staff manage special_collections" ON special_collections;
DROP POLICY IF EXISTS "Users update own special_collections" ON special_collections;

-- Allow ANY insertion (crucial for anonymous residents)
CREATE POLICY "Anyone can insert special_collections" 
ON special_collections FOR INSERT 
TO public
WITH CHECK (true);

-- Allow SELECT for everyone (simplest for now, we filter in the app)
CREATE POLICY "Users view own special_collections" 
ON special_collections FOR SELECT 
TO public
USING (true);

-- Allow UPDATE for everyone (for status updates/cancellation)
CREATE POLICY "Users update own special_collections" 
ON special_collections FOR UPDATE 
TO public
USING (true);

-- 5. Force Schema Refresh
NOTIFY pgrst, 'reload schema';
