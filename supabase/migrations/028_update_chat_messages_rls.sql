-- Migration 028: Update RLS policies for chat_messages to allow deletions and teacher moderation
-- Run this in: Supabase Dashboard → SQL Editor → New query

DROP POLICY IF EXISTS "receiver_can_mark_read" ON public.chat_messages;
DROP POLICY IF EXISTS "chat_messages_update_policy" ON public.chat_messages;

CREATE POLICY "chat_messages_update_policy"
  ON public.chat_messages
  FOR UPDATE
  TO authenticated
  USING (
    sender_id = auth.uid() OR 
    receiver_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.profiles 
      WHERE id = auth.uid() AND role = 'teacher'
    )
  );
