-- =================================================================
-- FINAL CONSOLIDATED NOTIFICATION FIX FOR COLLECTORS (V5)
-- =================================================================

-- 1. Remove Collector notifications for "New Pickup Request"
-- (Now strictly for Admins only)
CREATE OR REPLACE FUNCTION public.handle_new_special_collection()
RETURNS TRIGGER AS $$
BEGIN
    -- Notify Admins ONLY
    INSERT INTO public.user_notifications (user_id, title, message, type, priority, is_read, created_at)
    SELECT id, 'New Pickup Request', 'A resident has requested a special collection for ' || NEW.waste_type || '.', 'info', 'medium', false, NOW()
    FROM public.users
    WHERE role IN ('admin', 'superadmin');

    -- NO COLLECTOR NOTIFICATION HERE
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Consolidate Special Collection Status Changes (Schedule & Cancel)
-- Matches EXACT format from Collector App screenshot
CREATE OR REPLACE FUNCTION public.notify_collectors_on_special_collection_status_change()
RETURNS TRIGGER AS $$
DECLARE
    collector_user RECORD;
    res_name TEXT;
    w_type TEXT;
    s_date_time TEXT;
    notif_title TEXT;
    notif_msg TEXT;
BEGIN
    -- Get resident name and waste type for the message
    res_name := COALESCE(NEW.resident_name, 'Resident');
    w_type := COALESCE(NEW.waste_type, 'General Waste');
    
    -- FORMAT: YYYY-MM-DD at HH24:MI (matching user screenshot)
    s_date_time := to_char(NEW.scheduled_date, 'YYYY-MM-DD "at" HH24:MI');

    -- CASE 1: Marked as 'scheduled' (Bring back "New Special Collection")
    IF (NEW.status = 'scheduled' AND (OLD.status IS NULL OR OLD.status != 'scheduled')) THEN
        notif_title := '🚨 New Special Collection';
        notif_msg := 'New collection from special collection for ' || w_type || ' on ' || s_date_time || '.';
    
    -- CASE 2: Marked as 'cancelled' (Bring back "Collection Cancelled")
    ELSIF (NEW.status = 'cancelled' AND (OLD.status IS NULL OR OLD.status != 'cancelled')) THEN
        notif_title := '🚨 Collection Cancelled';
        notif_msg := 'Scheduled pickup for ' || res_name || ' (' || w_type || ') has been cancelled by admin.';
    
    -- If no relevant status change, exit
    ELSE
        RETURN NEW;
    END IF;

    -- Loop through all active collectors and notify them
    FOR collector_user IN 
        SELECT id FROM public.users 
        WHERE role IN ('collector', 'Collector') AND status = 'active'
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
-- This removes "New Pickup Request" and "Collection Started" already in their inbox
DELETE FROM public.user_notifications
WHERE (title = 'New Pickup Request' OR title = 'Collection Started')
AND user_id IN (
    SELECT id::TEXT FROM public.users 
    WHERE role IN ('collector', 'Collector')
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

-- Cleanup legacy triggers
DROP TRIGGER IF EXISTS on_special_collection_scheduled ON public.special_collections;
DROP FUNCTION IF EXISTS public.notify_collectors_on_special_collection_scheduled();
