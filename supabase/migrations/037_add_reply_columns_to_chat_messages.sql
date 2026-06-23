-- Migration 037: Add reply columns to chat_messages table
-- Run this in: Supabase Dashboard → SQL Editor → New query

ALTER TABLE public.chat_messages
  ADD COLUMN IF NOT EXISTS reply_to_id UUID REFERENCES public.chat_messages(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS reply_to_text TEXT,
  ADD COLUMN IF NOT EXISTS reply_to_sender_name TEXT;
