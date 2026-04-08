-- =================================================================
-- FINAL NOTIFICATION FIX FOR COLLECTORS (V12)
-- 1. Explicitly excludes collectors from Admin-only alerts.
-- 2. Robust collector identification for special collection alerts.
-- 3. Aggressive cleanup of existing unwanted notifications.
-- =================================================================

-- 1. Function to handle New Special Collection Request (Resident -> Admin)
CREATE OR REPLACE FUNCTION public.handle_new_special_collection()
RETURNS TRIGGER AS $$
BEGIN
    -- Notify ONLY Admins/Superadmins
    -- CRITICAL: We EXCLUDE anyone who is listed in the registered_collectors table
    INSERT INTO public.user_notifications (user_id, title, message, type, priority, is_read, created_at)
    SELECT id::TEXT, 'New Pickup Request', 'A resident has requested a special collection for ' || COALESCE(NEW.waste_type, 'Waste') || '.', 'info', 'medium', false, NOW()
    FROM public.users
    WHERE (role::text ILIKE 'admin' OR role::text ILIKE 'superadmin')
    AND id IS NOT NULL
    AND id::TEXT NOT IN (
        SELECT user_id::TEXT FROM public.registered_collectors WHERE user_id IS NOT NULL
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Function to handle Special Collection Status Changes (Admin -> Collector)
CREATE OR REPLACE FUNCTION public.notify_collectors_on_special_collection_status_change()
RETURNS TRIGGER AS $$
DECLARE
    collector_user RECORD;
    notif_title TEXT;
    notif_msg TEXT;
BEGIN
    -- Check status case-insensitively
    IF (LOWER(NEW.status) = 'scheduled') THEN
        notif_title := 'NEW SPECIAL COLLECTION';
        notif_msg := 'New collection for ' || COALESCE(NEW.waste_type, 'Waste') || ' scheduled for ' || to_char(NEW.scheduled_date, 'Mon DD, YYYY, HH:MI AM') || ' at ' || COALESCE(NEW.pickup_location, 'Resident Location') || '.';
    ELSIF (LOWER(NEW.status) = 'cancelled') THEN
        notif_title := '🚨 Collection Cancelled';
        notif_msg := 'Scheduled pickup for ' || COALESCE(NEW.resident_name, 'Resident') || ' has been cancelled.';
    ELSE
        RETURN NEW;
    END IF;

    -- Notify ALL Collectors (exclude NULLs)
    FOR collector_user IN 
        SELECT target_id::TEXT FROM (
            SELECT id as target_id FROM public.users WHERE role::text ILIKE 'collector'
            UNION
            SELECT user_id as target_id FROM public.registered_collectors
        ) AS sub
        WHERE target_id IS NOT NULL
    LOOP
        -- Duplicate check (10s window)
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

-- 3. Cleanup unwanted notifications from collectors' inboxes
-- We remove "New Pickup Request" and "Collection Started" for any user who is a collector
DELETE FROM public.user_notifications
WHERE (title ILIKE '%New Pickup Request%' OR title ILIKE '%Collection Started%')
AND user_id IN (
    SELECT user_id::TEXT FROM public.registered_collectors WHERE user_id IS NOT NULL
);

-- Also remove notifications with NULL user_id
DELETE FROM public.user_notifications
WHERE user_id IS NULL;

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
