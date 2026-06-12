-- Migration 024: Add telegram_file_id column to chat_messages table
ALTER TABLE public.chat_messages
  ADD COLUMN IF NOT EXISTS telegram_file_id TEXT;
