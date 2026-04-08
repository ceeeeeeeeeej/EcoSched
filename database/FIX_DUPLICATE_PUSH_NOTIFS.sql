-- ============================================================================
-- FIX DUPLICATE PUSH NOTIFICATIONS (V2 - STRONGER DEDUPLICATION)
-- Please copy this entire script and run it in your Supabase SQL Editor.
-- This WILL remove OLD device tokens (if you reinstalled the app) and keep 
-- only the single, active device token for your user.
-- ============================================================================

-- Keep ONLY the most recent token per resident_id, delete all others unconditionally.
DELETE FROM public.user_devices a USING (
    SELECT resident_id, MAX(ctid) as keep_ctid
    FROM public.user_devices
    WHERE resident_id IS NOT NULL
    GROUP BY resident_id
    HAVING COUNT(*) > 1
) b
WHERE a.resident_id = b.resident_id 
AND a.ctid <> b.keep_ctid;

-- Keep ONLY the most recent token per device_id unconditionally.
DELETE FROM public.user_devices a USING (
    SELECT device_id, MAX(ctid) as keep_ctid
    FROM public.user_devices
    WHERE device_id IS NOT NULL 
    GROUP BY device_id
    HAVING COUNT(*) > 1
) b
WHERE a.device_id = b.device_id 
AND a.ctid <> b.keep_ctid;
