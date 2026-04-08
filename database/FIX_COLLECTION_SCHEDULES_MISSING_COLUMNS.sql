-- FIX: ADD MISSING COLUMNS TO collection_schedules
-- Run this in your Supabase SQL Editor to resolve the 'pickup_location' error

DO $$ 
BEGIN 
    -- 1. Ensure 'name' column exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'collection_schedules' AND column_name = 'name') THEN
        ALTER TABLE public.collection_schedules ADD COLUMN name VARCHAR(255) DEFAULT 'Eco Collection';
    END IF;

    -- 2. Ensure 'scheduled_date' column exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'collection_schedules' AND column_name = 'scheduled_date') THEN
        ALTER TABLE public.collection_schedules ADD COLUMN scheduled_date TIMESTAMP WITH TIME ZONE;
    END IF;

    -- 3. Ensure 'resident_name' column exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'collection_schedules' AND column_name = 'resident_name') THEN
        ALTER TABLE public.collection_schedules ADD COLUMN resident_name VARCHAR(255);
    END IF;

    -- 4. Ensure 'pickup_location' column exists
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'collection_schedules' AND column_name = 'pickup_location') THEN
        ALTER TABLE public.collection_schedules ADD COLUMN pickup_location TEXT;
    END IF;

END $$;

-- Refresh schema cache (Supabase specific)
NOTIFY pgrst, 'reload schema';
