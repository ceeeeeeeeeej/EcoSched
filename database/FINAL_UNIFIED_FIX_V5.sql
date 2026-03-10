-- ===============================================
-- FINAL UNIFIED SCHEMA FIX (v5 - RECREATE TABLES)
-- ===============================================

-- 1. CLEAN RECREATION OF USER_DEVICES
DROP TABLE IF EXISTS user_devices CASCADE;
CREATE TABLE user_devices (
    device_id TEXT PRIMARY KEY,
    fcm_token TEXT,
    barangay TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS and add wide-open policies for anonymous community app
ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public all access on user_devices" ON user_devices FOR ALL TO public USING (true) WITH CHECK (true);

-- 2. ENSURE USER_NOTIFICATIONS IS CONSISTENT
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'user_notifications') THEN
        CREATE TABLE user_notifications (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            user_id TEXT,
            barangay TEXT,
            title TEXT NOT NULL,
            message TEXT NOT NULL,
            type TEXT DEFAULT 'info',
            is_read BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
    END IF;
END $$;

-- Fix user_id column if it exists but is wrong type
ALTER TABLE user_notifications ALTER COLUMN user_id TYPE TEXT USING user_id::text;

-- Ensure RLS is open for targeted notifications
ALTER TABLE user_notifications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can view their own notifications" ON user_notifications;
DROP POLICY IF EXISTS "Public read user_notifications" ON user_notifications;
CREATE POLICY "Public read user_notifications" ON user_notifications FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "Anyone can insert notifications" ON user_notifications;
DROP POLICY IF EXISTS "Anyone can insert user_notifications" ON user_notifications;
CREATE POLICY "Anyone can insert user_notifications" ON user_notifications FOR INSERT TO public WITH CHECK (true);

-- 3. FIX SPECIAL_COLLECTIONS RLS (Final check)
ALTER TABLE special_collections ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can select special_collections" ON special_collections;
CREATE POLICY "Anyone can select special_collections" ON special_collections FOR SELECT TO public USING (true);
DROP POLICY IF EXISTS "Anyone can insert special_collections" ON special_collections;
CREATE POLICY "Anyone can insert special_collections" ON special_collections FOR INSERT TO public WITH CHECK (true);

-- Reload
NOTIFY pgrst, 'reload schema';
