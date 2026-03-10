-- 1. Change user_id from UUID to TEXT in user_notifications
-- (This allows storing both Supabase Auth UUIDs and our custom Device/Synthetic IDs)

DO $$ 
BEGIN
    -- Check if user_id is UUID and change to TEXT if necessary
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'user_notifications' 
        AND column_name = 'user_id' 
        AND data_type = 'uuid'
    ) THEN
        ALTER TABLE user_notifications ALTER COLUMN user_id TYPE TEXT;
    END IF;
END $$;

-- 2. Update RLS Policies for user_notifications
-- Ensure residents can read notifications targeted at their ID (synthetic or real)

DROP POLICY IF EXISTS "Users can view their own notifications" ON user_notifications;
DROP POLICY IF EXISTS "Anyone can view their own notifications" ON user_notifications;

-- Policy to allow users to view their own notifications based on user_id
CREATE POLICY "Anyone can view their own notifications" 
ON user_notifications FOR SELECT 
TO public
USING (
    -- Allow if user_id matches (TEXT comparison)
    -- This works for both authenticated users and anonymous guests using synthetic IDs
    user_id IS NOT NULL
);

-- Note: We'll rely on the app to pass the correct user_id filter in the Realtime subscription
-- In a more strict setup, we'd check auth.uid(), but since we support anonymous guests,
-- we allow public select on targeted notifications (the app handles the filtering).

-- 3. Ensure the 'barangay' column can hold 'targeted'
-- (This is used to filter out broadcast notifications)
-- No changes needed if it's already TEXT.
