-- ============================================================
-- Migration 030 — Allow authenticated users to manage own profiles
-- ============================================================
-- Run this in: Supabase Dashboard → SQL Editor → New query
-- ============================================================

-- Allow authenticated users to insert their own profile row
DROP POLICY IF EXISTS "users_can_insert_own_profile" ON public.profiles;
CREATE POLICY "users_can_insert_own_profile"
  ON public.profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (id = auth.uid());

-- Allow authenticated users to update their own profile row
DROP POLICY IF EXISTS "users_can_update_own_profile" ON public.profiles;
CREATE POLICY "users_can_update_own_profile"
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (id = auth.uid());
