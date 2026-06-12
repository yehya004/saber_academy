-- Migration 009: Add session detail columns (topic, homework, resource_url)
-- Allows teacher to record what was covered each session, assign homework,
-- and attach a link (book/resource) so student can reference it later.
ALTER TABLE sessions
  ADD COLUMN IF NOT EXISTS topic        TEXT,
  ADD COLUMN IF NOT EXISTS homework     TEXT,
  ADD COLUMN IF NOT EXISTS resource_url TEXT;
