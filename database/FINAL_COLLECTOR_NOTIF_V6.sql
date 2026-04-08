-- =================================================================
-- REVISED CONSOLIDATED NOTIFICATION FIX FOR COLLECTORS (V6)
-- Strictly limits "New Pickup Request" to Admins
-- Ensures "New Special Collection" reaches Collectors
-- =================================================================

-- 1. Function to handle New Special Collection Request (Admins ONLY)
CREATE OR REPLACE FUNCTION public.handle_new_special_collection()
RETURNS TRIGGER AS $$
BEGIN
    -- Notify Admins/Superadmins ONLY
    -- We use ILIKE for case-insensitive role check
    INSERT INTO public.user_notifications (user_id, title, message, type, priority, is_read, created_at)
    SELECT id, 'New Pickup Request', 'A resident has requested a special collection for ' || NEW.waste_type || '.', 'info', 'medium', false, NOW()
    FROM public.users
    WHERE role::text ILIKE 'admin' OR role::text ILIKE 'superadmin';

    -- NO COLLECTOR NOTIFICATION HERE
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Function to handle Special Collection Status Changes (Scheduled)
-- This is what collectors SHOULD receive
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
    
    -- FORMAT: YYYY-MM-DD at HH24:MI (Matching dashboard format)
    s_date_time := to_char(NEW.scheduled_date, 'YYYY-MM-DD "at" HH24:MI');

    -- CASE 1: Marked as 'scheduled' (The one collectors need)
    IF (NEW.status = 'scheduled' AND (OLD.status IS NULL OR OLD.status != 'scheduled')) THEN
        notif_title := '🚨 New Special Collection';
        notif_msg := 'New collection from special collection for ' || w_type || ' on ' || s_date_time || '.';
    
    -- CASE 2: Marked as 'cancelled'
    ELSIF (NEW.status = 'cancelled' AND (OLD.status IS NULL OR OLD.status != 'cancelled')) THEN
        notif_title := '🚨 Collection Cancelled';
        notif_msg := 'Scheduled pickup for ' || COALESCE(NEW.resident_name, 'Resident') || ' (' || w_type || ') has been cancelled by admin.';
    
    ELSE
        -- No relevant status change for collectors
        RETURN NEW;
    END IF;

    -- Loop through all collectors and notify them
    -- We use ILIKE 'collector' to be safe with casing
    FOR collector_user IN 
        SELECT id FROM public.users 
        WHERE role::text ILIKE 'collector'
    LOOP
        INSERT INTO public.user_notifications (
            user_id,
            title,
            message,
            type,
            priority,
            is_read,
            created_at
        ) VALUES (
            collector_user.id::TEXT,
            notif_title,
            notif_msg,
            'alert',
            'high',
            false,
            NOW()
        );
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Cleanup: Clear existing/old unwanted notifications for Collectors
-- This removes "New Pickup Request" and "Collection Started" already in their inbox (if leaking)
-- We keep "Collection Started" if the user wants it, but they said "only move 'New Pickup Request'".
-- Actually the user said: "only move the 'New Pickup Request' not the Collection Started"
-- So we ONLY delete "New Pickup Request" for collectors.

DELETE FROM public.user_notifications
WHERE title = 'New Pickup Request'
AND user_id IN (
    SELECT id::TEXT FROM public.users 
    WHERE role::text ILIKE 'collector'
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

-- Success message for manual execution
-- SELECT 'Notification triggers V6 applied successfully' as result;
