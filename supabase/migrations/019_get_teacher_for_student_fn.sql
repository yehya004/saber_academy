-- ============================================================
-- Migration 019 — SECURITY DEFINER function: get teacher for student
-- ============================================================
-- Run this in: Supabase Dashboard → SQL Editor → New query
-- ============================================================
-- This function BYPASSES RLS so the student can always find their
-- teacher regardless of which RLS policies are currently active.
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_teacher_for_student(p_student_id uuid)
RETURNS SETOF public.profiles
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_teacher_id uuid;
BEGIN
  -- 1. Try lesson_schedules
  SELECT teacher_id INTO v_teacher_id
  FROM public.lesson_schedules
  WHERE student_id = p_student_id
  LIMIT 1;

  IF v_teacher_id IS NOT NULL THEN
    RETURN QUERY SELECT * FROM public.profiles WHERE id = v_teacher_id LIMIT 1;
    RETURN;
  END IF;

  -- 2. Try sessions
  SELECT teacher_id INTO v_teacher_id
  FROM public.sessions
  WHERE student_id = p_student_id
  LIMIT 1;

  IF v_teacher_id IS NOT NULL THEN
    RETURN QUERY SELECT * FROM public.profiles WHERE id = v_teacher_id LIMIT 1;
    RETURN;
  END IF;

  -- 3. Fallback: first teacher in the system
  RETURN QUERY SELECT * FROM public.profiles WHERE role = 'teacher' LIMIT 1;
END;
$$;

-- Allow any authenticated user to call it
GRANT EXECUTE ON FUNCTION public.get_teacher_for_student(uuid) TO authenticated;
