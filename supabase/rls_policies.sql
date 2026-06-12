-- ============================================================
-- Saber Academy — Row-Level Security (RLS) Policies
-- Run AFTER schema.sql. Paste into Supabase SQL Editor.
-- ============================================================

-- ============================================================
-- HELPER: get the calling user's role from profiles.
-- SECURITY DEFINER so students cannot bypass the lookup.
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS public.user_role
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$;


-- ============================================================
-- ENABLE RLS ON ALL TABLES
-- ============================================================

ALTER TABLE public.profiles      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.homeworks     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- PROFILES — Policies
-- ============================================================

-- Teacher: unrestricted CRUD on all profiles (manage students).
CREATE POLICY "teacher_all_profiles"
  ON public.profiles
  FOR ALL
  TO authenticated
  USING      (public.get_my_role() = 'teacher')
  WITH CHECK (public.get_my_role() = 'teacher');

-- Student: read their own profile only.
CREATE POLICY "student_select_own_profile"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (id = auth.uid());

-- Student: update their own profile (e.g. language_preference).
CREATE POLICY "student_update_own_profile"
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING      (id = auth.uid())
  WITH CHECK (id = auth.uid());


-- ============================================================
-- SESSIONS — Policies
-- ============================================================

-- Teacher: full CRUD (marks attendance, edits excuse notes).
CREATE POLICY "teacher_all_sessions"
  ON public.sessions
  FOR ALL
  TO authenticated
  USING      (public.get_my_role() = 'teacher')
  WITH CHECK (public.get_my_role() = 'teacher');

-- Student: read-only access to their own session records.
CREATE POLICY "student_select_own_sessions"
  ON public.sessions
  FOR SELECT
  TO authenticated
  USING (student_id = auth.uid());


-- ============================================================
-- HOMEWORKS — Policies
-- ============================================================

-- Teacher: full CRUD (assigns, reviews, corrects homework).
CREATE POLICY "teacher_all_homeworks"
  ON public.homeworks
  FOR ALL
  TO authenticated
  USING      (public.get_my_role() = 'teacher')
  WITH CHECK (public.get_my_role() = 'teacher');

-- Student: read their own homework assignments.
CREATE POLICY "student_select_own_homeworks"
  ON public.homeworks
  FOR SELECT
  TO authenticated
  USING (student_id = auth.uid());

-- Student: update their own homework (submit image, status → 'submitted').
-- The teacher's correction columns are naturally protected: only the teacher
-- policy (above) permits writing teacher_correction_url or status='corrected'.
CREATE POLICY "student_update_own_homeworks"
  ON public.homeworks
  FOR UPDATE
  TO authenticated
  USING      (student_id = auth.uid())
  WITH CHECK (student_id = auth.uid());


-- ============================================================
-- CHAT_MESSAGES — Policies
-- ============================================================

-- Teacher: full access across all conversations.
CREATE POLICY "teacher_all_chat"
  ON public.chat_messages
  FOR ALL
  TO authenticated
  USING      (public.get_my_role() = 'teacher')
  WITH CHECK (public.get_my_role() = 'teacher');

-- Student: read messages in which they are a participant.
CREATE POLICY "student_select_own_messages"
  ON public.chat_messages
  FOR SELECT
  TO authenticated
  USING (sender_id = auth.uid() OR receiver_id = auth.uid());

-- Student: insert messages they send (sender must be themselves).
CREATE POLICY "student_insert_own_messages"
  ON public.chat_messages
  FOR INSERT
  TO authenticated
  WITH CHECK (sender_id = auth.uid());

-- Student: update is_read on messages they received (mark as read).
CREATE POLICY "student_update_received_messages"
  ON public.chat_messages
  FOR UPDATE
  TO authenticated
  USING      (receiver_id = auth.uid())
  WITH CHECK (receiver_id = auth.uid());


-- ============================================================
-- QUIZ TABLES — Enable RLS
-- ============================================================

ALTER TABLE public.quizzes           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_questions    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_assignments  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_attempts     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lesson_schedules  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.homework_files    ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- QUIZZES — Policies
-- ============================================================

DROP POLICY IF EXISTS "teacher_all_quizzes"           ON public.quizzes;
DROP POLICY IF EXISTS "student_select_quizzes"        ON public.quizzes;
DROP POLICY IF EXISTS "student_select_assigned_quizzes" ON public.quizzes;

-- Teacher: full CRUD on their own quizzes.
CREATE POLICY "teacher_all_quizzes"
  ON public.quizzes
  FOR ALL
  TO authenticated
  USING      (public.get_my_role() = 'teacher')
  WITH CHECK (public.get_my_role() = 'teacher');

-- Student: read quizzes assigned to them only.
CREATE POLICY "student_select_assigned_quizzes"
  ON public.quizzes
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.quiz_assignments qa
      WHERE qa.quiz_id    = id
        AND qa.student_id = auth.uid()
    )
  );


-- ============================================================
-- QUIZ_QUESTIONS — Policies
-- ============================================================

DROP POLICY IF EXISTS "teacher_all_quiz_questions"    ON public.quiz_questions;
DROP POLICY IF EXISTS "student_select_quiz_questions" ON public.quiz_questions;

-- Teacher: full CRUD.
CREATE POLICY "teacher_all_quiz_questions"
  ON public.quiz_questions
  FOR ALL
  TO authenticated
  USING      (public.get_my_role() = 'teacher')
  WITH CHECK (public.get_my_role() = 'teacher');

-- Student: read questions for quizzes assigned to them.
CREATE POLICY "student_select_quiz_questions"
  ON public.quiz_questions
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM   public.quiz_assignments qa
      WHERE  qa.quiz_id    = quiz_id
        AND  qa.student_id = auth.uid()
    )
  );


-- ============================================================
-- QUIZ_ASSIGNMENTS — Policies
-- ============================================================

DROP POLICY IF EXISTS "teacher_all_quiz_assignments"    ON public.quiz_assignments;
DROP POLICY IF EXISTS "student_select_quiz_assignments" ON public.quiz_assignments;
DROP POLICY IF EXISTS "student_update_quiz_assignments" ON public.quiz_assignments;
DROP POLICY IF EXISTS "student_select_own_assignments"  ON public.quiz_assignments;
DROP POLICY IF EXISTS "student_update_own_assignments"  ON public.quiz_assignments;

-- Teacher: full CRUD.
CREATE POLICY "teacher_all_quiz_assignments"
  ON public.quiz_assignments
  FOR ALL
  TO authenticated
  USING      (public.get_my_role() = 'teacher')
  WITH CHECK (public.get_my_role() = 'teacher');

-- Student: read their own assignments.
CREATE POLICY "student_select_own_assignments"
  ON public.quiz_assignments
  FOR SELECT
  TO authenticated
  USING (student_id = auth.uid());

-- Student: update their own assignment (submit attempt, update status).
CREATE POLICY "student_update_own_assignments"
  ON public.quiz_assignments
  FOR UPDATE
  TO authenticated
  USING      (student_id = auth.uid())
  WITH CHECK (student_id = auth.uid());


-- ============================================================
-- QUIZ_ATTEMPTS — Policies
-- ============================================================

DROP POLICY IF EXISTS "teacher_select_quiz_attempts"  ON public.quiz_attempts;
DROP POLICY IF EXISTS "student_insert_quiz_attempts"  ON public.quiz_attempts;
DROP POLICY IF EXISTS "student_select_quiz_attempts"  ON public.quiz_attempts;
DROP POLICY IF EXISTS "student_insert_own_attempts"   ON public.quiz_attempts;
DROP POLICY IF EXISTS "student_select_own_attempts"   ON public.quiz_attempts;

-- Teacher: read all attempts for review.
CREATE POLICY "teacher_select_quiz_attempts"
  ON public.quiz_attempts
  FOR SELECT
  TO authenticated
  USING (public.get_my_role() = 'teacher');

-- Student: insert their own attempts.
CREATE POLICY "student_insert_own_attempts"
  ON public.quiz_attempts
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.quiz_assignments qa
      WHERE  qa.id         = assignment_id
        AND  qa.student_id = auth.uid()
    )
  );

-- Student: read their own attempts.
CREATE POLICY "student_select_own_attempts"
  ON public.quiz_attempts
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.quiz_assignments qa
      WHERE  qa.id         = assignment_id
        AND  qa.student_id = auth.uid()
    )
  );


-- ============================================================
-- LESSON_SCHEDULES — Policies
-- ============================================================

DROP POLICY IF EXISTS "teacher_all_lesson_schedules" ON public.lesson_schedules;
DROP POLICY IF EXISTS "student_select_own_schedule"  ON public.lesson_schedules;

-- Teacher: full CRUD.
CREATE POLICY "teacher_all_lesson_schedules"
  ON public.lesson_schedules
  FOR ALL
  TO authenticated
  USING      (public.get_my_role() = 'teacher')
  WITH CHECK (public.get_my_role() = 'teacher');

-- Student: read their own schedule.
CREATE POLICY "student_select_own_schedule"
  ON public.lesson_schedules
  FOR SELECT
  TO authenticated
  USING (student_id = auth.uid());


-- ============================================================
-- HOMEWORK_FILES — Policies
-- ============================================================

DROP POLICY IF EXISTS "teacher_all_homework_files"           ON public.homework_files;
DROP POLICY IF EXISTS "student_select_own_homework_files"    ON public.homework_files;
DROP POLICY IF EXISTS "student_insert_own_homework_files"    ON public.homework_files;

-- Teacher: full CRUD.
CREATE POLICY "teacher_all_homework_files"
  ON public.homework_files
  FOR ALL
  TO authenticated
  USING      (public.get_my_role() = 'teacher')
  WITH CHECK (public.get_my_role() = 'teacher');

-- Student: read files for their own homeworks.
CREATE POLICY "student_select_own_homework_files"
  ON public.homework_files
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.homeworks h
      WHERE  h.id         = homework_id
        AND  h.student_id = auth.uid()
    )
  );

-- Student: insert files for their own homeworks.
CREATE POLICY "student_insert_own_homework_files"
  ON public.homework_files
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.homeworks h
      WHERE  h.id         = homework_id
        AND  h.student_id = auth.uid()
    )
  );


-- ============================================================
-- PERFORMANCE INDEXES (run after schema.sql)
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_quiz_assignments_student_id
  ON public.quiz_assignments (student_id);

CREATE INDEX IF NOT EXISTS idx_quiz_assignments_teacher_id
  ON public.quiz_assignments (teacher_id);

CREATE INDEX IF NOT EXISTS idx_quiz_attempts_assignment_id
  ON public.quiz_attempts (assignment_id);

CREATE INDEX IF NOT EXISTS idx_lesson_schedules_student_id
  ON public.lesson_schedules (student_id);

CREATE INDEX IF NOT EXISTS idx_lesson_schedules_teacher_id
  ON public.lesson_schedules (teacher_id);

CREATE INDEX IF NOT EXISTS idx_profiles_role
  ON public.profiles (role);


-- ============================================================
-- REALTIME — Enable on chat_messages
-- Already enabled via Supabase Dashboard or a previous migration.
-- Uncomment only if running on a fresh project:
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;
-- ============================================================
