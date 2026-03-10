-- 0. Cleanup: Remove the old bin (if it exists) to avoid duplicates
DELETE FROM "public"."bins" WHERE "bin_id" = 'BIN-1189';

-- 1. Insert the BIN-1002 record (matches your sensor code)
INSERT INTO "public"."bins" ("bin_id", "fill_level", "status", "location_lat", "location_lng", "zone", "address", "updated_at")
VALUES (
  'BIN-1002', 
  0, 
  'active', 
  9.05452, 
  126.41682, 
  'Tago Poblacion', 
  'Near Public Market', 
  NOW()
)
ON CONFLICT ("bin_id") DO UPDATE SET 
  "updated_at" = NOW();

-- 2. Ensure RLS is enabled
ALTER TABLE "public"."bins" ENABLE ROW LEVEL SECURITY;

-- 3. Reset Policies (DROP first to avoid "already exists" error)
DROP POLICY IF EXISTS "Public Read Access" ON "public"."bins";
DROP POLICY IF EXISTS "Public Update Access" ON "public"."bins";
DROP POLICY IF EXISTS "Public Insert Access" ON "public"."bins";

-- 4. Create Read Policy (Allow Dashboard to see data)
CREATE POLICY "Public Read Access" 
ON "public"."bins" 
FOR SELECT 
TO anon, authenticated
USING (true);

-- 5. Create Update Policy (Allow Sensor to update data)
CREATE POLICY "Public Update Access" 
ON "public"."bins" 
FOR UPDATE 
TO anon, authenticated
USING (true)
WITH CHECK (true);

-- 6. Create Insert Policy (Optional, for testing)
CREATE POLICY "Public Insert Access" 
ON "public"."bins" 
FOR INSERT 
TO anon, authenticated
WITH CHECK (true);
