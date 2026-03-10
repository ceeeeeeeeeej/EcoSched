-- ==========================================
-- FINAL UNIFIED SCHEMA FIX (v2 - More Defensive)
-- ==========================================
-- This script fixes "resident_id" and "preferred_date" errors.

-- 1. FIX SPECIAL COLLECTIONS TABLE
DO $$ 
BEGIN
    -- Ensure table exists (plural)
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'special_collections') THEN
        
        -- Add/Fix resident_id
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'special_collections' AND column_name = 'resident_id') THEN
            ALTER TABLE special_collections ADD COLUMN resident_id TEXT;
        ELSE
            -- Ensure it is TEXT type to support device IDs
            ALTER TABLE special_collections ALTER COLUMN resident_id TYPE TEXT USING resident_id::text;
        END IF;

        -- Add/Fix waste_type
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'special_collections' AND column_name = 'waste_type') THEN
            ALTER TABLE special_collections ADD COLUMN waste_type TEXT;
        END IF;

        -- Add/Fix pickup_location
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'special_collections' AND column_name = 'pickup_location') THEN
            ALTER TABLE special_collections ADD COLUMN pickup_location TEXT;
        END IF;

        -- Add/Fix message
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'special_collections' AND column_name = 'message') THEN
            ALTER TABLE special_collections ADD COLUMN message TEXT;
        END IF;

        -- Add/Fix resident_name
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'special_collections' AND column_name = 'resident_name') THEN
            ALTER TABLE special_collections ADD COLUMN resident_name TEXT;
        END IF;

        -- Add/Fix resident_barangay
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'special_collections' AND column_name = 'resident_barangay') THEN
            ALTER TABLE special_collections ADD COLUMN resident_barangay TEXT;
        END IF;

        -- Add/Fix resident_purok
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'special_collections' AND column_name = 'resident_purok') THEN
            ALTER TABLE special_collections ADD COLUMN resident_purok TEXT;
        END IF;

        -- Handle preferred_date (Add if missing, then make nullable)
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'special_collections' AND column_name = 'preferred_date') THEN
            ALTER TABLE special_collections ADD COLUMN preferred_date DATE;
        END IF;
        ALTER TABLE special_collections ALTER COLUMN preferred_date DROP NOT NULL;
        
    END IF;
END $$;

-- 2. FIX USER_NOTIFICATIONS TABLE (For Admin Dashboard)
CREATE TABLE IF NOT EXISTS user_notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id TEXT, -- Synthetic ID
    barangay VARCHAR(100),
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'info',
    priority VARCHAR(50) DEFAULT 'medium',
    is_read BOOLEAN DEFAULT FALSE,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notifications' AND column_name = 'user_id') THEN
        ALTER TABLE user_notifications ALTER COLUMN user_id TYPE TEXT USING user_id::text;
    ELSE
        ALTER TABLE user_notifications ADD COLUMN user_id TEXT;
    END IF;
END $$;

-- 3. RESET POLICIES
ALTER TABLE special_collections ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can insert special_collections" ON special_collections;
CREATE POLICY "Anyone can insert special_collections" ON special_collections FOR INSERT TO public WITH CHECK (true);
DROP POLICY IF EXISTS "Anyone can select special_collections" ON special_collections;
CREATE POLICY "Anyone can select special_collections" ON special_collections FOR SELECT TO public USING (true);
DROP POLICY IF EXISTS "Anyone can update special_collections" ON special_collections;
CREATE POLICY "Anyone can update special_collections" ON special_collections FOR UPDATE TO public USING (true);

ALTER TABLE user_notifications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public read user_notifications" ON user_notifications;
CREATE POLICY "Public read user_notifications" ON user_notifications FOR SELECT TO public USING (true);
DROP POLICY IF EXISTS "Anyone can insert user_notifications" ON user_notifications;
CREATE POLICY "Anyone can insert user_notifications" ON user_notifications FOR INSERT TO public WITH CHECK (true);

-- 4. RELOAD SCHEMA CACHE
NOTIFY pgrst, 'reload schema';
