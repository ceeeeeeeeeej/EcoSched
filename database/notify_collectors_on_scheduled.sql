-- Trigger to notify all collectors when a special collection is scheduled
-- This ensures that collectors are alerted about new assigned tasks

CREATE OR REPLACE FUNCTION public.notify_collectors_on_special_collection_scheduled()
RETURNS TRIGGER AS $$
DECLARE
    collector_user RECORD;
    resident_name TEXT;
    waste_type TEXT;
    scheduled_date_str TEXT;
BEGIN
    -- Only trigger when status changes to 'scheduled'
    IF (NEW.status = 'scheduled' AND (OLD.status IS NULL OR OLD.status != 'scheduled')) THEN
        
        -- Get resident name from metadata or fallback
        resident_name := COALESCE(NEW.metadata->>'residentName', 'A resident');
        waste_type := COALESCE(NEW.waste_type, 'waste');
        scheduled_date_str := to_char(NEW.scheduled_date, 'YYYY-MM-DD');

        -- Loop through all users with collector role
        FOR collector_user IN 
            SELECT id FROM "public"."users" 
            WHERE role = 'collector' AND status = 'active'
        LOOP
            INSERT INTO "public"."notifications" (
                "user_id",
                "title",
                "message",
                "type",
                "is_read",
                "created_at"
            ) VALUES (
                collector_user.id,
                'Special Collection Scheduled',
                'A collection for ' || resident_name || ' (' || waste_type || ') is scheduled for ' || scheduled_date_str || '.',
                'special_collection',
                false,
                NOW()
            );
        END LOOP;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger
DROP TRIGGER IF EXISTS on_special_collection_scheduled ON "public"."special_collections";

CREATE TRIGGER on_special_collection_scheduled
AFTER UPDATE ON "public"."special_collections"
FOR EACH ROW
EXECUTE FUNCTION public.notify_collectors_on_special_collection_scheduled();

-- Add a comment for documentation
COMMENT ON FUNCTION public.notify_collectors_on_special_collection_scheduled() IS 'Notifies all active collectors when a special collection status is updated to scheduled.';
