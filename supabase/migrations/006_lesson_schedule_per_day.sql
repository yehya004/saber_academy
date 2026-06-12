-- Migration 006: Change lesson_schedules to per-day time storage
-- Old schema had a single (days_of_week[], hour_utc, minute_utc).
-- New schema stores day_times JSONB: [{"day":1,"hour_utc":14,"minute_utc":0}, ...]
-- ISO weekday: 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat, 7=Sun (UTC)

ALTER TABLE lesson_schedules
  DROP COLUMN IF EXISTS days_of_week,
  DROP COLUMN IF EXISTS hour_utc,
  DROP COLUMN IF EXISTS minute_utc,
  ADD COLUMN IF NOT EXISTS day_times JSONB NOT NULL DEFAULT '[]'::jsonb;

COMMENT ON COLUMN lesson_schedules.day_times IS
  'Array of {day, hour_utc, minute_utc} objects — one entry per scheduled weekday.
   day uses ISO weekday (1=Mon … 7=Sun) in UTC.
   Example: [{"day":1,"hour_utc":14,"minute_utc":0},{"day":4,"hour_utc":17,"minute_utc":30}]';
