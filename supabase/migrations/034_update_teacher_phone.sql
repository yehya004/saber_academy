-- ============================================================
-- Migration 034 — Update profiles SELECT policy & teacher phone
-- ============================================================
-- Run this in: Supabase Dashboard → SQL Editor → New query
-- ============================================================

-- 1. Update profiles select policy to allow reading teacher profiles without authentication
DROP POLICY IF EXISTS "authenticated_can_read_profiles" ON public.profiles;
CREATE POLICY "authenticated_can_read_profiles"
  ON public.profiles
  FOR SELECT
  USING (role = 'teacher' OR auth.role() = 'authenticated');

-- 2. Update the phone number for the teacher
UPDATE public.profiles
SET phone = '+201289212204'
WHERE role = 'teacher';
