/// One scheduled lesson slot: a weekday + UTC time.
/// [dayOfWeek] uses ISO weekday: 1=Mon … 7=Sun (stored/compared in UTC).
class DayScheduleEntry {
  final int dayOfWeek; // ISO weekday in UTC: 1=Mon … 7=Sun
  final int hourUtc;
  final int minuteUtc;

  const DayScheduleEntry({
    required this.dayOfWeek,
    required this.hourUtc,
    required this.minuteUtc,
  });

  factory DayScheduleEntry.fromMap(Map<String, dynamic> m) => DayScheduleEntry(
        dayOfWeek: (m['day']      as num).toInt(),
        hourUtc:   (m['hour_utc'] as num).toInt(),
        minuteUtc: (m['minute_utc'] as num).toInt(),
      );

  Map<String, dynamic> toMap() => {
        'day':       dayOfWeek,
        'hour_utc':  hourUtc,
        'minute_utc': minuteUtc,
      };
}

/// Mirrors the `lesson_schedules` table in Supabase.
/// All times are stored in UTC; timezone conversion is done in [TimezoneService].
class LessonScheduleModel {
  final String              id;
  final String              studentId;
  final String              teacherId;
  /// Per-day schedule entries — each day can have its own time.
  final List<DayScheduleEntry> daySchedules;
  final String              teacherTimezone; // IANA e.g. 'Africa/Cairo'
  final DateTime            updatedAt;

  const LessonScheduleModel({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.daySchedules,
    required this.teacherTimezone,
    required this.updatedAt,
  });

  factory LessonScheduleModel.fromMap(Map<String, dynamic> map) =>
      LessonScheduleModel(
        id:              map['id']              as String,
        studentId:       map['student_id']       as String,
        teacherId:       map['teacher_id']        as String,
        daySchedules: ((map['day_times'] as List?) ?? [])
            .map((e) => DayScheduleEntry.fromMap(e as Map<String, dynamic>))
            .toList(),
        teacherTimezone: map['teacher_timezone'] as String,
        updatedAt:       DateTime.parse(map['updated_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id':               id,
        'student_id':       studentId,
        'teacher_id':       teacherId,
        'day_times':        daySchedules.map((e) => e.toMap()).toList(),
        'teacher_timezone': teacherTimezone,
        'updated_at':       updatedAt.toIso8601String(),
      };
}
