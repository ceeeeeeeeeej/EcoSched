-- =================================================================
-- FINAL NOTIFICATION FIX FOR COLLECTORS (V10)
-- Bypasses 'profiles' table to avoid relation errors.
-- Target Admins via 'users' and Collectors via 'registered_collectors'.
-- =================================================================

-- 1. Function to handle New Special Collection Request
CREATE OR REPLACE FUNCTION public.handle_new_special_collection()
RETURNS TRIGGER AS $$
BEGIN
    -- Notify Admins/Superadmins
    INSERT INTO public.user_notifications (user_id, title, message, type, priority, is_read, created_at)
    SELECT id::TEXT, 'New Pickup Request', 'A resident has requested a special collection for ' || COALESCE(NEW.waste_type, 'Waste') || '.', 'info', 'medium', false, NOW()
    FROM public.users
    WHERE role::text ILIKE 'admin' OR role::text ILIKE 'superadmin';

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Function to handle Special Collection Status Changes
CREATE OR REPLACE FUNCTION public.notify_collectors_on_special_collection_status_change()
RETURNS TRIGGER AS $$
DECLARE
    collector_user RECORD;
    w_type TEXT;
    s_date_time TEXT;
    notif_title TEXT;
    notif_msg TEXT;
BEGIN
    w_type := COALESCE(NEW.waste_type, 'General Waste');
    s_date_time := to_char(NEW.scheduled_date, 'YYYY-MM-DD "at" HH24:MI');

    -- Check status case-insensitively
    IF (NEW.status::text ILIKE 'scheduled') THEN
        notif_title := '🚨 New Special Collection';
        notif_msg := 'New collection from special collection for ' || w_type || ' on ' || s_date_time || '.';
    ELSIF (NEW.status::text ILIKE 'cancelled') THEN
        notif_title := '🚨 Collection Cancelled';
        notif_msg := 'Scheduled pickup for ' || COALESCE(NEW.resident_name, 'Resident') || ' (' || w_type || ') has been cancelled.';
    ELSE
        -- No notification for other statuses
        RETURN NEW;
    END IF;

    -- Notify ALL Collectors from known tables
    FOR collector_user IN 
        SELECT id::TEXT as target_id FROM public.users WHERE role::text ILIKE 'collector'
        UNION
        SELECT user_id::TEXT as target_id FROM public.registered_collectors
    LOOP
        -- Only insert if not already notified in the last 10 seconds
        IF NOT EXISTS (
            SELECT 1 FROM public.user_notifications 
            WHERE user_id = collector_user.target_id 
            AND title = notif_title 
            AND created_at > NOW() - INTERVAL '10 seconds'
        ) THEN
            INSERT INTO public.user_notifications (user_id, title, message, type, priority, is_read, created_at)
            VALUES (collector_user.target_id, notif_title, notif_msg, 'alert', 'high', false, NOW());
        END IF;
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Cleanup unwanted notifications
DELETE FROM public.user_notifications
WHERE (title ILIKE '%New Pickup Request%' OR title ILIKE '%Collection Started%')
AND user_id IN (
    SELECT id::TEXT FROM public.users WHERE role::text ILIKE 'collector'
    UNION
    SELECT user_id::TEXT FROM public.registered_collectors
);

-- 4. Re-link triggers
DROP TRIGGER IF EXISTS on_special_collection_created ON public.special_collections;
CREATE TRIGGER on_special_collection_created
AFTER INSERT ON public.special_collections
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_special_collection();

DROP TRIGGER IF EXISTS on_special_collection_status_change ON public.special_collections;
CREATE TRIGGER on_special_collection_status_change
AFTER UPDATE ON public.special_collections
FOR EACH ROW
EXECUTE FUNCTION public.notify_collectors_on_special_collection_status_change();
