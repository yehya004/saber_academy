-- ============================================================
-- Migration 035 — Add is_guest flag to profiles
-- ============================================================
-- Run this in: Supabase Dashboard → SQL Editor → New query
-- ============================================================

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS is_guest BOOLEAN NOT NULL DEFAULT FALSE;
