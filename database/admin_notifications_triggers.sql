-- ADMIN NOTIFICATIONS TRIGGERS
-- Run this in Supabase SQL Editor to automate admin notifications

-- 1. Function to handle New Resident Feedback
CREATE OR REPLACE FUNCTION public.handle_new_feedback()
RETURNS TRIGGER AS $$
DECLARE
    admin_user RECORD;
BEGIN
    FOR admin_user IN SELECT id FROM public.users WHERE role IN ('admin', 'superadmin')
    LOOP
        INSERT INTO public.user_notifications (user_id, title, message, type, priority, is_read, created_at)
        VALUES (
            admin_user.id,
            'New Feedback Received',
            'A resident (' || COALESCE(NEW.resident_name, 'Unknown') || ') has submitted feedback: "' || LEFT(NEW.feedback_text, 100) || '..."',
            'feedback',
            'medium',
            false,
            NOW()
        );
    END LOOP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Function to handle New Special Collection Request
CREATE OR REPLACE FUNCTION public.handle_new_special_collection()
RETURNS TRIGGER AS $$
DECLARE
    admin_user RECORD;
    res_name TEXT;
BEGIN
    res_name := COALESCE(NEW.resident_name, 'A resident');
    FOR admin_user IN SELECT id FROM public.users WHERE role IN ('admin', 'superadmin')
    LOOP
        INSERT INTO public.user_notifications (user_id, title, message, type, priority, is_read, created_at)
        VALUES (
            admin_user.id,
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

-- 3. Function to handle Full Bin Alerts
CREATE OR REPLACE FUNCTION public.handle_full_bin()
RETURNS TRIGGER AS $$
DECLARE
    admin_user RECORD;
BEGIN
    -- Only trigger if fill_level crosses 90% and wasn't high before (to avoid spam)
    IF NEW.fill_level >= 90 AND (OLD.fill_level IS NULL OR OLD.fill_level < 90) THEN
        FOR admin_user IN SELECT id FROM public.users WHERE role IN ('admin', 'superadmin')
        LOOP
            INSERT INTO public.user_notifications (user_id, title, message, type, priority, is_read, created_at)
            VALUES (
                admin_user.id,
                '🚨 Bin Full Alert',
                'Bin ' || NEW.bin_id || ' at ' || COALESCE(NEW.location, NEW.address, 'Unknown Location') || ' is ' || NEW.fill_level || '% full.',
                'bin_alert',
                'urgent',
                false,
                NOW()
            );
        END LOOP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Function to handle New User/Resident Registration
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    admin_user RECORD;
BEGIN
    -- Only notify if it's a resident (or any non-admin role you want to track)
    IF NEW.role = 'resident' THEN
        FOR admin_user IN SELECT id FROM public.users WHERE role IN ('admin', 'superadmin')
        LOOP
            INSERT INTO public.user_notifications (user_id, title, message, type, priority, is_read, created_at)
            VALUES (
                admin_user.id,
                'New Resident Registered',
                'A new resident, ' || COALESCE(NEW.first_name, '') || ' ' || COALESCE(NEW.last_name, '') || ' (' || NEW.email || '), has joined EcoSched.',
                'new_user',
                'low',
                false,
                NOW()
            );
        END LOOP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RECREATE TRIGGERS
DROP TRIGGER IF EXISTS on_feedback_created ON public.resident_feedback;
CREATE TRIGGER on_feedback_created AFTER INSERT ON public.resident_feedback FOR EACH ROW EXECUTE FUNCTION public.handle_new_feedback();

DROP TRIGGER IF EXISTS on_special_collection_created ON public.special_collections;
CREATE TRIGGER on_special_collection_created AFTER INSERT ON public.special_collections FOR EACH ROW EXECUTE FUNCTION public.handle_new_special_collection();

DROP TRIGGER IF EXISTS on_bin_full ON public.bins;
CREATE TRIGGER on_bin_full AFTER UPDATE OF fill_level ON public.bins FOR EACH ROW EXECUTE FUNCTION public.handle_full_bin();

DROP TRIGGER IF EXISTS on_user_created ON public.users;
CREATE TRIGGER on_user_created AFTER INSERT ON public.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
