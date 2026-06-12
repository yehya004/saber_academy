import 'homework_file_model.dart';

/// Mirrors the `homeworks` table in Supabase.
class HomeworkModel {
  final String id;
  final String studentId;
  final String teacherId;
  final String assignmentText;
  final String status; // 'pending' | 'submitted' | 'corrected'
  final String? telegramFileId;       // kept for backward compat with old single-file records
  final String? correctionNotes;      // teacher's feedback text when marking corrected
  final List<HomeworkFileModel> files; // files uploaded via homework_files table
  final String? studentImageUrl;
  final String? teacherCorrectionUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HomeworkModel({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.assignmentText,
    required this.status,
    this.telegramFileId,
    this.correctionNotes,
    this.files = const [],
    this.studentImageUrl,
    this.teacherCorrectionUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HomeworkModel.fromMap(Map<String, dynamic> map) {
    // Safely parse homework_files — guard against malformed data.
    List<HomeworkFileModel> files = const [];
    final rawFiles = map['homework_files'];
    if (rawFiles is List) {
      files = rawFiles
          .whereType<Map<String, dynamic>>()
          .map(HomeworkFileModel.fromMap)
          .toList();
    }

    return HomeworkModel(
      id:                  map['id']                    as String? ?? '',
      studentId:           map['student_id']            as String? ?? '',
      teacherId:           map['teacher_id']            as String? ?? '',
      assignmentText:      map['assignment_text']       as String? ?? '',
      status:              map['status']                as String? ?? 'pending',
      telegramFileId:      map['telegram_file_id']      as String?,
      correctionNotes:     map['correction_notes']      as String?,
      files:               files,
      studentImageUrl:     map['student_image_url']     as String?,
      teacherCorrectionUrl:map['teacher_correction_url']as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id':                     id,
        'student_id':             studentId,
        'teacher_id':             teacherId,
        'assignment_text':        assignmentText,
        'status':                 status,
        if (telegramFileId    != null) 'telegram_file_id':  telegramFileId,
        if (correctionNotes  != null) 'correction_notes':  correctionNotes,
        if (studentImageUrl  != null) 'student_image_url': studentImageUrl,
        if (teacherCorrectionUrl != null) 'teacher_correction_url': teacherCorrectionUrl,
        'created_at':             createdAt.toIso8601String(),
        'updated_at':             updatedAt.toIso8601String(),
      };
}
