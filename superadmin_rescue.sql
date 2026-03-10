-- FINAL SUPERADMIN RESCUE & RLS RECURSION FIX
-- Copy and run this entire block in your Supabase SQL Editor.

-- STEP 1: FIX THE RECURSION BUG (Error 42P17)
-- This creates a function that can check your role WITHOUT triggering RLS recursively.
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT role FROM public.users WHERE id = auth.uid();
$$;

-- STEP 2: RECREATE THE POLICIES SAFELY
-- Drop existing problematic policies first
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.users;
DROP POLICY IF EXISTS "Users can view their own profile" ON public.users;
DROP POLICY IF EXISTS "Admins can view all users" ON public.users;

-- Re-create a safe select policy using the helper function
CREATE POLICY "Enable read access for authenticated users"
ON public.users FOR SELECT
TO authenticated
USING (
  auth.uid() = id 
  OR public.get_my_role() IN ('admin', 'superadmin')
);

-- STEP 3: ENSURE YOUR ACCOUNT IS ACTIVE & SUPERADMIN
-- We use email to target your specific account.
UPDATE public.users 
SET role = 'superadmin', 
    status = 'active',
    updated_at = now()
WHERE email = 'admin@echoshed.com';

-- STEP 4: VERIFY
SELECT id, email, role, status FROM public.users WHERE email = 'admin@echoshed.com';
