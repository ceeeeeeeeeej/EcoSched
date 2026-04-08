-- REFINE COLLECTOR NOTIFICATIONS
-- Run this in your Supabase SQL Editor to apply the changes.

-- 1. Function to handle Full Bin Alerts (Admins + Collectors)
CREATE OR REPLACE FUNCTION public.handle_full_bin()
RETURNS TRIGGER AS $$
DECLARE
    target_user RECORD;
BEGIN
    -- Only trigger if fill_level crosses 90% and wasn't high before
    IF NEW.fill_level >= 90 AND (OLD.fill_level IS NULL OR OLD.fill_level < 90) THEN
        -- Loop through admins, superadmins, and collectors
        FOR target_user IN 
            SELECT id FROM public.users 
            WHERE role IN ('admin', 'superadmin', 'collector', 'Collector')
        LOOP
            INSERT INTO public.user_notifications (user_id, title, message, type, priority, is_read, created_at)
            VALUES (
                target_user.id::TEXT,
                '🚨 Bin Full Alert',
                'In ' || COALESCE(NEW.location, NEW.address, 'your area') || ', bin ' || NEW.bin_id || ' is full! Please collect waste to prevent overflow.',
                'alert',
                'urgent',
                false,
                NOW()
            );
        END LOOP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Function to handle New Special Collection Request (Admins ONLY)
CREATE OR REPLACE FUNCTION public.handle_new_special_collection()
RETURNS TRIGGER AS $$
DECLARE
    admin_user RECORD;
    res_name TEXT;
BEGIN
    res_name := COALESCE(NEW.resident_name, 'A resident');
    -- Strictly admins/superadmins ONLY
    FOR admin_user IN 
        SELECT id FROM public.users 
        WHERE role IN ('admin', 'superadmin')
    LOOP
        INSERT INTO public.user_notifications (user_id, title, message, type, priority, is_read, created_at)
        VALUES (
            admin_user.id::TEXT,
            'New Pickup Request',
            res_name || ' has requested a special collection for ' || NEW.waste_type || '.',
            'special_collection',
            'medium',
            false,
            NOW()
        );
    END LOOP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Cleanup: Remove existing unwanted notifications from Collectors
DELETE FROM public.user_notifications
WHERE (title = 'New Pickup Request' OR title = 'Collection Started')
AND user_id IN (
    SELECT id::TEXT FROM public.users 
    WHERE role IN ('collector', 'Collector')
);

-- 4. Re-ensure triggers are linked correctly
DROP TRIGGER IF EXISTS on_bin_full ON public.bins;
CREATE TRIGGER on_bin_full AFTER UPDATE OF fill_level ON public.bins FOR EACH ROW EXECUTE FUNCTION public.handle_full_bin();

DROP TRIGGER IF EXISTS on_special_collection_created ON public.special_collections;
CREATE TRIGGER on_special_collection_created AFTER INSERT ON public.special_collections FOR EACH ROW EXECUTE FUNCTION public.handle_new_special_collection();

-- 5. Enable Realtime for user_notifications (if not already)
-- ALTER TABLE public.user_notifications SET (realtime = true);
-- (Handled via publication in most setups)
