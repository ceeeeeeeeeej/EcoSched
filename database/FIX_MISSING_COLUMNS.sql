-- EMERGENCY FIX: ADD MISSING COLUMNS TO user_notifications
-- Run this in your Supabase SQL Editor

DO $$ 
BEGIN 
    -- 1. Ensure 'type' column exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notifications' AND column_name = 'type') THEN
        ALTER TABLE public.user_notifications ADD COLUMN type VARCHAR(50) DEFAULT 'info';
    END IF;

    -- 2. Ensure 'priority' column exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notifications' AND column_name = 'priority') THEN
        ALTER TABLE public.user_notifications ADD COLUMN priority VARCHAR(50) DEFAULT 'medium';
    END IF;

    -- 3. Ensure 'is_read' column exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notifications' AND column_name = 'is_read') THEN
        ALTER TABLE public.user_notifications ADD COLUMN is_read BOOLEAN DEFAULT FALSE;
    END IF;

    -- 4. Ensure 'barangay' column exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notifications' AND column_name = 'barangay') THEN
        ALTER TABLE public.user_notifications ADD COLUMN barangay VARCHAR(100);
    END IF;

    -- 5. Ensure 'metadata' column exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notifications' AND column_name = 'metadata') THEN
        ALTER TABLE public.user_notifications ADD COLUMN metadata JSONB DEFAULT '{}'::jsonb;
    END IF;

    -- 6. Ensure 'user_id' is TEXT (for compatibility)
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_notifications' AND column_name = 'user_id' AND data_type = 'uuid') THEN
        ALTER TABLE public.user_notifications ALTER COLUMN user_id TYPE TEXT;
    END IF;
END $$;

-- Enable Realtime (Crucial for dashboard updates)
BEGIN;
  DROP PUBLICATION IF EXISTS supabase_realtime;
  CREATE PUBLICATION supabase_realtime FOR TABLE user_notifications;
COMMIT;
