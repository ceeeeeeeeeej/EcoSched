-- 1. FIX SCHEMA: Add missing columns for scheduling and notifications
-- device_token added for individual tracking
ALTER TABLE special_collections ADD COLUMN IF NOT EXISTS resident_name VARCHAR(255);
ALTER TABLE special_collections ADD COLUMN IF NOT EXISTS scheduled_time VARCHAR(50);
ALTER TABLE special_collections ADD COLUMN IF NOT EXISTS device_token TEXT;
-- metadata column check (some code still uses it)
ALTER TABLE special_collections ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb;

-- Add barangay to notifications for targeted broadcasts
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS barangay VARCHAR(100);

-- 2. CREATE user_devices table for token mapping
CREATE TABLE IF NOT EXISTS user_devices (
    device_token TEXT PRIMARY KEY,
    barangay VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on user_devices
ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;

-- Allow anyone to upsert their own device token
CREATE POLICY "Allow anonymous upsert user_devices" ON user_devices
FOR ALL TO public
USING (true)
WITH CHECK (true);

-- 3. Add barangay and purok to users (if missing)
ALTER TABLE users ADD COLUMN IF NOT EXISTS barangay VARCHAR(100);
ALTER TABLE users ADD COLUMN IF NOT EXISTS purok VARCHAR(100);

-- 4. DROP ALL OLD POLICIES to start fresh
DROP POLICY IF EXISTS "Admin manage special_collections" ON special_collections;
DROP POLICY IF EXISTS "Staff manage special_collections" ON special_collections;
DROP POLICY IF EXISTS "Users view/cancel own special_collections" ON special_collections;
DROP POLICY IF EXISTS "Anyone can view special_collections" ON special_collections;

-- 5. CREATE NEW BROAD POLICY for Staff (Admins and Collectors)
CREATE POLICY "Staff manage special_collections" ON special_collections 
FOR ALL TO authenticated 
USING (
    EXISTS (
        SELECT 1 FROM users 
        WHERE id = auth.uid() 
        AND role IN ('admin', 'superadmin', 'collector')
    )
);

-- 6. VALIDATION: Check your role
SELECT email, role FROM users WHERE id = auth.uid();
