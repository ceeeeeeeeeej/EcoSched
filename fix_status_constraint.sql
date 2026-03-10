-- FIX SPECIAL COLLECTIONS STATUS CONSTRAINT
-- This script updates the allowed status values for special collections.

-- 1. DROP THE PROBLEMATIC CONSTRAINT
-- The error message identified it as 'special_collections_status_check'
ALTER TABLE public.special_collections 
DROP CONSTRAINT IF EXISTS special_collections_status_check;

-- 2. RECREATE THE CONSTRAINT WITH ALL ALLOWED STATUSES
-- Includes the new 'approved' and 'verified' statuses.
ALTER TABLE public.special_collections 
ADD CONSTRAINT special_collections_status_check 
CHECK (status IN (
    'pending_payment',    -- Initial request
    'approved',           -- Approved by admin, awaiting payment
    'verified',           -- Office payment verified
    'scheduled',          -- Collection date set
    'completed',          -- Work finished
    'cancelled',          -- Request rejected or cancelled
    'payment_submitted'   -- (Optional) Legacy/Future use
));

-- 3. VERIFY
-- This should now succeed for an 'approved' status
SELECT id, status FROM public.special_collections LIMIT 1;
