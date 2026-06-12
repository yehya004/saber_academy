-- Migration 014: Quiz / Question Bank system
-- Teachers create reusable quizzes, assign them to students, students take timed quizzes.

-- ─────────────────────────────────────────────────────────────────────────────
-- quizzes  (quiz templates created by a teacher)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.quizzes (
  id          UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  teacher_id  UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title       TEXT        NOT NULL,
  description TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.quizzes ENABLE ROW LEVEL SECURITY;

-- Teacher: full CRUD on own quizzes
CREATE POLICY "teacher_all_quizzes"
  ON public.quizzes FOR ALL TO authenticated
  USING     (teacher_id = auth.uid())
  WITH CHECK (teacher_id = auth.uid());

-- ─────────────────────────────────────────────────────────────────────────────
-- quiz_questions  (individual questions inside a quiz)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.quiz_questions (
  id               UUID  DEFAULT gen_random_uuid() PRIMARY KEY,
  quiz_id          UUID  NOT NULL REFERENCES public.quizzes(id) ON DELETE CASCADE,
  question_text    TEXT  NOT NULL,
  question_type    TEXT  NOT NULL CHECK (question_type IN (
                     'true_false','single_choice','multiple_choice','fill_blank'
                   )),
  options          JSONB,      -- [{text, is_correct}] for choice types
  correct_answer   TEXT,       -- expected text for fill_blank
  telegram_file_id TEXT,       -- optional question image stored in Telegram
  hint             TEXT,
  points           INT   NOT NULL DEFAULT 1,
  time_seconds     INT,        -- optional per-question countdown timer (seconds)
  order_index      INT   NOT NULL DEFAULT 0,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.quiz_questions ENABLE ROW LEVEL SECURITY;

-- Teacher: full access to questions in own quizzes
CREATE POLICY "teacher_all_quiz_questions"
  ON public.quiz_questions FOR ALL TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.quizzes q WHERE q.id = quiz_id AND q.teacher_id = auth.uid())
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.quizzes q WHERE q.id = quiz_id AND q.teacher_id = auth.uid())
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- quiz_assignments  (quiz assigned to a specific student)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.quiz_assignments (
  id            UUID  DEFAULT gen_random_uuid() PRIMARY KEY,
  quiz_id       UUID  NOT NULL REFERENCES public.quizzes(id)    ON DELETE CASCADE,
  student_id    UUID  NOT NULL REFERENCES auth.users(id)         ON DELETE CASCADE,
  teacher_id    UUID  NOT NULL REFERENCES auth.users(id)         ON DELETE CASCADE,
  status        TEXT  NOT NULL DEFAULT 'pending'
                      CHECK (status IN ('pending', 'submitted')),
  total_points  INT   NOT NULL DEFAULT 0,
  earned_points INT,
  assigned_at   TIMESTAMPTZ DEFAULT NOW(),
  submitted_at  TIMESTAMPTZ,
  UNIQUE (quiz_id, student_id)
);

ALTER TABLE public.quiz_assignments ENABLE ROW LEVEL SECURITY;

-- Teacher: full access to assignments they created
CREATE POLICY "teacher_all_quiz_assignments"
  ON public.quiz_assignments FOR ALL TO authenticated
  USING     (teacher_id = auth.uid())
  WITH CHECK (teacher_id = auth.uid());

-- Student: read own assignments
CREATE POLICY "student_select_quiz_assignments"
  ON public.quiz_assignments FOR SELECT TO authenticated
  USING (student_id = auth.uid());

-- Student: update own assignment (to submit)
CREATE POLICY "student_update_quiz_assignments"
  ON public.quiz_assignments FOR UPDATE TO authenticated
  USING     (student_id = auth.uid())
  WITH CHECK (student_id = auth.uid());

-- Students: read questions for quizzes assigned to them
-- (defined after quiz_assignments so the relation exists)
CREATE POLICY "student_select_quiz_questions"
  ON public.quiz_questions FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.quiz_assignments a
      WHERE  a.quiz_id = quiz_id AND a.student_id = auth.uid()
    )
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- quiz_attempts  (each student answer for each question)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.quiz_attempts (
  id                 UUID  DEFAULT gen_random_uuid() PRIMARY KEY,
  assignment_id      UUID  NOT NULL REFERENCES public.quiz_assignments(id) ON DELETE CASCADE,
  question_id        UUID  NOT NULL REFERENCES public.quiz_questions(id)   ON DELETE CASCADE,
  student_answer     TEXT,       -- option index string for choices; text for fill_blank
  selected_options   JSONB,      -- [0, 2, ...] for multiple_choice
  is_correct         BOOLEAN,
  points_earned      INT,
  time_taken_seconds INT,
  answered_at        TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (assignment_id, question_id)
);

ALTER TABLE public.quiz_attempts ENABLE ROW LEVEL SECURITY;

-- Teacher: read attempts for their assignments
CREATE POLICY "teacher_select_quiz_attempts"
  ON public.quiz_attempts FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.quiz_assignments a
      WHERE  a.id = assignment_id AND a.teacher_id = auth.uid()
    )
  );

-- Student: insert own attempts
CREATE POLICY "student_insert_quiz_attempts"
  ON public.quiz_attempts FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.quiz_assignments a
      WHERE  a.id = assignment_id AND a.student_id = auth.uid()
    )
  );

-- Student: read own attempts
CREATE POLICY "student_select_quiz_attempts"
  ON public.quiz_attempts FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.quiz_assignments a
      WHERE  a.id = assignment_id AND a.student_id = auth.uid()
    )
  );

-- Student: update own attempts (upsert)
CREATE POLICY "student_update_quiz_attempts"
  ON public.quiz_attempts FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.quiz_assignments a
      WHERE  a.id = assignment_id AND a.student_id = auth.uid()
    )
  );
