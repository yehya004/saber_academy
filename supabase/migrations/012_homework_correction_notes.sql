-- ============================================================
-- Migration 012 — Add correction_notes column to homeworks
-- ============================================================
-- Run this in: Supabase Dashboard → SQL Editor → New query
-- ============================================================

ALTER TABLE public.homeworks
  ADD COLUMN IF NOT EXISTS correction_notes TEXT;
