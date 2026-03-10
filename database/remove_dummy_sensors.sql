-- cleanup_dummy_sensors.sql
-- Run this in your Supabase SQL Editor to remove-- Clean up ALL sensors EXCEPT the real Arduino (BIN-1189)
DELETE FROM bins 
WHERE bin_id NOT IN ('BIN-1189');

-- Verify they are gone
SELECT bin_id, address, status FROM bins;