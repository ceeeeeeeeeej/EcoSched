-- MASTER RLS & SUPERADMIN FIX
-- Resolves "Failed to approve", "Access Denied", and RLS recursion errors.

-- 1. SAFE ROLE CHECK FUNCTION
-- This function bypasses RLS to check roles, preventing infinite loops.
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT role FROM public.users WHERE id = auth.uid();
$$;

-- 2. USERS TABLE POLICIES (Simplified)
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.users;
DROP POLICY IF EXISTS "Admin/Superadmin view all users" ON public.users;
DROP POLICY IF EXISTS "Users view own profile" ON public.users;
DROP POLICY IF EXISTS "Users update own profile" ON public.users;

CREATE POLICY "Users can view self and admins can view all"
ON public.users FOR SELECT
TO authenticated
USING (
  auth.uid() = id 
  OR public.get_my_role() IN ('admin', 'superadmin')
);

CREATE POLICY "Users can update self"
ON public.users FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- 3. SPECIAL COLLECTIONS POLICIES (Fixes "Failed to approve")
DROP POLICY IF EXISTS "Admin manage special_collections" ON public.special_collections;
DROP POLICY IF EXISTS "Admin/Superadmin manage special_collections" ON public.special_collections;
DROP POLICY IF EXISTS "Users view/cancel own special_collections" ON public.special_collections;
DROP POLICY IF EXISTS "Enable insert access for authenticated users" ON public.special_collections;
DROP POLICY IF EXISTS "Users insert special_collections" ON public.special_collections;

CREATE POLICY "Admin/Superadmin manage all special_collections"
ON public.special_collections FOR ALL
TO authenticated
USING (public.get_my_role() IN ('admin', 'superadmin'));

CREATE POLICY "Residents manage own special_collections"
ON public.special_collections FOR ALL
TO authenticated
USING (auth.uid()::text = resident_id)
WITH CHECK (auth.uid()::text = resident_id OR public.get_my_role() IN ('admin', 'superadmin'));

-- 4. AREA SCHEDULES
DROP POLICY IF EXISTS "Public read area_schedules" ON public.area_schedules;
DROP POLICY IF EXISTS "Admin/Superadmin manage area_schedules" ON public.area_schedules;

CREATE POLICY "Public read area_schedules" ON public.area_schedules FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admin manage area_schedules" ON public.area_schedules FOR ALL TO authenticated 
USING (public.get_my_role() IN ('admin', 'superadmin'));

-- 5. ENSURE SUPERADMIN STATUS
UPDATE public.users 
SET role = 'superadmin', status = 'active'
WHERE email = 'admin@echoshed.com';

-- VERIFY
SELECT tablename, policyname FROM pg_policies WHERE schemaname = 'public' AND tablename IN ('users', 'special_collections', 'area_schedules');
