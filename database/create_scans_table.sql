-- 1. Create the AI Scans table
CREATE TABLE IF NOT EXISTS ai_scans (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    image_path TEXT NOT NULL, -- The path within the storage bucket
    image_url TEXT, -- The public or signed URL if applicable
    label VARCHAR(100) NOT NULL,
    confidence DECIMAL(5, 4),
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create index for performance
CREATE INDEX IF NOT EXISTS idx_ai_scans_user_id ON ai_scans(user_id);

-- 3. Enable RLS
ALTER TABLE ai_scans ENABLE ROW LEVEL SECURITY;

-- 4. Policies
-- Users can only see their own scans
CREATE POLICY "Users can view own scans" ON ai_scans
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own scans
CREATE POLICY "Users can insert own scans" ON ai_scans
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Admins can see all scans
CREATE POLICY "Admins can view all scans" ON ai_scans
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
    );

-- 5. Storage Policies (Standard Supabase Storage)
-- Note: The bucket 'scan_images' must be created in the Supabase UI first.
-- These policies assume the bucket exists.

CREATE POLICY "Allow public read access to scan images"
ON storage.objects FOR SELECT
USING ( bucket_id = 'scan_images' );

CREATE POLICY "Allow authenticated users to upload scan images"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'scan_images' 
    AND auth.role() = 'authenticated'
);
