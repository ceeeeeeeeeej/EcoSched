-- Add Barangay Mahayag to Area Schedules
-- This ensures the app can fetch a default schedule for Mahayag residents.

INSERT INTO public.area_schedules (area, schedule_name, days, time)
VALUES ('mahayag', 'Mahayag Waste Collection', ARRAY['wednesday'], '08:00:00')
ON CONFLICT (area) DO UPDATE 
SET schedule_name = EXCLUDED.schedule_name, days = EXCLUDED.days, time = EXCLUDED.time;

-- Verify
SELECT * FROM public.area_schedules WHERE area = 'mahayag';
