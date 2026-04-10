-- ECO SCHED DATA NORMALIZATION
-- Run this in Supabase SQL Editor to standardize all area names to lowercase

-- 1. Standardize Users table
UPDATE public.users 
SET barangay = LOWER(TRIM(barangay))
WHERE barangay IS NOT NULL;

-- 2. Standardize Collection Schedules table
UPDATE public.collection_schedules
SET zone = LOWER(TRIM(zone))
WHERE zone IS NOT NULL;

-- 3. Standardize Area Schedules (Fixed) table
UPDATE public.area_schedules
SET area = LOWER(TRIM(area))
WHERE area IS NOT NULL;

-- 4. Standardize Special Collections
UPDATE public.special_collections
SET resident_barangay = LOWER(TRIM(resident_barangay))
WHERE resident_barangay IS NOT NULL;

-- 5. Standardize Announcements
UPDATE public.announcements
SET target_audience = LOWER(TRIM(target_audience))
WHERE target_audience IS NOT NULL AND target_audience <> 'all';

-- 6. Clean up old "reminder" type notifications that might have bad casing
DELETE FROM public.user_notifications 
WHERE type = 'reminder';

-- 7. Lowercase any existing targeted notifications
UPDATE public.user_notifications
SET barangay = LOWER(TRIM(barangay))
WHERE barangay IS NOT NULL AND barangay <> 'targeted';
