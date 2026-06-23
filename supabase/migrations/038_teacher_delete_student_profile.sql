-- Migration 038: RLS Policy to allow teachers to delete student profiles
-- Run this in: Supabase Dashboard → SQL Editor → New query

-- Allow a teacher to delete a student profile row.
DROP POLICY IF EXISTS "teacher_can_delete_student_profile" ON public.profiles;
CREATE POLICY "teacher_can_delete_student_profile"
  ON public.profiles
  FOR DELETE
  TO authenticated
  USING (
    (
      SELECT role FROM public.profiles WHERE id = auth.uid()
    ) = 'teacher'
    AND role = 'student'
  );
