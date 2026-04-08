-- Sync Database with New Firmware (ECO-VIC-24)
-- This script removes "Almost Full" logic and adds support for the new "bin_status" and "distance" fields.

-- 1. Add bin_status column if it doesn't exist
ALTER TABLE bins ADD COLUMN IF NOT EXISTS bin_status TEXT DEFAULT 'normal';

-- 2. Ensure ECO-VIC-24 bin exists
INSERT INTO bins (bin_id, address, zone, status)
VALUES ('ECO-VIC-24', 'Barangay Victoria', 'Victoria', 'active')
ON CONFLICT (bin_id) DO UPDATE SET 
    address = EXCLUDED.address,
    zone = EXCLUDED.zone;

-- 3. Trigger to calculate fill_level from distance automatically
-- This keeps the dashboard progress bars working.
CREATE OR REPLACE FUNCTION calculate_fill_level_from_distance()
RETURNS TRIGGER AS $$
DECLARE
    bin_h NUMERIC := 105.0; -- Default height from firmware
BEGIN
    -- Only calculate if distance is provided and changed
    IF (NEW.distance IS NOT NULL AND (OLD.distance IS NULL OR NEW.distance IS DISTINCT FROM OLD.distance)) THEN
        NEW.fill_level := GREATEST(0, LEAST(100, ROUND(((bin_h - NEW.distance) / bin_h) * 100)));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tr_calculate_fill_level ON bins;
CREATE TRIGGER tr_calculate_fill_level
BEFORE INSERT OR UPDATE ON bins
FOR EACH ROW
EXECUTE FUNCTION calculate_fill_level_from_distance();

-- 4. Update Notification Trigger
-- Now triggers based on bin_status rather than fill_level
CREATE OR REPLACE FUNCTION notify_full_bin()
RETURNS TRIGGER AS $$
DECLARE
    admin_user RECORD;
    barangay_name TEXT;
BEGIN
    -- Extract barangay from address if possible
    barangay_name := COALESCE(NEW.address, NEW.zone);

    -- Trigger when status becomes 'full'
    IF (NEW.bin_status = 'full' AND (OLD.bin_status IS NULL OR OLD.bin_status != 'full')) THEN
        FOR admin_user IN SELECT id FROM users WHERE role IN ('admin', 'superadmin') LOOP
            INSERT INTO notifications (user_id, title, message, type, metadata)
            VALUES (
                admin_user.id,
                '🚨 Bin Full Alert',
                'In ' || barangay_name || ', bin ' || NEW.bin_id || ' is full! Please collect waste to prevent overflow.',
                'alert',
                jsonb_build_object('bin_id', NEW.bin_id, 'fill_level', NEW.fill_level, 'bin_status', NEW.bin_status)
            );
        END LOOP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. Update Logging Trigger
-- Removes "ALMOST FULL" status from logs
CREATE OR REPLACE FUNCTION log_bin_fill_level_change()
RETURNS TRIGGER AS $$
BEGIN
    -- Only log if the fill_level or status actually changed
    IF (NEW.fill_level IS DISTINCT FROM OLD.fill_level OR NEW.bin_status IS DISTINCT FROM OLD.bin_status) THEN
        INSERT INTO bin_logs (
            bin_id, old_fill_level, new_fill_level, status, gps_lat, gps_lng, created_at
        ) VALUES (
            NEW.bin_id, OLD.fill_level, NEW.fill_level, UPPER(NEW.bin_status), NEW.gps_lat, NEW.gps_lng, NOW()
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
