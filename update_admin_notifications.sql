-- Update Admin Notifications Triggers

-- 1. Update Special Collections Trigger to use correct table
CREATE OR REPLACE FUNCTION public.handle_new_special_collection()
RETURNS TRIGGER AS $$
DECLARE
    admin_user RECORD;
    resident_name TEXT;
BEGIN
    -- Try to get resident name from metadata if available, else use a fallback
    resident_name := COALESCE(NEW.metadata->>'resident_name', 'A resident');

    -- Loop through all admins and superadmins
    FOR admin_user IN 
        SELECT id FROM "public"."users" 
        WHERE role IN ('admin', 'superadmin')
    LOOP
        INSERT INTO "public"."user_notifications" (
            "user_id",
            "title",
            "message",
            "type",
            "priority",
            "is_read",
            "created_at"
        ) VALUES (
            admin_user.id,
            'New Pickup Request',
            resident_name || ' has requested a special collection.',
            'special_collection',
            'medium',
            false,
            NOW()
        );
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Create Trigger for Resident Feedback
CREATE OR REPLACE FUNCTION public.handle_new_feedback()
RETURNS TRIGGER AS $$
DECLARE
    admin_user RECORD;
    resident_name TEXT;
    user_record RECORD;
BEGIN
    -- Fetch resident name
    SELECT first_name, last_name INTO user_record FROM "public"."users" WHERE id = NEW.user_id;
    IF user_record.first_name IS NOT NULL THEN
        resident_name := user_record.first_name || ' ' || COALESCE(user_record.last_name, '');
    ELSE
        resident_name := 'A resident';
    END IF;

    -- Loop through all admins and superadmins
    FOR admin_user IN 
        SELECT id FROM "public"."users" 
        WHERE role IN ('admin', 'superadmin')
    LOOP
        INSERT INTO "public"."user_notifications" (
            "user_id",
            "title",
            "message",
            "type",
            "priority",
            "is_read",
            "created_at"
        ) VALUES (
            admin_user.id,
            'New Feedback Received',
            resident_name || ' submitted new feedback (' || NEW.rating || ' stars).',
            'feedback',
            'medium',
            false,
            NOW()
        );
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger for Resident Feedback
DROP TRIGGER IF EXISTS on_feedback_created ON "public"."resident_feedback";
CREATE TRIGGER on_feedback_created
AFTER INSERT ON "public"."resident_feedback"
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_feedback();


-- 3. Create Trigger for Bin Full Alerts
CREATE OR REPLACE FUNCTION public.handle_bin_full()
RETURNS TRIGGER AS $$
DECLARE
    admin_user RECORD;
BEGIN
    -- Only trigger if the bin goes from < 90 to >= 90
    IF (NEW.fill_level >= 90 AND (OLD.fill_level < 90 OR OLD.fill_level IS NULL)) THEN
        -- Loop through all admins and superadmins
        FOR admin_user IN 
            SELECT id FROM "public"."users" 
            WHERE role IN ('admin', 'superadmin')
        LOOP
            INSERT INTO "public"."user_notifications" (
                "user_id",
                "title",
                "message",
                "type",
                "priority",
                "is_read",
                "created_at"
            ) VALUES (
                admin_user.id,
                'Bin Full Alert',
                'Bin ' || COALESCE(NEW.bin_id, 'Unknown') || ' at ' || COALESCE(NEW.address, COALESCE(NEW.zone, 'Unknown Location')) || ' is ' || NEW.fill_level || '% full.',
                'alert',
                'high',
                false,
                NOW()
            );
        END LOOP;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Overwrite the existing bin_full_notification_trigger
DROP TRIGGER IF EXISTS bin_full_notification_trigger ON "public"."bins";
CREATE TRIGGER bin_full_notification_trigger
AFTER UPDATE ON "public"."bins"
FOR EACH ROW
EXECUTE FUNCTION public.handle_bin_full();

-- Ensure previously created notify_full_bin function is dropped to avoid confusion
DROP FUNCTION IF EXISTS public.notify_full_bin();
