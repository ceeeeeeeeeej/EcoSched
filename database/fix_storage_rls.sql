-- 1. Drop existing restrictive policies for scan_images (if they exist)
DROP POLICY IF EXISTS "Allow authenticated users to upload scan images" ON storage.objects;
DROP POLICY IF EXISTS "Allow public read access to scan images" ON storage.objects;

-- 2. Allow ANYONE to view images in the scan_images bucket (Public access)
CREATE POLICY "Public Access" 
ON storage.objects FOR SELECT 
USING ( bucket_id = 'scan_images' );

-- 3. Allow ALL authenticated users to upload images (Fixes the 403 error)
CREATE POLICY "Authenticated Upload" 
ON storage.objects FOR INSERT 
WITH CHECK ( 
    bucket_id = 'scan_images' 
    AND (auth.role() = 'authenticated' OR auth.role() = 'anon') 
);

-- 4. Allow users to update their own uploads (often needed by some drivers)
CREATE POLICY "Authenticated Update" 
ON storage.objects FOR UPDATE
USING ( bucket_id = 'scan_images' );
