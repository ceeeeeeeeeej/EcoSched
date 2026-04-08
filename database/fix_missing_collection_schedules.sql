-- Fix for missing or unexposed collection_schedules table
-- Run this in your Supabase SQL Editor

-- 1. Ensure the table exists
CREATE TABLE IF NOT EXISTS public.collection_schedules (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    zone VARCHAR(50) NOT NULL,
    collection_time TIMESTAMP WITH TIME ZONE NOT NULL,
    collector_id UUID REFERENCES public.registered_collectors(id) ON DELETE SET NULL,
    status VARCHAR(20) DEFAULT 'scheduled',
    description TEXT,
    is_rescheduled BOOLEAN DEFAULT FALSE,
    original_date TIMESTAMP WITH TIME ZONE,
    rescheduled_reason TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    name VARCHAR(255),
    scheduled_date TIMESTAMP WITH TIME ZONE
);

-- 2. Ensure RLS is enabled
ALTER TABLE public.collection_schedules ENABLE ROW LEVEL SECURITY;

-- 3. Ensure appropriate policies exist
DROP POLICY IF EXISTS "Everyone read collection_schedules" ON public.collection_schedules;
CREATE POLICY "Everyone read collection_schedules" ON public.collection_schedules FOR SELECT USING (true);

-- 4. Grant access to API roles
GRANT ALL ON TABLE public.collection_schedules TO postgres, service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.collection_schedules TO authenticated;
GRANT SELECT ON TABLE public.collection_schedules TO anon;

-- 5. Force PostgREST schema cache to reload
NOTIFY pgrst, reload_schema;
