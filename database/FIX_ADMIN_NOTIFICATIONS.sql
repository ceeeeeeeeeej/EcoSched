-- FINAL FIX FOR ADMIN NOTIFICATIONS
-- Run this in your Supabase SQL Editor

-- 1. Ensure the user_notifications table exists with correct schema
CREATE TABLE IF NOT EXISTS public.user_notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID, -- For targeted notifications
    barangay VARCHAR(100), -- For broadcast notifications
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'info',
    priority VARCHAR(50) DEFAULT 'medium',
    is_read BOOLEAN DEFAULT FALSE,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Update column types if necessary (handle Device IDs as well as Auth UUIDs)
ALTER TABLE public.user_notifications ALTER COLUMN user_id TYPE TEXT;

-- 3. Function to handle New Resident Feedback
CREATE OR REPLACE FUNCTION public.handle_new_feedback()
RETURNS TRIGGER AS $$
DECLARE
    admin_user RECORD;
BEGIN
    FOR admin_user IN SELECT id FROM public.users WHERE role IN ('admin', 'superadmin')
    LOOP
        INSERT INTO public.user_notifications (user_id, title, message, type, priority, is_read, created_at)
        VALUES (
            admin_user.id::TEXT,
            'New Feedback Received',
            'A resident has submitted new feedback: ' || LEFT(NEW.feedback_text, 50) || '...',
            'feedback',
            'medium',
            false,
            NOW()
        );
    END LOOP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Function to handle New Special Collection Request
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

-- 5. Function to handle Full Bin Alerts
CREATE OR REPLACE FUNCTION public.handle_full_bin()
RETURNS TRIGGER AS $$
DECLARE
    admin_user RECORD;
BEGIN
    -- Only trigger if fill_level crosses 90% and wasn't high before
    IF NEW.fill_level >= 90 AND (OLD.fill_level IS NULL OR OLD.fill_level < 90) THEN
        FOR admin_user IN SELECT id FROM public.users WHERE role IN ('admin', 'superadmin')
        LOOP
            INSERT INTO public.user_notifications (user_id, title, message, type, priority, is_read, created_at)
            VALUES (
                admin_user.id::TEXT,
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

-- 6. Function to handle New User/Resident Registration
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    admin_user RECORD;
BEGIN
    IF NEW.role = 'resident' THEN
        FOR admin_user IN SELECT id FROM public.users WHERE role IN ('admin', 'superadmin')
        LOOP
            INSERT INTO public.user_notifications (user_id, title, message, type, priority, is_read, created_at)
            VALUES (
                admin_user.id::TEXT,
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

-- 7. (Re)Create Triggers
DROP TRIGGER IF EXISTS on_feedback_created ON public.resident_feedback;
CREATE TRIGGER on_feedback_created AFTER INSERT ON public.resident_feedback FOR EACH ROW EXECUTE FUNCTION public.handle_new_feedback();

DROP TRIGGER IF EXISTS on_special_collection_created ON public.special_collections;
CREATE TRIGGER on_special_collection_created AFTER INSERT ON public.special_collections FOR EACH ROW EXECUTE FUNCTION public.handle_new_feedback(); -- Wait, should be handle_new_special_collection

-- Correction for trigger link
DROP TRIGGER IF EXISTS on_special_collection_created ON public.special_collections;
CREATE TRIGGER on_special_collection_created AFTER INSERT ON public.special_collections FOR EACH ROW EXECUTE FUNCTION public.handle_new_special_collection();

DROP TRIGGER IF EXISTS on_bin_full ON public.bins;
CREATE TRIGGER on_bin_full AFTER UPDATE OF fill_level ON public.bins FOR EACH ROW EXECUTE FUNCTION public.handle_full_bin();

DROP TRIGGER IF EXISTS on_user_created ON public.users;
CREATE TRIGGER on_user_created AFTER INSERT ON public.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Enable Realtime for user_notifications
BEGIN;
  DROP PUBLICATION IF EXISTS supabase_realtime;
  CREATE PUBLICATION supabase_realtime FOR TABLE user_notifications;
COMMIT;
