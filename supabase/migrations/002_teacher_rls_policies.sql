-- ============================================================
-- Migration 002 — RLS policies for teacher creating students
-- ============================================================
-- Run this in: Supabase Dashboard → SQL Editor → New query
-- ============================================================

-- Allow a teacher to INSERT a new profile row for a student they just created.
-- Condition: the caller's own profile has role = 'teacher'
DROP POLICY IF EXISTS "teacher_can_insert_student_profile" ON public.profiles;
CREATE POLICY "teacher_can_insert_student_profile"
  ON public.profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (
      SELECT role FROM public.profiles WHERE id = auth.uid()
    ) = 'teacher'
  );

-- Allow a teacher to UPDATE any student profile row
-- (needed if you later want teachers to edit student info directly).
DROP POLICY IF EXISTS "teacher_can_update_student_profile" ON public.profiles;
CREATE POLICY "teacher_can_update_student_profile"
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (
    (
      SELECT role FROM public.profiles WHERE id = auth.uid()
    ) = 'teacher'
    AND role = 'student'
  );

-- Allow every authenticated user to read all profiles
-- (needed for teacher to see their students list).
-- Skip this if you already have a SELECT policy.
DROP POLICY IF EXISTS "authenticated_can_read_profiles" ON public.profiles;
CREATE POLICY "authenticated_can_read_profiles"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (true);
