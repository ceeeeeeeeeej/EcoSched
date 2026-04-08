-- Bin Fill Level Logger Setup (Robust Version)
-- This script creates a logging table and a trigger to automatically
-- record changes to the "fill_level" in the "bins" table.

-- 1. (Optional) Cleanup - Uncomment if you want to start fresh
-- DROP TABLE IF EXISTS bin_logs CASCADE;

-- 2. Create the bin_logs table
-- This stores the history of fill level changes along with GPS coordinates.
CREATE TABLE IF NOT EXISTS bin_logs (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    bin_id VARCHAR(50) NOT NULL,
    old_fill_level NUMERIC,
    new_fill_level NUMERIC,
    status TEXT, -- Added to store "Full", "Almost Full", "Normal"
    gps_lat NUMERIC,
    gps_lng NUMERIC,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Ensure the column exists if the table was created previously without it
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='bin_logs' AND column_name='created_at') THEN
        ALTER TABLE bin_logs ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- 3. Create the trigger function
-- This function is executed whenever a row in the "bins" table is updated.
-- SECURITY DEFINER allows it to run with owner permissions (bypassing RLS for log insertion).
CREATE OR REPLACE FUNCTION log_bin_fill_level_change()
RETURNS TRIGGER AS $$
DECLARE
    status_text TEXT;
BEGIN
    -- Match your firmware thresholds and exact strings
    IF (NEW.fill_level < 30) THEN
        status_text := 'NOT FULL';
    ELSIF (NEW.fill_level < 75) THEN
        status_text := 'ALMOST FULL';
    ELSE
        status_text := 'FULL';
    END IF;

    -- Only log if the fill_level actually changed
    IF (NEW.fill_level IS DISTINCT FROM OLD.fill_level) THEN
        INSERT INTO bin_logs (
            bin_id, old_fill_level, new_fill_level, status, gps_lat, gps_lng, created_at
        ) VALUES (
            NEW.bin_id, OLD.fill_level, NEW.fill_level, status_text, NEW.gps_lat, NEW.gps_lng, NOW()
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER; 

-- 4. Create the trigger
DROP TRIGGER IF EXISTS tr_log_bin_fill_level_change ON bins;
CREATE TRIGGER tr_log_bin_fill_level_change
AFTER UPDATE ON bins
FOR EACH ROW
EXECUTE FUNCTION log_bin_fill_level_change();

-- 5. Enable Row Level Security (RLS)
ALTER TABLE bin_logs ENABLE ROW LEVEL SECURITY;

-- 6. Standard Read Policy for Admin
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'bin_logs' AND policyname = 'Admin view all bin_logs'
    ) THEN
        CREATE POLICY "Admin view all bin_logs" ON bin_logs 
        FOR SELECT 
        USING (
            EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('admin', 'superadmin'))
        );
    END IF;
END $$;

COMMENT ON TABLE bin_logs IS 'History of bin fill level changes and associated GPS telemetry.';
