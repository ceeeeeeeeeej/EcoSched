-- 1. Enable the network extension (REALLY IMPORTANT: Fixes "schema net does not exist" error)
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 2. Create the trigger function
CREATE OR REPLACE FUNCTION public.trigger_push_on_user_notification()
RETURNS TRIGGER AS $$
DECLARE
  -- 🚨 ACTION REQUIRED: Paste your "Service Role Key" between the quotes below
  -- Found in: Supabase Dashboard -> Project Settings -> API -> service_role (secret)
  service_role_key TEXT := 'YOUR_SERVICE_ROLE_KEY_HERE';
  
  -- Project Reference ID (Permanent for this project)
  project_ref TEXT := 'bfqktqtsjchbmopafgzf';
BEGIN
  -- Call the Edge Function via HTTP POST
  -- This sends the signal to FCM to show the notification on the device
  PERFORM
    net.http_post(
      url := 'https://' || project_ref || '.supabase.co/functions/v1/send-push-v2',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || service_role_key
      ),
      body := jsonb_build_object(
        'resident_id', NEW.user_id::text,
        'title', NEW.title,
        'body', NEW.message,
        'barangay', NEW.barangay,
        'broadcast', (NEW.user_id IS NULL AND (NEW.barangay IS NULL OR NEW.barangay = 'all')),
        'collapse_key', CASE 
            WHEN NEW.title ILIKE '%truck%' THEN 'truck_arrival'
            WHEN NEW.title ILIKE '%bin%' THEN 'bin_status'
            WHEN NEW.title ILIKE '%schedule%' THEN 'schedule_reminder'
            ELSE 'general_alert'
        END
      )
    );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Attach the trigger to user_notifications (the correct table)
DROP TRIGGER IF EXISTS tr_push_on_user_notification ON public.user_notifications;
CREATE TRIGGER tr_push_on_user_notification
  AFTER INSERT ON public.user_notifications
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_push_on_user_notification();

-- 3. Cleanup: The function 'trigger_push_on_user_notification' is now only attached to 'user_notifications'
-- This ensures one single, reliable path for push delivery without duplicates.
COMMENT ON FUNCTION public.trigger_push_on_user_notification IS 'Dispatches FCM push notifications via Edge Function upon any insert in user_notifications table.';
