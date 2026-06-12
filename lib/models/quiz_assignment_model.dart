import 'quiz_attempt_model.dart';
import 'quiz_model.dart';

class QuizAssignmentModel {
  final String  id;
  final String  quizId;
  final String  studentId;
  final String  teacherId;

  /// 'pending' | 'submitted'
  final String  status;

  final int  totalPoints;
  final int? earnedPoints;

  final DateTime  assignedAt;
  final DateTime? submittedAt;

  /// Populated when fetched with `quizzes(*, quiz_questions(*))`.
  final QuizModel? quiz;

  /// Populated when fetched with `quiz_attempts(*)`.
  final List<QuizAttemptModel> attempts;

  const QuizAssignmentModel({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.teacherId,
    required this.status,
    required this.totalPoints,
    this.earnedPoints,
    required this.assignedAt,
    this.submittedAt,
    this.quiz,
    this.attempts = const [],
  });

  factory QuizAssignmentModel.fromMap(Map<String, dynamic> m) {
    final quizRaw      = m['quizzes'] as Map<String, dynamic>?;
    final attemptsRaw  = m['quiz_attempts'] as List<dynamic>? ?? [];

    return QuizAssignmentModel(
      id:           m['id']           as String,
      quizId:       m['quiz_id']      as String,
      studentId:    m['student_id']   as String,
      teacherId:    m['teacher_id']   as String,
      status:       m['status']       as String? ?? 'pending',
      totalPoints:  m['total_points'] as int?    ?? 0,
      earnedPoints: m['earned_points'] as int?,
      assignedAt:   DateTime.parse(m['assigned_at'] as String),
      submittedAt:  m['submitted_at'] != null
                        ? DateTime.parse(m['submitted_at'] as String)
                        : null,
      quiz: quizRaw != null ? QuizModel.fromMap(quizRaw) : null,
      attempts: attemptsRaw
          .map((e) => QuizAttemptModel.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
