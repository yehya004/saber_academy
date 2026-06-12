-- 005_lesson_schedules.sql
-- Weekly recurring lesson schedule per student.
-- Time is stored in UTC; the app converts to each user's local timezone.

CREATE TABLE lesson_schedules (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id       UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  teacher_id       UUID        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  days_of_week     INTEGER[]   NOT NULL,           -- 1=Mon … 7=Sun (ISO weekday, UTC)
  hour_utc         INTEGER     NOT NULL CHECK (hour_utc   BETWEEN 0 AND 23),
  minute_utc       INTEGER     NOT NULL CHECK (minute_utc BETWEEN 0 AND 59),
  teacher_timezone TEXT        NOT NULL,           -- IANA e.g. 'Africa/Cairo'
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (student_id)                              -- one active schedule per student
);

-- ── Row-Level Security ────────────────────────────────────────────────────────
ALTER TABLE lesson_schedules ENABLE ROW LEVEL SECURITY;

-- Teacher can INSERT / UPDATE / DELETE schedules they own
CREATE POLICY "teacher_manage_schedules"
  ON lesson_schedules
  FOR ALL
  TO authenticated
  USING     (teacher_id = auth.uid())
  WITH CHECK (teacher_id = auth.uid());

-- Student can SELECT only their own schedule
CREATE POLICY "student_read_own_schedule"
  ON lesson_schedules
  FOR SELECT
  TO authenticated
  USING (student_id = auth.uid());
