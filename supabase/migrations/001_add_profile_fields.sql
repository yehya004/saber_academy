-- ============================================================
-- Migration 001 — Add phone, country, avatar_url to profiles
-- ============================================================
-- Run this in: Supabase Dashboard → SQL Editor → New query
-- ============================================================

-- 1. Add new columns (safe to run more than once thanks to IF NOT EXISTS)
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS phone      TEXT,
  ADD COLUMN IF NOT EXISTS country    TEXT,
  ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- 2. Index on country for fast filtering (optional but useful)
CREATE INDEX IF NOT EXISTS profiles_country_idx ON public.profiles (country);
