-- =================================================================
-- TRIGGER TEST SCRIPT (V2)
-- Run this in your SQL Editor to see if the trigger is working.
-- =================================================================

DO $$
DECLARE
    test_id UUID;
    test_sc_id UUID;
    test_notif RECORD;
BEGIN
    RAISE NOTICE '--- Starting Trigger Test ---';
    
    -- 1. Get a collector user ID
    SELECT id INTO test_id FROM public.users WHERE role::text ILIKE 'collector' LIMIT 1;
    IF NOT FOUND THEN
        SELECT user_id INTO test_id FROM public.registered_collectors LIMIT 1;
    END IF;
    
    IF test_id IS NULL THEN
        RAISE EXCEPTION 'No collector found in database to test notifications.';
    END IF;
    
    RAISE NOTICE 'Using Collector ID for test: %', test_id;

    -- 2. Get a special collection item ID
    SELECT id INTO test_sc_id FROM public.special_collections LIMIT 1;
    IF test_sc_id IS NULL THEN
        RAISE EXCEPTION 'No special collection item found to test trigger.';
    END IF;
    
    RAISE NOTICE 'Updating SC Item ID: % to trigger notification...', test_sc_id;

    -- 3. Perform Updates to trigger the 'on_special_collection_status_change' trigger
    UPDATE public.special_collections SET status = 'approved' WHERE id = test_sc_id;
    UPDATE public.special_collections SET status = 'scheduled', scheduled_date = NOW() WHERE id = test_sc_id;

    -- 4. Check results
    SELECT id, title, message INTO test_notif FROM public.user_notifications 
    WHERE user_id = test_id::TEXT 
    AND title ILIKE '%Special Collection%' 
    ORDER BY created_at DESC LIMIT 1;

    IF FOUND THEN
        RAISE NOTICE '✅ SUCCESS! Found notification: "%" - "%"', test_notif.title, test_notif.message;
    ELSE
        RAISE NOTICE '❌ FAILURE: No notification was created for collector %. Check if V9 was applied correctly.', test_id;
    END IF;

    RAISE NOTICE '--- Test Complete ---';
END $$;
