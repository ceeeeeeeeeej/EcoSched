-- RLS FIX FOR GUEST ACCESS
-- This script allows non-logged in (anon) users to read schedules

-- 1. Area Schedules: Enable read for everyone (anon and authenticated)
DROP POLICY IF EXISTS "Public read area_schedules" ON public.area_schedules;
CREATE POLICY "Public read area_schedules" 
ON public.area_schedules FOR SELECT 
USING (true);

-- 2. Collection Schedules: Enable read for everyone
DROP POLICY IF EXISTS "Everyone read collection_schedules" ON public.collection_schedules;
CREATE POLICY "Everyone read collection_schedules" 
ON public.collection_schedules FOR SELECT 
USING (true);

-- 3. Ensure the tables are accessible to anon role
GRANT SELECT ON public.area_schedules TO anon, authenticated;
GRANT SELECT ON public.collection_schedules TO anon, authenticated;

-- VERIFY
SELECT tablename, policyname, roles FROM pg_policies 
WHERE schemaname = 'public' AND tablename IN ('area_schedules', 'collection_schedules');
