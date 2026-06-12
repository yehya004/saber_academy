-- Migration 007: Add email column to profiles table
-- Stores student email so teachers can view it in the student detail screen.
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS email TEXT;
