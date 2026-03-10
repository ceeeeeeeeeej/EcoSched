-- ===============================================
-- FINAL UNIFIED SCHEMA FIX (v4 - FIX USER_DEVICES)
-- ===============================================
-- This script fixes "resident_id", "user_id", and "user_devices" table.

-- 1. FIX USER_DEVICES TABLE (NEW FIX)
-- Use device_id as PK and fcm_token for push notifications.
DO $$ 
BEGIN 
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'user_devices') THEN
        -- Add device_id if missing
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'user_devices' AND column_name = 'device_id') THEN
            ALTER TABLE user_devices ADD COLUMN device_id TEXT;
        END IF;
        
        -- If device_token exists but fcm_token doesn't, rename it
        IF EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'user_devices' AND column_name = 'device_token') 
           AND NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'user_devices' AND column_name = 'fcm_token') THEN
            ALTER TABLE user_devices RENAME COLUMN device_token TO fcm_token;
        END IF;

        -- Ensure fcm_token exists
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'user_devices' AND column_name = 'fcm_token') THEN
            ALTER TABLE user_devices ADD COLUMN fcm_token TEXT;
        END IF;

        -- We want device_id to be the primary key if it's not already
        -- (This is complex in SQL if another PK exists, so we'll just ensure it has a unique index at least if we can't easily swap PK)
        -- But for user_devices, it's safer to just recreate or add a UNIQUE constraint.
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'user_devices_device_id_key') THEN
           ALTER TABLE user_devices ADD CONSTRAINT user_devices_device_id_key UNIQUE (device_id);
        END IF;

    ELSE
        CREATE TABLE user_devices (
            device_id TEXT PRIMARY KEY,
            fcm_token TEXT,
            barangay VARCHAR(100),
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
    END IF;
END $$;

-- Enable RLS for user_devices
ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow anyone to update their own device" ON user_devices;
CREATE POLICY "Allow anyone to update their own device" ON user_devices FOR ALL TO public USING (true) WITH CHECK (true);


-- 2. FIX SPECIAL COLLECTIONS TABLE (FROM V3)
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'special_collections') THEN
        -- Add/Fix resident_id
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'special_collections' AND column_name = 'resident_id') THEN
            ALTER TABLE special_collections ADD COLUMN resident_id TEXT;
        ELSE
            ALTER TABLE special_collections ALTER COLUMN resident_id TYPE TEXT USING resident_id::text;
        END IF;

        -- Remove preferred_date if it still exists
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'special_collections' AND column_name = 'preferred_date') THEN
            ALTER TABLE special_collections DROP COLUMN preferred_date;
        END IF;

        -- Ensure other columns exist
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'special_collections' AND column_name = 'waste_type') THEN
            ALTER TABLE special_collections ADD COLUMN waste_type TEXT;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'special_collections' AND column_name = 'estimated_quantity') THEN
            ALTER TABLE special_collections ADD COLUMN estimated_quantity TEXT;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'special_collections' AND column_name = 'pickup_location') THEN
            ALTER TABLE special_collections ADD COLUMN pickup_location TEXT;
        END IF;
    END IF;
END $$;

-- 3. FIX USER_NOTIFICATIONS TABLE (FROM V3)
CREATE TABLE IF NOT EXISTS user_notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id TEXT, -- Linked to resident_id
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

-- 4. RESET POLICIES
ALTER TABLE special_collections ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can insert special_collections" ON special_collections;
CREATE POLICY "Anyone can insert special_collections" ON special_collections FOR INSERT TO public WITH CHECK (true);
DROP POLICY IF EXISTS "Anyone can select special_collections" ON special_collections;
CREATE POLICY "Anyone can select special_collections" ON special_collections FOR SELECT TO public USING (true);

ALTER TABLE user_notifications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Public read user_notifications" ON user_notifications;
CREATE POLICY "Public read user_notifications" ON user_notifications FOR SELECT TO public USING (true);
DROP POLICY IF EXISTS "Anyone can insert user_notifications" ON user_notifications;
CREATE POLICY "Anyone can insert user_notifications" ON user_notifications FOR INSERT TO public WITH CHECK (true);

-- 5. RELOAD SCHEMA CACHE
NOTIFY pgrst, 'reload schema';
