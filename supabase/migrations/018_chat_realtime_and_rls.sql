-- ============================================================
-- Migration 018 — Enable realtime + RLS for chat_messages
-- ============================================================
-- Run this in: Supabase Dashboard → SQL Editor → New query
-- ============================================================

-- ── 1. Enable RLS on chat_messages ──────────────────────────
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

-- Sender or receiver can read messages
DROP POLICY IF EXISTS "users_can_read_own_messages" ON public.chat_messages;
CREATE POLICY "users_can_read_own_messages"
  ON public.chat_messages
  FOR SELECT
  TO authenticated
  USING (sender_id = auth.uid() OR receiver_id = auth.uid());

-- Only the sender can insert (sender_id must equal auth.uid())
DROP POLICY IF EXISTS "users_can_send_messages" ON public.chat_messages;
CREATE POLICY "users_can_send_messages"
  ON public.chat_messages
  FOR INSERT
  TO authenticated
  WITH CHECK (sender_id = auth.uid());

-- Only the receiver can mark messages as read
DROP POLICY IF EXISTS "receiver_can_mark_read" ON public.chat_messages;
CREATE POLICY "receiver_can_mark_read"
  ON public.chat_messages
  FOR UPDATE
  TO authenticated
  USING (receiver_id = auth.uid());

-- ── 2. Add chat_messages to realtime publication ─────────────
-- This enables live updates so the Flutter .stream() API
-- receives new rows without the user having to reload.
ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;
