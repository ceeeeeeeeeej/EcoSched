-- Fix for "new row violates row-level security policy for table users"
-- This allows guest residents and new sign-ups to be added to the database.

-- 1. Allow INSERT for both Guests (anon) and Signed-in Users (authenticated)
-- This is necessary for new sign-ups AND guest registration.
DROP POLICY IF EXISTS "Allow insert for all users" ON public.users;
CREATE POLICY "Allow insert for all users"
ON public.users FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- 2. Allow UPDATE for Guests (anon) on resident profiles
-- This is necessary for the 'upsert' operation used in Resident registration
DROP POLICY IF EXISTS "Allow anon to update resident profiles" ON public.users;
CREATE POLICY "Allow anon to update resident profiles"
ON public.users FOR UPDATE
TO anon
USING (role = 'resident')
WITH CHECK (role = 'resident');

-- Verify policies
SELECT policyname, cmd, roles FROM pg_policies WHERE tablename = 'users';
