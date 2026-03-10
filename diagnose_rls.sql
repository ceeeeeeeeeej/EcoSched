-- RLS & PERMISSION DIAGNOSIS SCRIPT
-- Run this in Supabase SQL Editor to see why your account is blocked.

-- 1. Check your current Auth UID and Role (according to the DB)
SELECT 
    auth.uid() as my_auth_uid,
    (SELECT email FROM public.users WHERE id = auth.uid()) as my_email,
    (SELECT role FROM public.users WHERE id = auth.uid()) as my_profile_role,
    public.get_my_role() as role_from_function;

-- 2. Check if you can actually READ your own profile (testing the Select policy)
SELECT * FROM public.users WHERE id = auth.uid();

-- 3. Check all active policies on special_collections
-- Fixed: use 'cmd' instead of 'action'
SELECT policyname, cmd as action, roles, qual, with_check 
FROM pg_policies 
WHERE tablename = 'special_collections';


-- 4. EMERGENCY FIX: The "Nuclear" Approval Policy
-- If all else fails, this grants full access to special_collections for any authenticated user.
-- Use this ONLY for testing to see if RLS is the blocker.
-- DROP POLICY IF EXISTS "TEMP_DEBUG_ALL" ON public.special_collections;
-- CREATE POLICY "TEMP_DEBUG_ALL" ON public.special_collections FOR ALL TO authenticated USING (true);
