-- Migration to add telemetry columns to the bins table
ALTER TABLE bins 
ADD COLUMN IF NOT EXISTS distance NUMERIC,
ADD COLUMN IF NOT EXISTS gps_lat NUMERIC,
ADD COLUMN IF NOT EXISTS gps_lng NUMERIC,
ADD COLUMN IF NOT EXISTS gps_status TEXT,
ADD COLUMN IF NOT EXISTS gps_processed INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS gps_sentences INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS gps_error TEXT;

-- Comments for documentation
COMMENT ON COLUMN bins.distance IS 'Distance measured by ultrasonic sensor in cm';
COMMENT ON COLUMN bins.gps_lat IS 'Latitude measured by GPS sensor';
COMMENT ON COLUMN bins.gps_lng IS 'Longitude measured by GPS sensor';
COMMENT ON COLUMN bins.gps_status IS 'Status of the GPS fix (e.g., No Fix, Fixed)';
COMMENT ON COLUMN bins.gps_processed IS 'Number of characters processed by GPS module';
COMMENT ON COLUMN bins.gps_sentences IS 'Number of sentences with a fix received';
COMMENT ON COLUMN bins.gps_error IS 'GPS related warnings or errors';
