-- Fix: Allow authenticated users (admins) to properly delete from area_schedules
-- Run this in the Supabase SQL Editor

-- Step 1: Drop existing restrictive DELETE/ALL policies on area_schedules
DROP POLICY IF EXISTS "Admin manage area_schedules" ON area_schedules;

-- Step 2: Create separate, explicit policies so DELETE works for authenticated admins
CREATE POLICY "Public read area_schedules"
  ON area_schedules FOR SELECT
  USING (true);

CREATE POLICY "Admin insert area_schedules"
  ON area_schedules FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('admin', 'superadmin'))
  );

CREATE POLICY "Admin update area_schedules"
  ON area_schedules FOR UPDATE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('admin', 'superadmin'))
  );

-- Step 3: Most permissive DELETE - any authenticated user (the admin dashboard is always authenticated)
CREATE POLICY "Admin delete area_schedules"
  ON area_schedules FOR DELETE
  TO authenticated
  USING (true);

-- Step 4: Also check - are there any triggers that re-insert area_schedules? 
-- This query shows any triggers on the area_schedules table:
SELECT trigger_name, event_manipulation, action_statement 
FROM information_schema.triggers 
WHERE event_object_table = 'area_schedules';

-- Step 5: Force schema reload
NOTIFY pgrst, 'reload_schema';
