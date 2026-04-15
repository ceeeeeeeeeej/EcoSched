-- SQL Script to sequentially update the created_at dates for all your tables
-- This will space the dates out by 1 hour for each row, ordered by their ID.
-- Copy and paste this into the Supabase SQL Editor and run it.

-- 1. bin_logs
WITH numbered_rows AS (
    SELECT ctid, ROW_NUMBER() OVER (ORDER BY ctid) as rn
    FROM bin_logs
)
UPDATE bin_logs
SET created_at = NOW() - ((SELECT COUNT(*) FROM bin_logs) - numbered_rows.rn || ' hours')::interval
FROM numbered_rows
WHERE bin_logs.ctid = numbered_rows.ctid;

-- 2. notifications
WITH numbered_rows AS (
    SELECT ctid, ROW_NUMBER() OVER (ORDER BY ctid) as rn
    FROM notifications
)
UPDATE notifications
SET created_at = NOW() - ((SELECT COUNT(*) FROM notifications) - numbered_rows.rn || ' hours')::interval
FROM numbered_rows
WHERE notifications.ctid = numbered_rows.ctid;

-- 3. resident_feedback
WITH numbered_rows AS (
    SELECT ctid, ROW_NUMBER() OVER (ORDER BY ctid) as rn
    FROM resident_feedback
)
UPDATE resident_feedback
SET created_at = NOW() - ((SELECT COUNT(*) FROM resident_feedback) - numbered_rows.rn || ' hours')::interval
FROM numbered_rows
WHERE resident_feedback.ctid = numbered_rows.ctid;

-- 4. special_collections
WITH numbered_rows AS (
    SELECT ctid, ROW_NUMBER() OVER (ORDER BY ctid) as rn
    FROM special_collections
)
UPDATE special_collections
SET created_at = NOW() - ((SELECT COUNT(*) FROM special_collections) - numbered_rows.rn || ' hours')::interval
FROM numbered_rows
WHERE special_collections.ctid = numbered_rows.ctid;

-- 5. user_activities
WITH numbered_rows AS (
    SELECT ctid, ROW_NUMBER() OVER (ORDER BY ctid) as rn
    FROM user_activities
)
UPDATE user_activities
SET created_at = NOW() - ((SELECT COUNT(*) FROM user_activities) - numbered_rows.rn || ' hours')::interval
FROM numbered_rows
WHERE user_activities.ctid = numbered_rows.ctid;

-- 6. user_notifications
WITH numbered_rows AS (
    SELECT ctid, ROW_NUMBER() OVER (ORDER BY ctid) as rn
    FROM user_notifications
)
UPDATE user_notifications
SET created_at = NOW() - ((SELECT COUNT(*) FROM user_notifications) - numbered_rows.rn || ' hours')::interval
FROM numbered_rows
WHERE user_notifications.ctid = numbered_rows.ctid;

-- 7. users (Note: auth.users might need to be linked, but this is the public.users table if you have one)
WITH numbered_rows AS (
    SELECT ctid, ROW_NUMBER() OVER (ORDER BY ctid) as rn
    FROM users
)
UPDATE users
SET created_at = NOW() - ((SELECT COUNT(*) FROM users) - numbered_rows.rn || ' hours')::interval
FROM numbered_rows
WHERE users.ctid = numbered_rows.ctid;

-- 8. ai_scans (if applicable)
WITH numbered_rows AS (
    SELECT ctid, ROW_NUMBER() OVER (ORDER BY ctid) as rn
    FROM ai_scans
)
UPDATE ai_scans
SET created_at = NOW() - ((SELECT COUNT(*) FROM ai_scans) - numbered_rows.rn || ' hours')::interval
FROM numbered_rows
WHERE ai_scans.ctid = numbered_rows.ctid;

-- 9. area_schedules
WITH numbered_rows AS (
    SELECT ctid, ROW_NUMBER() OVER (ORDER BY ctid) as rn
    FROM area_schedules
)
UPDATE area_schedules
SET created_at = NOW() - ((SELECT COUNT(*) FROM area_schedules) - numbered_rows.rn || ' hours')::interval
FROM numbered_rows
WHERE area_schedules.ctid = numbered_rows.ctid;

-- 10. collection_schedules
WITH numbered_rows AS (
    SELECT ctid, ROW_NUMBER() OVER (ORDER BY ctid) as rn
    FROM collection_schedules
)
UPDATE collection_schedules
SET created_at = NOW() - ((SELECT COUNT(*) FROM collection_schedules) - numbered_rows.rn || ' hours')::interval
FROM numbered_rows
WHERE collection_schedules.ctid = numbered_rows.ctid;

-- 11. iot_sensors
WITH numbered_rows AS (
    SELECT ctid, ROW_NUMBER() OVER (ORDER BY ctid) as rn
    FROM iot_sensors
)
UPDATE iot_sensors
SET created_at = NOW() - ((SELECT COUNT(*) FROM iot_sensors) - numbered_rows.rn || ' hours')::interval
FROM numbered_rows
WHERE iot_sensors.ctid = numbered_rows.ctid;

-- 12. registered_collectors
WITH numbered_rows AS (
    SELECT ctid, ROW_NUMBER() OVER (ORDER BY ctid) as rn
    FROM registered_collectors
)
UPDATE registered_collectors
SET created_at = NOW() - ((SELECT COUNT(*) FROM registered_collectors) - numbered_rows.rn || ' hours')::interval
FROM numbered_rows
WHERE registered_collectors.ctid = numbered_rows.ctid;

-- 13. reminders
WITH numbered_rows AS (
    SELECT ctid, ROW_NUMBER() OVER (ORDER BY ctid) as rn
    FROM reminders
)
UPDATE reminders
SET created_at = NOW() - ((SELECT COUNT(*) FROM reminders) - numbered_rows.rn || ' hours')::interval
FROM numbered_rows
WHERE reminders.ctid = numbered_rows.ctid;

-- 14. routes
WITH numbered_rows AS (
    SELECT ctid, ROW_NUMBER() OVER (ORDER BY ctid) as rn
    FROM routes
)
UPDATE routes
SET created_at = NOW() - ((SELECT COUNT(*) FROM routes) - numbered_rows.rn || ' hours')::interval
FROM numbered_rows
WHERE routes.ctid = numbered_rows.ctid;

-- 16. user_devices
WITH numbered_rows AS (
    SELECT ctid, ROW_NUMBER() OVER (ORDER BY ctid) as rn
    FROM user_devices
)
UPDATE user_devices
SET created_at = NOW() - ((SELECT COUNT(*) FROM user_devices) - numbered_rows.rn || ' hours')::interval
FROM numbered_rows
WHERE user_devices.ctid = numbered_rows.ctid;

-- 17. waste_management_plans
WITH numbered_rows AS (
    SELECT ctid, ROW_NUMBER() OVER (ORDER BY ctid) as rn
    FROM waste_management_plans
)
UPDATE waste_management_plans
SET created_at = NOW() - ((SELECT COUNT(*) FROM waste_management_plans) - numbered_rows.rn || ' hours')::interval
FROM numbered_rows
WHERE waste_management_plans.ctid = numbered_rows.ctid;
