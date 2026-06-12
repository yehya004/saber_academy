-- Migration 017: Relax message_text check constraint to allow empty text for image-only messages

-- Drop the old constraint that requires message_text to be non-empty
ALTER TABLE public.chat_messages
  DROP CONSTRAINT IF EXISTS chat_messages_message_text_check;

-- Add a new constraint: either the text is non-empty, or there is a non-empty image_url
ALTER TABLE public.chat_messages
  ADD CONSTRAINT chat_messages_message_text_check
    CHECK (
      (length(trim(message_text)) > 0)
      OR
      (image_url IS NOT NULL AND image_url <> '')
    );
