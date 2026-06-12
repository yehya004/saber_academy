-- Migration 016: Add image_url column to chat_messages + create chat-images storage bucket

-- 1. Add optional image_url column
ALTER TABLE public.chat_messages
  ADD COLUMN IF NOT EXISTS image_url TEXT;

-- 2. Create the chat-images storage bucket (public, 5 MB limit per file)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'chat-images',
  'chat-images',
  true,
  5242880,  -- 5 MB
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO NOTHING;

-- 3. Storage policy: authenticated users can upload to their own folder
CREATE POLICY "chat_images_insert"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'chat-images' AND (storage.foldername(name))[1] = auth.uid()::text);

-- 4. Storage policy: anyone can read chat images (public bucket)
CREATE POLICY "chat_images_select"
  ON storage.objects FOR SELECT TO public
  USING (bucket_id = 'chat-images');
