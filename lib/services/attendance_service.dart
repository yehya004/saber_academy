import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';
import '../models/session_model.dart';

class AttendanceService {
  final _client = Supabase.instance.client;

  /// Returns all sessions for [studentId], newest first.
  Future<List<SessionModel>> fetchStudentSessions(String studentId) async {
    final data = await _client
        .from('sessions')
        .select()
        .eq('student_id', studentId)
        .order('session_date', ascending: false);

    return data.map((e) => SessionModel.fromMap(e)).toList();
  }

  /// Teacher marks a session for a student.
  /// If status is 'present', also increments lesson_in_level on the profile
  /// (and advances level when it reaches 20).
  Future<void> markAttendance({
    required String studentId,
    required String teacherId,
    required DateTime sessionDate,
    required String status,
    String? absenceExcuse,
    String? topic,
    String? homework,
    String? resourceUrl,
    double deductedAmount = 1.0,
    bool deductForAbsence = false,
  }) async {
    await _client.from('sessions').insert({
      'student_id': studentId,
      'teacher_id': teacherId,
      'session_date': sessionDate.toIso8601String().split('T').first,
      'status': status,
      'deducted_amount': deductedAmount,
      if (absenceExcuse != null && absenceExcuse.isNotEmpty)
        'absence_excuse': absenceExcuse,
      if (topic != null && topic.isNotEmpty) 'topic': topic,
      if (homework != null && homework.isNotEmpty) 'homework': homework,
      if (resourceUrl != null && resourceUrl.isNotEmpty)
        'resource_url': resourceUrl,
    });

    // Auto-increment lesson_in_level when present or late
    if (status == 'present' || status == 'late') {
      final profile = await _client
          .from('profiles')
          .select('level, lesson_in_level, study_system')
          .eq('id', studentId)
          .maybeSingle();

      int level = (profile?['level'] as int?) ?? 1;
      double lesson = ((profile?['lesson_in_level'] as num?) ?? 0.0).toDouble();
      final String studySystem = (profile?['study_system'] as String?) ?? 'classes';

      if (studySystem == 'hours') {
        lesson += deductedAmount;
      } else {
        lesson += 1.0;
      }

      if (lesson >= AppConstants.lessonsPerLevel) {
        level += 1;
        lesson = 0.0;
      }

      await _client.from('profiles').update({
        'level': level,
        'lesson_in_level': lesson,
      }).eq('id', studentId);
    }

    // Deduct from student balance
    final shouldDeduct = (status == 'present' || status == 'late') || (status == 'absent' && deductForAbsence);
    if (shouldDeduct) {
      final profile = await _client
          .from('profiles')
          .select('study_balance, total_in_level, lesson_in_level')
          .eq('id', studentId)
          .maybeSingle();
      if (profile != null) {
        final double total = ((profile['total_in_level'] as num?) ?? 20.0).toDouble();
        final double lesson = ((profile['lesson_in_level'] as num?) ?? 0.0).toDouble();
        double currentBalance = ((profile['study_balance'] as num?) ?? 0.0).toDouble();
        if (currentBalance == 0.0 && total > lesson) {
          currentBalance = total - lesson;
        }
        final double newBalance = (currentBalance - deductedAmount).clamp(0.0, 99999.0);
        await _client.from('profiles').update({
          'study_balance': newBalance,
        }).eq('id', studentId);
      }
    }

    // Auto-create a homework entry so it appears on the student's homework page
    if (homework != null && homework.isNotEmpty) {
      await _client.from('homeworks').insert({
        'student_id': studentId,
        'teacher_id': teacherId,
        'assignment_text': homework,
        'status': 'pending',
      });
    }
  }

  /// Returns level progress for [studentId].
  ///
  /// If the teacher has manually set level/lesson on the profile, those values
  /// are used directly. Otherwise falls back to attendance-based calculation.
  Future<Map<String, num>> getStudentLevelData(String studentId) async {
    // ── Read manual level from profile ───────────────────────────
    final profile = await _client
        .from('profiles')
        .select('level, lesson_in_level')
        .eq('id', studentId)
        .maybeSingle();

    final int manualLevel = (profile?['level'] as int?) ?? 1;
    final double manualLesson = ((profile?['lesson_in_level'] as num?) ?? 0.0).toDouble();

    // Count attended sessions for total_attended display
    final sessions = await _client
        .from('sessions')
        .select()
        .eq('student_id', studentId)
        .or('status.eq.present,status.eq.late');
    final int attended = sessions.length;

    return {
      'total_attended': attended,
      'level': manualLevel,
      'progress_in_level': manualLesson,
      'sessions_to_next_level': (AppConstants.lessonsPerLevel - manualLesson)
          .clamp(0.0, AppConstants.lessonsPerLevel.toDouble()),
    };
  }
}
