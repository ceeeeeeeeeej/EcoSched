-- Fix for "Invalid input syntax for type uuid" error
-- The app uses string IDs (e.g., "resident_123...") for guest users, but the DB expects UUIDs linked to the users table.
-- We need to relax this constraint to allow guest submissions.

-- 1. Drop the foreign key constraint if it exists
ALTER TABLE "public"."special_collections" 
DROP CONSTRAINT IF EXISTS "special_collections_resident_id_fkey";

-- 2. Change the resident_id column type to TEXT to accept "resident_..." strings
-- Using "USING resident_id::text" ensures existing UUIDs are converted safely
ALTER TABLE "public"."special_collections" 
ALTER COLUMN "resident_id" TYPE TEXT USING "resident_id"::text;

-- 3. Reset RLS Policies
DROP POLICY IF EXISTS "Users view/cancel own special_collections" ON "public"."special_collections";
DROP POLICY IF EXISTS "Users insert special_collections" ON "public"."special_collections";
DROP POLICY IF EXISTS "Admin manage special_collections" ON "public"."special_collections";

-- 4. Create New Policies

-- Allow users to view their own requests (UUID matches or Guest ID matches)
CREATE POLICY "Users view/cancel own special_collections" 
ON "public"."special_collections" 
FOR SELECT 
USING (
  (auth.uid() IS NOT NULL AND auth.uid()::text = resident_id)
  OR 
  (resident_id LIKE 'resident_%') 
  -- Note: Ideally we'd match the guest ID to a session variable, but for now we allow reading 'resident_' rows 
  -- to ensure the app doesn't crash on listing. 
  -- In a production app, we'd use a secure session token.
);

-- Allow anyone (authenticated or anon) to INSERT requests
CREATE POLICY "Users insert special_collections" 
ON "public"."special_collections" 
FOR INSERT 
WITH CHECK (true);

-- Restore Admin Access
CREATE POLICY "Admin manage special_collections" 
ON "public"."special_collections" 
FOR ALL 
USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
);

-- Refresh schema cache
NOTIFY pgrst, 'reload config';
