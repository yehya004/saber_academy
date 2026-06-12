-- Migration 015: Add missing student SELECT policies for quizzes table
-- Problem: quizzes table only had a teacher policy, so students couldn't read
--          the nested quizzes(*, quiz_questions(*)) join when fetching assignments.

-- Allow students to read quizzes that are assigned to them
CREATE POLICY "student_select_quizzes"
  ON public.quizzes FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.quiz_assignments a
      WHERE  a.quiz_id = id
        AND  a.student_id = auth.uid()
    )
  );
