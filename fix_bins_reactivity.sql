-- 1. Ensure updated_at trigger exists for the bins table
-- This ensures the dashboard "Updated At" label stays live
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS tr_bins_updated_at ON bins;
CREATE TRIGGER tr_bins_updated_at
BEFORE UPDATE ON bins
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- 2. Cleanup Duplicates
-- If there are multiple records with the same bin_id, we keep only the most recently updated one.
DELETE FROM bins a USING (
      SELECT MIN(ctid) as ctid, bin_id
      FROM bins 
      GROUP BY bin_id HAVING COUNT(*) > 1
) b
WHERE a.bin_id = b.bin_id 
AND a.ctid <> b.ctid;

-- 3. Enforce Uniqueness
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'bins_bin_id_unique') THEN
        ALTER TABLE bins ADD CONSTRAINT bins_bin_id_unique UNIQUE (bin_id);
    END IF;
END $$;

-- 4. Ensure Technical Columns Exist (Double Check)
ALTER TABLE bins 
ADD COLUMN IF NOT EXISTS distance NUMERIC,
ADD COLUMN IF NOT EXISTS gps_status TEXT,
ADD COLUMN IF NOT EXISTS gps_processed INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS gps_sentences INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS gps_error TEXT;

-- 5. Set Initial Technical Data for BIN-1002 if it's missing
UPDATE bins SET 
  distance = 0,
  gps_status = 'Initialized',
  gps_processed = 0,
  gps_sentences = 0
WHERE bin_id = 'BIN-1002' AND distance IS NULL;
