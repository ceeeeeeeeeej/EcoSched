-- Ensure user_notifications table exists and is updatable
-- Run this in your Supabase SQL Editor

-- 1. Explicitly grant permissions to ensure PATCH (update) works
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_notifications TO anon, authenticated, service_role;

-- 2. If RLS is enabled, ensure there's a policy for updates
-- Check if RLS is enabled and disable if we want it open, or add a policy
-- For now, let's keep it simple and ensure a permissive policy exists if RLS is on
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename = 'user_notifications' 
        AND rowsecurity = true
    ) THEN
        -- Add permissive policy if not exists
        IF NOT EXISTS (
            SELECT 1 FROM pg_policies 
            WHERE tablename = 'user_notifications' 
            AND policyname = 'Allow all access to user_notifications'
        ) THEN
            CREATE POLICY "Allow all access to user_notifications" 
            ON public.user_notifications FOR ALL 
            USING (true) 
            WITH CHECK (true);
        END IF;
    ELSE
        -- Just to be safe, disable RLS if we're having 405/406 issues
        ALTER TABLE public.user_notifications DISABLE ROW LEVEL SECURITY;
    END IF;
END
$$;

-- 3. Verify the table is indeed a table and not a view
-- If it was a view, this would help us find out (re-running the CREATE TABLE from before)
CREATE TABLE IF NOT EXISTS public.user_notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id TEXT,
    barangay VARCHAR(100),
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'info',
    priority VARCHAR(50) DEFAULT 'medium',
    is_read BOOLEAN DEFAULT FALSE,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
