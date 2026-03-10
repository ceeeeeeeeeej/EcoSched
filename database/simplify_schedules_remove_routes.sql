-- Migration: Simplify schedules to barangay-based system
-- Remove route dependencies and add automatic notifications

-- Step 1: Add barangay column if it doesn't exist (using service_area as barangay)
ALTER TABLE scheduled_pickups ADD COLUMN IF NOT EXISTS barangay TEXT;

-- Step 2: Populate barangay from service_area if empty
UPDATE scheduled_pickups 
SET barangay = service_area 
WHERE barangay IS NULL AND service_area IS NOT NULL;

-- Step 3: Remove route-related columns (if they exist)
ALTER TABLE scheduled_pickups DROP COLUMN IF EXISTS route_id;
ALTER TABLE scheduled_pickups DROP COLUMN IF EXISTS route_name;
ALTER TABLE scheduled_pickups DROP COLUMN IF EXISTS pickup_route;

-- Step 4: Create function to notify residents when schedule changes
CREATE OR REPLACE FUNCTION notify_schedule_change()
RETURNS TRIGGER AS $$
DECLARE
    schedule_type TEXT;
    notification_title TEXT;
    notification_message TEXT;
BEGIN
    -- Determine schedule type
    schedule_type := COALESCE(NEW.waste_type, 'Waste Collection');
    
    -- Build notification content
    IF TG_OP = 'INSERT' THEN
        notification_title := 'New Collection Schedule';
        notification_message := schedule_type || ' scheduled for ' || 
                                TO_CHAR(NEW.schedule_date, 'Mon DD, YYYY') || ' at ' || 
                                COALESCE(NEW.collection_time, 'TBD') || ' in ' || 
                                COALESCE(NEW.barangay, NEW.service_area, 'your area');
    ELSIF TG_OP = 'UPDATE' THEN
        -- Only notify if date or time changed
        IF (NEW.schedule_date != OLD.schedule_date OR NEW.collection_time != OLD.collection_time) THEN
            notification_title := 'Collection Schedule Updated';
            notification_message := schedule_type || ' rescheduled from ' || 
                                    TO_CHAR(OLD.schedule_date, 'Mon DD, YYYY') || ' to ' || 
                                    TO_CHAR(NEW.schedule_date, 'Mon DD, YYYY') || ' at ' || 
                                    COALESCE(NEW.collection_time, 'TBD') || ' in ' || 
                                    COALESCE(NEW.barangay, NEW.service_area, 'your area');
        ELSE
            -- No date/time change, don't notify
            RETURN NEW;
        END IF;
    END IF;
    
    -- Insert notifications for all residents in the affected barangay
    INSERT INTO notifications (user_id, title, message, type, read, created_at)
    SELECT 
        u.id,
        notification_title,
        notification_message,
        'schedule_update',
        false,
        NOW()
    FROM users u
    WHERE (
        -- Match by location field (barangay)
        LOWER(TRIM(u.location)) = LOWER(TRIM(COALESCE(NEW.barangay, NEW.service_area)))
        OR
        -- Match by service_area field (for flexibility)
        LOWER(TRIM(u.service_area)) = LOWER(TRIM(COALESCE(NEW.barangay, NEW.service_area)))
    )
    AND u.role = 'resident'; -- Only notify residents
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 5: Drop existing trigger if it exists
DROP TRIGGER IF EXISTS on_schedule_change ON scheduled_pickups;

-- Step 6: Create trigger for schedule changes
CREATE TRIGGER on_schedule_change
    AFTER INSERT OR UPDATE ON scheduled_pickups
    FOR EACH ROW
    EXECUTE FUNCTION notify_schedule_change();

-- Step 7: Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_scheduled_pickups_barangay ON scheduled_pickups(barangay);
CREATE INDEX IF NOT EXISTS idx_scheduled_pickups_date ON scheduled_pickups(schedule_date);
CREATE INDEX IF NOT EXISTS idx_users_location ON users(location);
CREATE INDEX IF NOT EXISTS idx_users_service_area ON users(service_area);

-- Step 8: Update existing schedules to ensure barangay is populated
UPDATE scheduled_pickups 
SET barangay = COALESCE(barangay, service_area, 'Unknown')
WHERE barangay IS NULL OR barangay = '';

COMMENT ON COLUMN scheduled_pickups.barangay IS 'Barangay/zone for this collection schedule';
COMMENT ON TRIGGER on_schedule_change ON scheduled_pickups IS 'Automatically notifies residents in affected barangay when schedules are created or rescheduled';
