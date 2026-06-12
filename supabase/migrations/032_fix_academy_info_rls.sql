-- ============================================================
-- Migration 032 — Fix academy_info RLS policies for teachers
-- ============================================================
-- Run this in: Supabase Dashboard → SQL Editor → New query
-- ============================================================

DROP POLICY IF EXISTS "teachers_can_update_academy_info" ON public.academy_info;
DROP POLICY IF EXISTS "teachers_can_all_academy_info" ON public.academy_info;

CREATE POLICY "teachers_can_all_academy_info"
  ON public.academy_info
  FOR ALL
  TO authenticated
  USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'teacher')
  WITH CHECK ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'teacher');
