-- Add missing columns to the bins table that are used by the dashboard and ESP8266

ALTER TABLE bins
ADD COLUMN IF NOT EXISTS status text DEFAULT 'active',
ADD COLUMN IF NOT EXISTS location_lat numeric,
ADD COLUMN IF NOT EXISTS location_lng numeric,
ADD COLUMN IF NOT EXISTS gps_lat numeric,
ADD COLUMN IF NOT EXISTS gps_lng numeric,
ADD COLUMN IF NOT EXISTS distance numeric,
ADD COLUMN IF NOT EXISTS gps_status text,
ADD COLUMN IF NOT EXISTS gps_processed integer DEFAULT 0,
ADD COLUMN IF NOT EXISTS gps_sentences integer DEFAULT 0,
ADD COLUMN IF NOT EXISTS gps_error text;
