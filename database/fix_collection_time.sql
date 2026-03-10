-- SQL Migration: Fix missing collection_time column in collection_schedules
-- Run this in your Supabase SQL Editor

DO $$ 
BEGIN
    -- 1. Check if the table exists
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'collection_schedules') THEN
        
        -- 2. Add collection_time if it's missing
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'collection_schedules' AND column_name = 'collection_time') THEN
            ALTER TABLE collection_schedules ADD COLUMN collection_time TIMESTAMP WITH TIME ZONE;
            RAISE NOTICE 'Added missing column: collection_time';
            
            -- 3. Attempt to migrate data from potential alternative names
            -- Check for scheduled_date
            IF EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'collection_schedules' AND column_name = 'scheduled_date') THEN
                UPDATE collection_schedules SET collection_time = scheduled_date WHERE collection_time IS NULL;
                RAISE NOTICE 'Migrated data from scheduled_date to collection_time';
            END IF;
            
            -- Check for scheduled_time
            IF EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'collection_schedules' AND column_name = 'scheduled_time') THEN
                UPDATE collection_schedules SET collection_time = scheduled_time WHERE collection_time IS NULL;
                RAISE NOTICE 'Migrated data from scheduled_time to collection_time';
            END IF;
            
            -- Set a default value for any remaining NULLs if NOT NULL constraint is desired later
            -- UPDATE collection_schedules SET collection_time = NOW() WHERE collection_time IS NULL;
            
            -- 4. Apply NOT NULL constraint if safe
            -- ALTER TABLE collection_schedules ALTER COLUMN collection_time SET NOT NULL;
        ELSE
            RAISE NOTICE 'Column collection_time already exists.';
        END IF;

        -- 5. Ensure the index exists
        IF NOT EXISTS (SELECT FROM pg_indexes WHERE tablename = 'collection_schedules' AND indexname = 'idx_collection_schedules_time') THEN
            CREATE INDEX idx_collection_schedules_time ON collection_schedules(collection_time);
        END IF;

    ELSE
        RAISE NOTICE 'Table collection_schedules does not exist. Please run the full schema script.';
    END IF;
END $$;
