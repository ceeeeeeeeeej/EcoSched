-- NUCLEAR RLS RESET FOR USERS TABLE
-- Run this if the "infinite recursion" error persists.

-- 1. DROP ALL EXISTING POLICIES ON THE USERS TABLE
-- This ensures no hidden problematic policies are left behind.
DO $$ 
DECLARE 
    pol RECORD;
BEGIN 
    FOR pol IN (SELECT policyname FROM pg_policies WHERE tablename = 'users' AND schemaname = 'public') 
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.users', pol.policyname);
        RAISE NOTICE 'Dropped policy: %', pol.policyname;
    END LOOP;
END $$;

-- 2. CREATE A SIMPLE, NON-RECURSIVE POLICY
-- This allows any authenticated user to read all users (safe for an admin dashboard).
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.users;
CREATE POLICY "Enable read access for authenticated users" 
ON public.users FOR SELECT 
TO authenticated 
USING (true);

-- 3. ENSURE YOUR ACCOUNT IS ACTIVE & SUPERADMIN
-- (Double-check your email here)
UPDATE public.users 
SET role = 'superadmin', 
    status = 'active',
    updated_at = now()
WHERE email = 'admin@echoshed.com';

-- 4. VERIFY FINAL STATE
SELECT policyname FROM pg_policies WHERE tablename = 'users';
SELECT id, email, role, status FROM public.users WHERE email = 'admin@echoshed.com';
