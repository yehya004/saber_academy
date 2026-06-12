-- ============================================================
-- Saber Academy — Supabase PostgreSQL Schema
-- Run this in your Supabase project's SQL Editor.
-- ============================================================

-- ============================================================
-- CUSTOM ENUM TYPES
-- ============================================================

CREATE TYPE public.user_role        AS ENUM ('teacher', 'student');
CREATE TYPE public.session_status   AS ENUM ('present', 'absent');
CREATE TYPE public.homework_status  AS ENUM ('pending', 'submitted', 'corrected');


-- ============================================================
-- TABLE 1: profiles
-- Extends auth.users. One row per authenticated user.
-- ============================================================

CREATE TABLE public.profiles (
  id                   UUID          NOT NULL,
  role                 user_role     NOT NULL DEFAULT 'student',
  full_name            TEXT          NOT NULL DEFAULT '',
  language_preference  CHAR(2)       NOT NULL DEFAULT 'ar'
                         CHECK (language_preference IN ('en', 'ar', 'tr')),
  created_at           TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey
    FOREIGN KEY (id) REFERENCES auth.users (id) ON DELETE CASCADE
);

COMMENT ON TABLE  public.profiles IS 'Extended user profile, one row per auth.users entry.';
COMMENT ON COLUMN public.profiles.role IS 'teacher = Mr. Saber (admin), student = learner.';

-- Auto-create a profile row whenever a new user signs up via Supabase Auth.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', '')
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();


-- ============================================================
-- TABLE 2: sessions
-- Tracks each 1-on-1 lesson (present / absent).
-- ============================================================

CREATE TABLE public.sessions (
  id               UUID            NOT NULL DEFAULT gen_random_uuid(),
  student_id       UUID            NOT NULL,
  teacher_id       UUID            NOT NULL,
  session_date     DATE            NOT NULL DEFAULT CURRENT_DATE,
  status           session_status  NOT NULL DEFAULT 'present',
  absence_excuse   TEXT,
  created_at       TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

  CONSTRAINT sessions_pkey PRIMARY KEY (id),
  CONSTRAINT sessions_student_fkey
    FOREIGN KEY (student_id) REFERENCES public.profiles (id) ON DELETE CASCADE,
  CONSTRAINT sessions_teacher_fkey
    FOREIGN KEY (teacher_id) REFERENCES public.profiles (id) ON DELETE CASCADE
);

COMMENT ON TABLE  public.sessions IS '1-on-1 session log. Level = (COUNT(status=present) / 20) + 1.';
COMMENT ON COLUMN public.sessions.absence_excuse IS 'Optional reason for absence; populated by teacher.';

CREATE INDEX idx_sessions_student_id   ON public.sessions (student_id);
CREATE INDEX idx_sessions_teacher_id   ON public.sessions (teacher_id);
CREATE INDEX idx_sessions_session_date ON public.sessions (session_date DESC);


-- ============================================================
-- TABLE 3: homeworks
-- Assignment lifecycle: pending → submitted → corrected.
-- ============================================================

CREATE TABLE public.homeworks (
  id                     UUID             NOT NULL DEFAULT gen_random_uuid(),
  student_id             UUID             NOT NULL,
  teacher_id             UUID             NOT NULL,
  assignment_text        TEXT             NOT NULL CHECK (char_length(assignment_text) > 0),
  status                 homework_status  NOT NULL DEFAULT 'pending',
  student_image_url      TEXT,
  teacher_correction_url TEXT,
  created_at             TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
  updated_at             TIMESTAMPTZ      NOT NULL DEFAULT NOW(),

  CONSTRAINT homeworks_pkey PRIMARY KEY (id),
  CONSTRAINT homeworks_student_fkey
    FOREIGN KEY (student_id) REFERENCES public.profiles (id) ON DELETE CASCADE,
  CONSTRAINT homeworks_teacher_fkey
    FOREIGN KEY (teacher_id) REFERENCES public.profiles (id) ON DELETE CASCADE
);

COMMENT ON TABLE  public.homeworks IS 'Homework assignments with image upload support via Supabase Storage.';
COMMENT ON COLUMN public.homeworks.student_image_url      IS 'Public URL of student submission image in Storage bucket.';
COMMENT ON COLUMN public.homeworks.teacher_correction_url IS 'Public URL of teacher correction image in Storage bucket.';

CREATE INDEX idx_homeworks_student_id ON public.homeworks (student_id);
CREATE INDEX idx_homeworks_status     ON public.homeworks (status);

-- Auto-update updated_at timestamp on every UPDATE.
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_homework_updated
  BEFORE UPDATE ON public.homeworks
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();


-- ============================================================
-- TABLE 4: chat_messages
-- Real-time 1-on-1 direct messages (Supabase Realtime).
-- ============================================================

CREATE TABLE public.chat_messages (
  id            UUID         NOT NULL DEFAULT gen_random_uuid(),
  sender_id     UUID         NOT NULL,
  receiver_id   UUID         NOT NULL,
  message_text  TEXT         NOT NULL CHECK (char_length(message_text) > 0),
  is_read       BOOLEAN      NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

  CONSTRAINT chat_messages_pkey PRIMARY KEY (id),
  CONSTRAINT chat_messages_sender_fkey
    FOREIGN KEY (sender_id)   REFERENCES public.profiles (id) ON DELETE CASCADE,
  CONSTRAINT chat_messages_receiver_fkey
    FOREIGN KEY (receiver_id) REFERENCES public.profiles (id) ON DELETE CASCADE,
  CONSTRAINT no_self_message
    CHECK (sender_id <> receiver_id)
);

COMMENT ON TABLE public.chat_messages IS 'Direct messages between teacher and student, streamed via Supabase Realtime.';

CREATE INDEX idx_chat_messages_sender_id   ON public.chat_messages (sender_id);
CREATE INDEX idx_chat_messages_receiver_id ON public.chat_messages (receiver_id);
CREATE INDEX idx_chat_messages_created_at  ON public.chat_messages (created_at ASC);

-- Enable Realtime on chat_messages (run in Supabase Dashboard → Database → Replication).
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;
