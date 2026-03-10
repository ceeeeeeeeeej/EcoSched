-- Migration: Change resident_id to TEXT and handle policy dependencies
-- This allows "guest" residents (identified by non-UUID strings) to submit requests.

-- 1. Drop policies that depend on the resident_id column
-- Based on error: ERROR: cannot alter type of a column used in a policy definition
DROP POLICY IF EXISTS "Users view/cancel own special_collections" ON public.special_collections;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.special_collections;
DROP POLICY IF EXISTS "Enable insert access for authenticated users" ON public.special_collections;

-- 2. Drop the foreign key constraint
-- Usually named 'special_collections_resident_id_fkey'
DO $$ 
BEGIN 
    IF EXISTS (
        SELECT 1 
        FROM information_schema.table_constraints 
        WHERE table_name = 'special_collections' 
        AND constraint_name = 'special_collections_resident_id_fkey'
    ) THEN
        ALTER TABLE public.special_collections DROP CONSTRAINT special_collections_resident_id_fkey;
    END IF;
END $$;

-- 3. Change column type to TEXT
ALTER TABLE public.special_collections ALTER COLUMN resident_id TYPE TEXT;

-- 4. Recreate the policies
-- Using auth.uid()::text to ensure comparison works with the TEXT column
CREATE POLICY "Users view/cancel own special_collections"
  ON public.special_collections FOR ALL
  TO authenticated
  USING (
    auth.uid()::text = resident_id 
    OR (SELECT role FROM public.users WHERE id = auth.uid()) IN ('admin', 'superadmin')
  );

CREATE POLICY "Enable insert access for authenticated users"
  ON public.special_collections FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- (Optional) Add a general read policy if needed, or stick to the one above.
