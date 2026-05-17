-- Create the artisan-media storage bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types, created_at, updated_at)
VALUES ('artisan-media', 'artisan-media', true, 5242880, NULL, now(), now())
ON CONFLICT (id) DO NOTHING;

-- Allow public uploads to artisan-media bucket
CREATE POLICY "Allow public uploads"
ON storage.objects
FOR INSERT
TO public
WITH CHECK (bucket_id = 'artisan-media');

-- Allow public reads from artisan-media bucket
CREATE POLICY "Allow public reads"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'artisan-media');

-- Allow public updates to artisan-media bucket
CREATE POLICY "Allow public updates"
ON storage.objects
FOR UPDATE
TO public
USING (bucket_id = 'artisan-media');

-- Allow public deletes from artisan-media bucket
CREATE POLICY "Allow public deletes"
ON storage.objects
FOR DELETE
TO public
USING (bucket_id = 'artisan-media');
