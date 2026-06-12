import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lesson_schedule_model.dart';

class LessonScheduleService {
  final _client = Supabase.instance.client;

  /// Returns the schedule for [studentId], or `null` if none exists.
  Future<LessonScheduleModel?> getScheduleForStudent(String studentId) async {
    final data = await _client
        .from('lesson_schedules')
        .select()
        .eq('student_id', studentId)
        .maybeSingle();
    if (data == null) return null;
    return LessonScheduleModel.fromMap(data);
  }

  /// Inserts or updates the schedule for [studentId] (upsert on student_id).
  /// [daySchedules] holds per-day UTC times.
  Future<void> upsertSchedule({
    required String                 studentId,
    required String                 teacherId,
    required List<DayScheduleEntry> daySchedules,
    required String                 teacherTimezone,
  }) async {
    await _client.from('lesson_schedules').upsert(
      {
        'student_id':       studentId,
        'teacher_id':       teacherId,
        'day_times':        daySchedules.map((e) => e.toMap()).toList(),
        'teacher_timezone': teacherTimezone,
        'updated_at':       DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'student_id',
    );
  }

  /// Removes the schedule for [studentId].
  Future<void> deleteSchedule(String studentId) async {
    await _client
        .from('lesson_schedules')
        .delete()
        .eq('student_id', studentId);
  }
}
