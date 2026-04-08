-- 1. Check triggers on special_collections
SELECT tgname, tgenabled 
FROM pg_trigger 
WHERE tgrelid = 'public.special_collections'::regclass;

-- 2. Check users table for collectors
SELECT id, email, role FROM public.users WHERE role ILIKE '%collector%';

-- 3. Check registered_collectors table
-- We check only for user_id to avoid any column name issues
SELECT user_id, 'collector' as role FROM public.registered_collectors;

-- 4. Check total notification count
SELECT count(*) as total_notifications FROM public.user_notifications;

-- 5. Check recent notifications for collectors specifically
SELECT user_id, title, message, created_at 
FROM public.user_notifications 
WHERE title ILIKE '%Special Collection%'
ORDER BY created_at DESC LIMIT 5;
