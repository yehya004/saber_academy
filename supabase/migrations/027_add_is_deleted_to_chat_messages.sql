-- Migration 027: Add is_deleted column to chat_messages table
ALTER TABLE public.chat_messages
  ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN NOT NULL DEFAULT false;
