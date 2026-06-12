-- Migration 022: Add chat file sharing support (10 MB limit) and quiz question passages

-- 1. Add file_url and file_name columns to chat_messages
ALTER TABLE public.chat_messages
  ADD COLUMN IF NOT EXISTS file_url TEXT,
  ADD COLUMN IF NOT EXISTS file_name TEXT;

-- 2. Add passage_text column to quiz_questions
ALTER TABLE public.quiz_questions
  ADD COLUMN IF NOT EXISTS passage_text TEXT;

-- 3. Create the chat-files storage bucket (public, 10 MB limit per file, any MIME type)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'chat-files',
  'chat-files',
  true,
  10485760,  -- 10 MB
  NULL       -- Any file type allowed
)
ON CONFLICT (id) DO NOTHING;

-- 4. Storage policy: authenticated users can upload to their own folder in chat-files
DROP POLICY IF EXISTS "chat_files_insert" ON storage.objects;
CREATE POLICY "chat_files_insert"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'chat-files' AND (storage.foldername(name))[1] = auth.uid()::text);

-- 5. Storage policy: anyone can read chat files
DROP POLICY IF EXISTS "chat_files_select" ON storage.objects;
CREATE POLICY "chat_files_select"
  ON storage.objects FOR SELECT TO public
  USING (bucket_id = 'chat-files');
