-- Add total_in_level column to profiles to allow custom level lessons/hours limit per student.
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS total_in_level NUMERIC NOT NULL DEFAULT 20.0;
