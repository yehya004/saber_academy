-- ============================================================
-- Migration 010 — RLS policies for homeworks + sessions tables
-- ============================================================
-- Run this in: Supabase Dashboard → SQL Editor → New query
-- ============================================================

-- ── HOMEWORKS TABLE ──────────────────────────────────────────

-- Enable RLS (safe to re-run)
ALTER TABLE public.homeworks ENABLE ROW LEVEL SECURITY;

-- Teachers can INSERT homework (for any student)
DROP POLICY IF EXISTS "teacher_can_insert_homework" ON public.homeworks;
CREATE POLICY "teacher_can_insert_homework"
  ON public.homeworks
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'teacher'
  );

-- Teachers can read all homeworks they assigned
DROP POLICY IF EXISTS "teacher_can_read_homework" ON public.homeworks;
CREATE POLICY "teacher_can_read_homework"
  ON public.homeworks
  FOR SELECT
  TO authenticated
  USING (
    teacher_id = auth.uid()
    OR
    (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'teacher'
  );

-- Teachers can update (mark corrected)
DROP POLICY IF EXISTS "teacher_can_update_homework" ON public.homeworks;
CREATE POLICY "teacher_can_update_homework"
  ON public.homeworks
  FOR UPDATE
  TO authenticated
  USING (
    (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'teacher'
  );

-- Students can read their own homeworks
DROP POLICY IF EXISTS "student_can_read_own_homework" ON public.homeworks;
CREATE POLICY "student_can_read_own_homework"
  ON public.homeworks
  FOR SELECT
  TO authenticated
  USING (student_id = auth.uid());

-- Students can update their own homework (submit)
DROP POLICY IF EXISTS "student_can_update_own_homework" ON public.homeworks;
CREATE POLICY "student_can_update_own_homework"
  ON public.homeworks
  FOR UPDATE
  TO authenticated
  USING (student_id = auth.uid());

-- ── SESSIONS TABLE ───────────────────────────────────────────

-- Enable RLS (safe to re-run)
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;

-- Teachers can INSERT sessions
DROP POLICY IF EXISTS "teacher_can_insert_session" ON public.sessions;
CREATE POLICY "teacher_can_insert_session"
  ON public.sessions
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'teacher'
  );

-- Teachers can read all sessions
DROP POLICY IF EXISTS "teacher_can_read_sessions" ON public.sessions;
CREATE POLICY "teacher_can_read_sessions"
  ON public.sessions
  FOR SELECT
  TO authenticated
  USING (
    (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'teacher'
  );

-- Students can read their own sessions
DROP POLICY IF EXISTS "student_can_read_own_sessions" ON public.sessions;
CREATE POLICY "student_can_read_own_sessions"
  ON public.sessions
  FOR SELECT
  TO authenticated
  USING (student_id = auth.uid());
