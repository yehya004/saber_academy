/// Mirrors the `lesson_postponements` table in Supabase.
/// Tracks single-session postponements/reschedules of lessons.
class LessonPostponementModel {
  final String id;
  final String studentId;
  final String teacherId;
  final DateTime originalDateTime; // The original date and time (in UTC)
  final DateTime newDateTime;      // The rescheduled date and time (in UTC)
  final DateTime createdAt;

  const LessonPostponementModel({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.originalDateTime,
    required this.newDateTime,
    required this.createdAt,
  });

  factory LessonPostponementModel.fromMap(Map<String, dynamic> map) =>
      LessonPostponementModel(
        id:                 map['id'] as String,
        studentId:          map['student_id'] as String,
        teacherId:          map['teacher_id'] as String,
        originalDateTime:   DateTime.parse(map['original_date_time'] as String),
        newDateTime:        DateTime.parse(map['new_date_time'] as String),
        createdAt:          DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id':                 id,
        'student_id':         studentId,
        'teacher_id':         teacherId,
        'original_date_time': originalDateTime.toIso8601String(),
        'new_date_time':      newDateTime.toIso8601String(),
        'created_at':         createdAt.toIso8601String(),
      };
}
