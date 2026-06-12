-- ============================================================
-- Migration 036 — Update existing guest profiles
-- ============================================================
-- Run this in: Supabase Dashboard → SQL Editor → New query
-- ============================================================

UPDATE public.profiles
SET is_guest = TRUE
WHERE full_name LIKE 'زائر: %';
