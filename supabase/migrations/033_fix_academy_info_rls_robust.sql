-- ============================================================
-- Migration 033 — Robust RLS Policies for academy_info Table
-- ============================================================
-- Run this in: Supabase Dashboard → SQL Editor → New query
-- ============================================================

-- 1. Create a security definer helper function to bypass RLS recursion/read issues on profiles
CREATE OR REPLACE FUNCTION public.is_teacher()
RETURNS BOOLEAN SECURITY DEFINER AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'teacher'
  );
END;
$$ LANGUAGE plpgsql;

-- 2. Drop existing policies to prevent conflicts
DROP POLICY IF EXISTS "teachers_can_update_academy_info" ON public.academy_info;
DROP POLICY IF EXISTS "teachers_can_all_academy_info" ON public.academy_info;

-- 3. Create the robust policy granting teachers full control (SELECT, INSERT, UPDATE, DELETE)
CREATE POLICY "teachers_can_all_academy_info"
  ON public.academy_info
  FOR ALL
  TO authenticated
  USING (public.is_teacher())
  WITH CHECK (public.is_teacher());
