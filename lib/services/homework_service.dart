import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/homework_model.dart';

class HomeworkService {
  final _client = Supabase.instance.client;

  // ── Fetch ────────────────────────────────────────────────────────────────

  Future<List<HomeworkModel>> fetchStudentHomeworks(String studentId) async {
    final data = await _client
        .from('homeworks')
        .select('*, homework_files(*)')
        .eq('student_id', studentId)
        .order('created_at', ascending: false);

    return data.map((e) => HomeworkModel.fromMap(e)).toList();
  }

  Future<List<HomeworkModel>> fetchAllHomeworks() async {
    final data = await _client
        .from('homeworks')
        .select('*, homework_files(*)')
        .order('created_at', ascending: false);

    return data.map((e) => HomeworkModel.fromMap(e)).toList();
  }

  // ── Assign ───────────────────────────────────────────────────────────────

  /// Teacher assigns new homework to a student.
  Future<void> assignHomework({
    required String studentId,
    required String teacherId,
    required String assignmentText,
  }) =>
      _client.from('homeworks').insert({
        'student_id':      studentId,
        'teacher_id':      teacherId,
        'assignment_text': assignmentText,
        'status':          'pending',
      });

  // ── Student file actions ─────────────────────────────────────────────────

  /// Upload a file for a homework submission.
  /// Inserts into homework_files and marks homework as 'submitted'.
  Future<void> addFile({
    required String homeworkId,
    required String telegramFileId,
    required String fileName,
  }) async {
    await _client.from('homework_files').insert({
      'homework_id':      homeworkId,
      'telegram_file_id': telegramFileId,
      'file_name':        fileName,
    });
    await _client
        .from('homeworks')
        .update({'status': 'submitted'})
        .eq('id', homeworkId);
  }

  /// Delete one file. If no files remain, resets homework status to 'pending'.
  Future<void> deleteFile({
    required String fileId,
    required String homeworkId,
  }) async {
    await _client.from('homework_files').delete().eq('id', fileId);

    final remaining = await _client
        .from('homework_files')
        .select('id')
        .eq('homework_id', homeworkId);

    if ((remaining as List).isEmpty) {
      await _client
          .from('homeworks')
          .update({'status': 'pending'})
          .eq('id', homeworkId);
    }
  }

  /// Delete all files and reset homework to 'pending' (student resubmits from scratch).
  Future<void> resetSubmission(String homeworkId) async {
    await _client.from('homework_files').delete().eq('homework_id', homeworkId);
    await _client.from('homeworks').update({
      'status':           'pending',
      'correction_notes': null,
    }).eq('id', homeworkId);
  }

  // ── Teacher correction actions ───────────────────────────────────────────

  /// Mark homework corrected with optional written notes.
  Future<void> markCorrected({
    required String homeworkId,
    String? correctionNotes,
    String? teacherCorrectionUrl,
  }) =>
      _client.from('homeworks').update({
        'status': 'corrected',
        if (correctionNotes      != null) 'correction_notes':      correctionNotes,
        if (teacherCorrectionUrl != null) 'teacher_correction_url': teacherCorrectionUrl,
      }).eq('id', homeworkId);

  /// Update correction notes on an already-corrected homework.
  Future<void> editCorrection({
    required String homeworkId,
    required String correctionNotes,
  }) =>
      _client.from('homeworks').update({
        'correction_notes': correctionNotes,
      }).eq('id', homeworkId);

  /// Remove correction and revert homework to 'submitted'.
  Future<void> deleteCorrection(String homeworkId) =>
      _client.from('homeworks').update({
        'correction_notes': null,
        'status':           'submitted',
      }).eq('id', homeworkId);
}
