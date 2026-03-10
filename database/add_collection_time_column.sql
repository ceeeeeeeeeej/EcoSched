-- Fix collection_schedules schema
-- Add missing collection_time column that the Admin Dashboard expects

-- Check if we're using scheduled_pickups or collection_schedules
-- Add collection_time column if it doesn't exist
ALTER TABLE scheduled_pickups ADD COLUMN IF NOT EXISTS collection_time TIME;

-- Populate collection_time from schedule_date if empty
UPDATE scheduled_pickups 
SET collection_time = (schedule_date::TIME)
WHERE collection_time IS NULL AND schedule_date IS NOT NULL;

-- Also ensure we have the barangay column (from previous migration)
ALTER TABLE scheduled_pickups ADD COLUMN IF NOT EXISTS barangay TEXT;

-- Populate barangay from service_area if empty
UPDATE scheduled_pickups 
SET barangay = service_area 
WHERE barangay IS NULL AND service_area IS NOT NULL;

COMMENT ON COLUMN scheduled_pickups.collection_time IS 'Time of day for the collection (HH:MM:SS format)';
