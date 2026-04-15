-- EMERGENCY FIX: ADD MISSING COLUMNS TO user_devices
-- Run this in your Supabase SQL Editor

DO $$ 
BEGIN 
    -- 1. Ensure 'updated_at' column exists in user_devices
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_devices' AND column_name = 'updated_at') THEN
        ALTER TABLE public.user_devices ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- Optional: update PostgreSQL schema cache
NOTIFY pgrst, 'reload schema';
