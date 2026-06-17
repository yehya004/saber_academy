import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lesson_postponement_model.dart';

class LessonPostponementService {
  final _client = Supabase.instance.client;

  /// Postpones a lesson to a new date and time.
  Future<void> postponeLesson({
    required String studentId,
    required String teacherId,
    required DateTime originalDateTime,
    required DateTime newDateTime,
  }) async {
    await _client.from('lesson_postponements').insert({
      'student_id': studentId,
      'teacher_id': teacherId,
      'original_date_time': originalDateTime.toUtc().toIso8601String(),
      'new_date_time': newDateTime.toUtc().toIso8601String(),
    });
  }

  /// Fetches all postponements for a given student, filtering out and deleting passed reschedules.
  Future<List<LessonPostponementModel>> getPostponementsForStudent(String studentId) async {
    final data = await _client
        .from('lesson_postponements')
        .select()
        .eq('student_id', studentId)
        .order('original_date_time', ascending: false);

    final list = data.map((e) => LessonPostponementModel.fromMap(e)).toList();
    final now = DateTime.now().toUtc();

    // Separate active and passed postponements
    final activeList = list.where((p) => p.newDateTime.isAfter(now)).toList();
    final passedList = list.where((p) => p.newDateTime.isBefore(now)).toList();

    // Asynchronously delete passed reschedules from database
    for (final p in passedList) {
      deletePostponement(p.id).catchError((_) {});
    }

    return activeList;
  }

  /// Deletes a postponement by ID (e.g. after it has passed or if canceled).
  Future<void> deletePostponement(String id) async {
    await _client.from('lesson_postponements').delete().eq('id', id);
  }
}
