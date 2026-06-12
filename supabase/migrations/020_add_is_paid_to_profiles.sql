-- ============================================================
-- Migration 020 — Add is_paid and is_blocked columns to profiles table
-- Run this in your Supabase project's SQL Editor.
-- ============================================================

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS is_paid BOOLEAN NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS is_blocked BOOLEAN NOT NULL DEFAULT FALSE;
