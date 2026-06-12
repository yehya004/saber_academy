class QuizAttemptModel {
  final String  id;
  final String  assignmentId;
  final String  questionId;

  /// Option index as string for choices; raw text for fill_blank.
  final String? studentAnswer;

  /// Selected option indices for multiple_choice.
  final List<int> selectedOptions;

  final bool? isCorrect;
  final int?  pointsEarned;
  final int?  timeTakenSeconds;
  final DateTime? answeredAt;

  const QuizAttemptModel({
    required this.id,
    required this.assignmentId,
    required this.questionId,
    this.studentAnswer,
    this.selectedOptions = const [],
    this.isCorrect,
    this.pointsEarned,
    this.timeTakenSeconds,
    this.answeredAt,
  });

  factory QuizAttemptModel.fromMap(Map<String, dynamic> m) => QuizAttemptModel(
        id:              m['id']              as String,
        assignmentId:    m['assignment_id']   as String,
        questionId:      m['question_id']     as String,
        studentAnswer:   m['student_answer']  as String?,
        selectedOptions: (m['selected_options'] as List<dynamic>? ?? [])
                             .map((e) => (e as num).toInt())
                             .toList(),
        isCorrect:       m['is_correct']      as bool?,
        pointsEarned:    m['points_earned']   as int?,
        timeTakenSeconds: m['time_taken_seconds'] as int?,
        answeredAt: m['answered_at'] != null
            ? DateTime.parse(m['answered_at'] as String)
            : null,
      );
}
