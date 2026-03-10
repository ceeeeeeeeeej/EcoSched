-- SQL Migration: Fix missing columns in resident_feedback table
-- Run this in your Supabase SQL Editor

DO $$ 
BEGIN
    -- 1. Check if the table exists
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'resident_feedback') THEN
        
        -- 2. Add feedback_text if it's missing
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'resident_feedback' AND column_name = 'feedback_text') THEN
            ALTER TABLE resident_feedback ADD COLUMN feedback_text TEXT;
            RAISE NOTICE 'Added missing column: feedback_text';
        ELSE
            RAISE NOTICE 'Column feedback_text already exists.';
        END IF;
        
        -- 3. Add feedback_type if it's missing
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'resident_feedback' AND column_name = 'feedback_type') THEN
            ALTER TABLE resident_feedback ADD COLUMN feedback_type VARCHAR(50);
            RAISE NOTICE 'Added missing column: feedback_type';
        ELSE
            RAISE NOTICE 'Column feedback_type already exists.';
        END IF;
        
        -- 4. Add status if it's missing
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'resident_feedback' AND column_name = 'status') THEN
            ALTER TABLE resident_feedback ADD COLUMN status VARCHAR(20) DEFAULT 'pending';
            RAISE NOTICE 'Added missing column: status';
        ELSE
            RAISE NOTICE 'Column status already exists.';
        END IF;

    ELSE
        RAISE NOTICE 'Table resident_feedback does not exist. Please run the full schema script.';
    END IF;
END $$;
