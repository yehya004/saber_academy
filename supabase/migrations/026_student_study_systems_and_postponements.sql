-- ============================================================
-- Migration 026 — Student Study Systems, Attendance updates & Postponements
-- ============================================================

-- 1. Add fields to profiles for hours vs classes study system
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS study_system TEXT CHECK (study_system IN ('hours', 'classes')) DEFAULT 'classes';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS study_balance NUMERIC DEFAULT 0.0;

-- 2. Add 'late' to session_status enum (if not exists)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_type t 
    JOIN pg_enum e ON t.oid = e.enumtypid 
    WHERE t.typname = 'session_status' AND e.enumlabel = 'late'
  ) THEN
    ALTER TYPE public.session_status ADD VALUE 'late';
  END IF;
END
$$;

-- 3. Add deducted_amount to sessions
ALTER TABLE public.sessions ADD COLUMN IF NOT EXISTS deducted_amount NUMERIC DEFAULT 1.0;

-- 4. Create lesson_postponements table to track temporary class reschedules
CREATE TABLE IF NOT EXISTS public.lesson_postponements (
  id                  UUID            NOT NULL DEFAULT gen_random_uuid(),
  student_id          UUID            NOT NULL,
  teacher_id          UUID            NOT NULL,
  original_date_time  TIMESTAMPTZ     NOT NULL, -- original scheduled UTC date and time
  new_date_time       TIMESTAMPTZ     NOT NULL, -- rescheduled UTC date and time
  created_at          TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

  CONSTRAINT lesson_postponements_pkey PRIMARY KEY (id),
  CONSTRAINT lesson_postponements_student_fkey
    FOREIGN KEY (student_id) REFERENCES public.profiles (id) ON DELETE CASCADE,
  CONSTRAINT lesson_postponements_teacher_fkey
    FOREIGN KEY (teacher_id) REFERENCES public.profiles (id) ON DELETE CASCADE
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.lesson_postponements ENABLE ROW LEVEL SECURITY;

-- Policy for teachers: full access to postponements
DROP POLICY IF EXISTS "teacher_all_policy" ON public.lesson_postponements;
CREATE POLICY "teacher_all_policy"
  ON public.lesson_postponements
  FOR ALL
  TO authenticated
  USING (
    (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'teacher'
  );

-- Policy for students: full access to their own postponements
DROP POLICY IF EXISTS "student_all_policy" ON public.lesson_postponements;
CREATE POLICY "student_all_policy"
  ON public.lesson_postponements
  FOR ALL
  TO authenticated
  USING (student_id = auth.uid());
