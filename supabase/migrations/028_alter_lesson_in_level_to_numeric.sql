-- Migration 028: Alter lesson_in_level in profiles to NUMERIC to support decimal hours
ALTER TABLE public.profiles
  ALTER COLUMN lesson_in_level TYPE NUMERIC;
