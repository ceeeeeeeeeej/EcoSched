-- =================================================================
-- REVISED CONSOLIDATED NOTIFICATION FIX FOR COLLECTORS (V7)
-- Multi-table lookup to ensure collectors are correctly identified.
-- Aggressive cleanup of unwanted notifications.
-- =================================================================

-- 1. Function to handle New Special Collection Request
CREATE OR REPLACE FUNCTION public.handle_new_special_collection()
RETURNS TRIGGER AS $$
BEGIN
    -- Notify Admins/Superadmins
    -- We check both 'users' and 'profiles' since one might be empty
    INSERT INTO public.user_notifications (user_id, title, message, type, priority, is_read, created_at)
    SELECT id, 'New Pickup Request', 'A resident has requested a special collection for ' || COALESCE(NEW.waste_type, 'Waste') || '.', 'info', 'medium', false, NOW()
    FROM public.users
    WHERE role::text ILIKE 'admin' OR role::text ILIKE 'superadmin';

    INSERT INTO public.user_notifications (user_id, title, message, type, priority, is_read, created_at)
    SELECT id, 'New Pickup Request', 'A resident has requested a special collection for ' || COALESCE(NEW.waste_type, 'Waste') || '.', 'info', 'medium', false, NOW()
    FROM public.profiles
    WHERE role::text ILIKE 'admin' OR role::text ILIKE 'superadmin'
    AND id NOT IN (SELECT user_id FROM public.user_notifications WHERE title = 'New Pickup Request' AND created_at > NOW() - INTERVAL '1 second');

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
    
    -- Format date/time
    s_date_time := to_char(NEW.scheduled_date, 'YYYY-MM-DD "at" HH24:MI');

    IF (NEW.status = 'scheduled') THEN
        notif_title := '🚨 New Special Collection';
        notif_msg := 'New collection from special collection for ' || w_type || ' on ' || s_date_time || '.';
    ELSIF (NEW.status = 'cancelled') THEN
        notif_title := '🚨 Collection Cancelled';
        notif_msg := 'Scheduled pickup for ' || COALESCE(NEW.resident_name, 'Resident') || ' (' || w_type || ') has been cancelled.';
    ELSE
        RETURN NEW;
    END IF;

    -- Notify ALL Collectors from all potential sources
    FOR collector_user IN 
        SELECT id FROM public.users WHERE role::text ILIKE 'collector'
        UNION
        SELECT id FROM public.profiles WHERE role::text ILIKE 'collector'
        UNION
        SELECT user_id as id FROM public.registered_collectors
    LOOP
        -- Check for duplication in the last 5 seconds to prevent spam if multiple tables match
        IF NOT EXISTS (
            SELECT 1 FROM public.user_notifications 
            WHERE user_id = collector_user.id::TEXT 
            AND title = notif_title 
            AND created_at > NOW() - INTERVAL '5 seconds'
        ) THEN
            INSERT INTO public.user_notifications (user_id, title, message, type, priority, is_read, created_at)
            VALUES (collector_user.id::TEXT, notif_title, notif_msg, 'alert', 'high', false, NOW());
        END IF;
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Aggressive Cleanup for Collectors
DELETE FROM public.user_notifications
WHERE (title ILIKE '%New Pickup Request%' OR title ILIKE '%Collection Started%')
AND user_id IN (
    SELECT id::TEXT FROM public.users WHERE role::text ILIKE 'collector'
    UNION
    SELECT id::TEXT FROM public.profiles WHERE role::text ILIKE 'collector'
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
