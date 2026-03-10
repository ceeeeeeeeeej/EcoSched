-- Reconcile Schema: Standardize Notification and Device Tracking
-- This script ensures all tables use consistent naming and support targeted notifications.

-- 1. Standardize user_notifications
-- Ensure it has the necessary columns for both broadcast and targeted alerts.
CREATE TABLE IF NOT EXISTS user_notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID, -- For targeted notifications (links to device synthetic ID)
    barangay VARCHAR(100), -- For broadcast notifications
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'info',
    priority VARCHAR(50) DEFAULT 'medium',
    is_read BOOLEAN DEFAULT FALSE,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Realtime for user_notifications
-- (This is typically done via the Supabase Dashboard, but we can attempt to add it to the publication)
BEGIN;
  DROP PUBLICATION IF EXISTS supabase_realtime;
  CREATE PUBLICATION supabase_realtime FOR TABLE user_notifications;
COMMIT;

-- 2. Update special_collections to use resident_id (UUID)
-- This allows us to link a request back to a specific anonymous "user" (device).
ALTER TABLE special_collections ADD COLUMN IF NOT EXISTS resident_id UUID;
ALTER TABLE special_collections ADD COLUMN IF NOT EXISTS resident_name VARCHAR(255);
ALTER TABLE special_collections ADD COLUMN IF NOT EXISTS resident_barangay VARCHAR(100);
ALTER TABLE special_collections ADD COLUMN IF NOT EXISTS resident_purok VARCHAR(100);

-- 3. Standardize user_devices
-- Use device_id as PK and fcm_token for push notifications.
DO $$ 
BEGIN 
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'user_devices') THEN
        -- Check if columns exist and rename if necessary or add missing ones
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'user_devices' AND column_name = 'device_id') THEN
            ALTER TABLE user_devices ADD COLUMN device_id TEXT;
        END IF;
        
        -- If device_token exists but fcm_token doesn't, rename it
        IF EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'user_devices' AND column_name = 'device_token') 
           AND NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'user_devices' AND column_name = 'fcm_token') THEN
            ALTER TABLE user_devices RENAME COLUMN device_token TO fcm_token;
        END IF;
    ELSE
        CREATE TABLE user_devices (
            device_id TEXT PRIMARY KEY,
            fcm_token TEXT,
            barangay VARCHAR(100),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );
    END IF;
END $$;

-- 4. Clean up old notifications table (Move data if exists, then drop)
-- (Optional: only if you are sure you want to deprecate 'notifications')
-- INSERT INTO user_notifications (title, message, created_at)
-- SELECT title, message, created_at FROM notifications;
-- DROP TABLE IF EXISTS notifications;

-- Enable RLS logic
ALTER TABLE user_notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read user_notifications" ON user_notifications FOR SELECT USING (true);
CREATE POLICY "System insert user_notifications" ON user_notifications FOR INSERT WITH CHECK (true);

ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow anyone to update their own device" ON user_devices FOR ALL USING (true);
