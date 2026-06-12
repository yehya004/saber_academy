-- Migration 008: Add messenger_link column to profiles
-- Stores Messenger/Facebook link separately from WhatsApp number.
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS messenger_link TEXT;
