-- Enable Realtime for all operational tables
-- This adds the specified tables to the 'supabase_realtime' publication

BEGIN;

-- First, ensure the publication exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
        CREATE PUBLICATION supabase_realtime;
    END IF;
END $$;

-- Add tables to the publication
-- We use 'ALTER PUBLICATION ... ADD TABLE' for each table
-- Note: Replication must be enabled on the table first (handled automatically by Supabase usually, but good to be explicit if needed)

ALTER PUBLICATION supabase_realtime ADD TABLE users;
ALTER PUBLICATION supabase_realtime ADD TABLE profiles;
ALTER PUBLICATION supabase_realtime ADD TABLE special_collections;
ALTER PUBLICATION supabase_realtime ADD TABLE collection_schedules;
ALTER PUBLICATION supabase_realtime ADD TABLE area_schedules;
ALTER PUBLICATION supabase_realtime ADD TABLE bins;
ALTER PUBLICATION supabase_realtime ADD TABLE resident_feedback;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE user_activities;
ALTER PUBLICATION supabase_realtime ADD TABLE collectors;

COMMIT;

-- Verify the publication
SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime';
