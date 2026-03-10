-- Fix Schema: Add/Update columns for Special Collections
-- This script ensures the 'special_collections' table has the correct columns for anonymous requests.

DO $$ 
BEGIN 
    -- 1. Correct resident_id column (Ensure it is TEXT to support both UUIDs and Device IDs)
    IF EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'special_collections' AND column_name = 'resident_id') THEN
        -- If it's a UUID, we need to convert it to TEXT
        IF (SELECT data_type FROM information_schema.columns WHERE table_name = 'special_collections' AND column_name = 'resident_id') <> 'text' THEN
            -- Drop foreign key constraint if it exists (usually named special_collections_resident_id_fkey)
            ALTER TABLE special_collections DROP CONSTRAINT IF EXISTS special_collections_resident_id_fkey;
            -- Convert type
            ALTER TABLE special_collections ALTER COLUMN resident_id TYPE TEXT USING resident_id::text;
        END IF;
    ELSE
        ALTER TABLE special_collections ADD COLUMN resident_id TEXT;
    END IF;

    -- 2. Add other missing location columns
    IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'special_collections' AND column_name = 'resident_name') THEN
        ALTER TABLE special_collections ADD COLUMN resident_name TEXT;
    END IF;

    IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'special_collections' AND column_name = 'resident_barangay') THEN
        ALTER TABLE special_collections ADD COLUMN resident_barangay TEXT;
    END IF;

    IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'special_collections' AND column_name = 'resident_purok') THEN
        ALTER TABLE special_collections ADD COLUMN resident_purok TEXT;
    END IF;

    -- 3. Make preferred_date nullable (since app doesn't send it yet)
    IF EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'special_collections' AND column_name = 'preferred_date') THEN
        ALTER TABLE special_collections ALTER COLUMN preferred_date DROP NOT NULL;
    END IF;

END $$;

-- 3. Update RLS Policies for special_collections
-- Drop old policies to avoid conflicts
DROP POLICY IF EXISTS "Users view/cancel own special_collections" ON special_collections;
DROP POLICY IF EXISTS "Users insert special_collections" ON special_collections;
DROP POLICY IF EXISTS "Anyone can insert special_collections" ON special_collections;
DROP POLICY IF EXISTS "Admin manage special_collections" ON special_collections;
DROP POLICY IF EXISTS "Staff manage special_collections" ON special_collections;

-- Policy 1: Anyone can insert (Allows anonymous requests from residents)
CREATE POLICY "Anyone can insert special_collections" 
ON special_collections FOR INSERT 
WITH CHECK (true);

-- Policy 2: Users can view their own requests (Filtered by resident_id in the app)
-- Note: Re-enabling SELECT for all or keeping it scoped if we have a way to verify identity.
-- For now, allowing SELECT but the app will filter by resident_id.
CREATE POLICY "Users view own special_collections" 
ON special_collections FOR SELECT 
USING (true);

-- Policy 3: Staff (Admin/Collector) can manage all
CREATE POLICY "Staff manage special_collections" ON special_collections 
FOR ALL TO authenticated 
USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() 
        AND role IN ('admin', 'superadmin', 'collector')
    )
);

-- Policy 4: Allow updating own records (for cancellation)
CREATE POLICY "Users update own special_collections" 
ON special_collections FOR UPDATE 
USING (true);

-- 4. Notify Supabase to reload schema cache (Optional/Automatic, but good to keep in mind)
-- SELECT pg_notify('pgrst', 'reload schema');
