-- ==========================================
-- SETUP: RELIABLE SCHEDULE CRON JOB
-- ==========================================
-- This script enables the pg_cron extension and sets up 
-- a recurring task to call the 'check-schedules' Edge Function
-- every minute. This ensures notifications are sent even 
-- if the Admin Dashboard is closed.

-- 1. Enable the pg_cron extension
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 2. Create the cron job
-- IMPORTANT: Replace 'YOUR_SERVICE_ROLE_KEY' with your actual 
-- Supabase Service Role Key (found in Project Settings > API)
SELECT cron.schedule(
    'check-schedules-every-minute', -- unique job name
    '* * * * *',                   -- every minute
    $$
    SELECT
      net.http_post(
        url := 'https://bfqktqtsjchbmopafgzf.supabase.co/functions/v1/check-schedules',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer YOUR_SERVICE_ROLE_KEY'
        ),
        body := '{}'::jsonb
      ) as request_id;
    $$
);

-- 3. Verify the job was created
-- SELECT * FROM cron.job;

-- 4. Monitor job runs (optional)
-- SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 10;
