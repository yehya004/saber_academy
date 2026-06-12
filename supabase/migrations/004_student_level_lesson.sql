-- ============================================================
-- Migration 004 — Add manual level & lesson fields to profiles
-- ============================================================
-- Run this in: Supabase Dashboard → SQL Editor → New query
-- ============================================================

-- 1. Add columns
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS level          INT DEFAULT 1,
  ADD COLUMN IF NOT EXISTS lesson_in_level INT DEFAULT 0;

-- 2. Allow teachers to update student level/lesson (extends migration 002)
--    Policy 002 already covers UPDATE for students by teachers, so no new
--    policy is needed — just make sure it's applied.
