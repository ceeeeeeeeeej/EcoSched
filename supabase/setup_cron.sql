-- 1. Enable Required Extensions
create extension if not exists pg_cron;
create extension if not exists http;

-- 2. Create the Cron Job
-- This will run every 5 minutes and call the 'check-schedules' Edge Function.
-- Replace YOUR_PROJECT_REF with your actual Supabase project reference.
-- Replace YOUR_SERVICE_ROLE_KEY with your service_role API key.

select
  cron.schedule(
    'check-schedules-every-5-mins',
    '*/5 * * * *',
    $$
    select
      net.http_post(
        url:='https://YOUR_PROJECT_REF.supabase.co/functions/v1/check-schedules',
        headers:='{"Content-Type": "application/json", "Authorization": "Bearer YOUR_SERVICE_ROLE_KEY"}'::jsonb,
        body:='{}'::jsonb
      ) as request_id;
    $$
  );

-- 3. Verify the cron job
select * from cron.job;
