-- Migration 013: homework_files table
-- Each homework can have multiple files uploaded via Telegram.

CREATE TABLE IF NOT EXISTS public.homework_files (
  id               UUID         DEFAULT gen_random_uuid() PRIMARY KEY,
  homework_id      UUID         NOT NULL REFERENCES public.homeworks(id) ON DELETE CASCADE,
  telegram_file_id TEXT         NOT NULL,
  file_name        TEXT         NOT NULL DEFAULT '',
  created_at       TIMESTAMPTZ  DEFAULT NOW()
);

ALTER TABLE public.homework_files ENABLE ROW LEVEL SECURITY;

-- ── Student policies ──────────────────────────────────────────────────────────

-- Students can insert files for their own homeworks
CREATE POLICY "student_insert_homework_files"
  ON public.homework_files
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.homeworks h
      WHERE h.id = homework_id
        AND h.student_id = auth.uid()
    )
  );

-- Students can select files for their own homeworks
CREATE POLICY "student_select_homework_files"
  ON public.homework_files
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.homeworks h
      WHERE h.id = homework_id
        AND h.student_id = auth.uid()
    )
  );

-- Students can delete files for their own homeworks (unless corrected)
CREATE POLICY "student_delete_homework_files"
  ON public.homework_files
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.homeworks h
      WHERE h.id = homework_id
        AND h.student_id = auth.uid()
        AND h.status <> 'corrected'
    )
  );

-- ── Teacher policies ──────────────────────────────────────────────────────────

-- Teachers can select all homework files
CREATE POLICY "teacher_select_homework_files"
  ON public.homework_files
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.homeworks h
      WHERE h.id = homework_id
        AND h.teacher_id = auth.uid()
    )
  );

-- Teachers can delete homework files (e.g. when deleting a correction)
CREATE POLICY "teacher_delete_homework_files"
  ON public.homework_files
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.homeworks h
      WHERE h.id = homework_id
        AND h.teacher_id = auth.uid()
    )
  );
