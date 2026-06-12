-- ============================================================
-- Migration 011 — Add telegram_file_id column to homeworks
-- ============================================================
-- Run this in: Supabase Dashboard → SQL Editor → New query
-- (Skip if column already exists — IF NOT EXISTS is safe to re-run)
-- ============================================================

ALTER TABLE public.homeworks
  ADD COLUMN IF NOT EXISTS telegram_file_id TEXT;
