-- Migration: Fix resident notifications trigger to target collection_schedules
-- This ensures residents receive persistent notifications when schedules are created or updated

-- Step 1: Create or replace the notification function
CREATE OR REPLACE FUNCTION notify_collection_schedule_change()
RETURNS TRIGGER AS $$
DECLARE
    notification_title TEXT;
    notification_message TEXT;
BEGIN
    -- Build notification content
    IF TG_OP = 'INSERT' THEN
        notification_title := 'New Collection Schedule';
        notification_message := NEW.name || ' scheduled for ' || 
                                TO_CHAR(NEW.scheduled_date, 'Mon DD, YYYY') || ' at ' || 
                                TO_CHAR(NEW.scheduled_date, 'HH:MI AM') || ' in ' || 
                                NEW.zone;
    ELSIF TG_OP = 'UPDATE' THEN
        -- Only notify if date or time changed significantly
        IF (NEW.scheduled_date != OLD.scheduled_date OR NEW.is_rescheduled = true) THEN
            notification_title := 'Collection Schedule Updated';
            notification_message := NEW.name || ' rescheduled from ' || 
                                    TO_CHAR(OLD.scheduled_date, 'Mon DD, YYYY HH:MI AM') || ' to ' || 
                                    TO_CHAR(NEW.scheduled_date, 'Mon DD, YYYY HH:MI AM') || ' in ' || 
                                    NEW.zone;
            
            -- Add reason if available
            IF NEW.rescheduled_reason IS NOT NULL AND NEW.rescheduled_reason != '' THEN
                notification_message := notification_message || '. Reason: ' || NEW.rescheduled_reason;
            END IF;
        ELSE
            -- No significant change, don't notify
            RETURN NEW;
        END IF;
    END IF;
    
    -- Insert notifications for all residents in the affected zone
    INSERT INTO notifications (user_id, title, message, type, is_read, created_at)
    SELECT 
        u.id,
        notification_title,
        notification_message,
        'warning', -- Match Flutter's expected type for reschedules
        false,
        NOW()
    FROM users u
    WHERE (
        LOWER(TRIM(u.location)) = LOWER(TRIM(NEW.zone))
        OR
        LOWER(TRIM(u.service_area)) = LOWER(TRIM(NEW.zone))
    )
    AND u.role = 'resident'; -- Only notify residents
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 2: Drop existing trigger if it exists
DROP TRIGGER IF EXISTS on_collection_schedule_change ON collection_schedules;

-- Step 3: Create trigger for collection_schedules
CREATE TRIGGER on_collection_schedule_change
    AFTER INSERT OR UPDATE ON collection_schedules
    FOR EACH ROW
    EXECUTE FUNCTION notify_collection_schedule_change();

-- Step 4: Ensure notifications table has appropriate indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);

COMMENT ON FUNCTION notify_collection_schedule_change() IS 'Automatically notifies residents in affected zone when collection schedules are created or updated';
