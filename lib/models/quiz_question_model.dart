import 'quiz_option_model.dart';

class QuizQuestionModel {
  final String id;
  final String quizId;
  final String questionText;

  /// 'true_false' | 'single_choice' | 'multiple_choice' | 'fill_blank'
  final String questionType;

  /// Populated for choice-based types.
  final List<QuizOptionModel> options;

  /// Expected answer for fill_blank (case-insensitive match on submit).
  final String? correctAnswer;

  /// Optional image stored in Telegram.
  final String? telegramFileId;

  /// Optional clue shown on student request.
  final String? hint;

  /// Shared passage/text under which this question is grouped.
  final String? passageText;

  final int points;
  final int? timeSeconds; // per-question countdown timer
  final int orderIndex;

  const QuizQuestionModel({
    required this.id,
    required this.quizId,
    required this.questionText,
    required this.questionType,
    this.options = const [],
    this.correctAnswer,
    this.telegramFileId,
    this.hint,
    this.passageText,
    required this.points,
    this.timeSeconds,
    required this.orderIndex,
  });

  factory QuizQuestionModel.fromMap(Map<String, dynamic> m) {
    // Safely parse options — guard against malformed data from Supabase.
    List<QuizOptionModel> options = const [];
    final rawOptions = m['options'];
    if (rawOptions is List) {
      options = rawOptions
          .whereType<Map<String, dynamic>>()
          .map(QuizOptionModel.fromMap)
          .toList();
    }

    return QuizQuestionModel(
      id: m['id'] as String? ?? '',
      quizId: m['quiz_id'] as String? ?? '',
      questionText: m['question_text'] as String? ?? '',
      questionType: m['question_type'] as String? ?? 'true_false',
      options: options,
      correctAnswer: m['correct_answer'] as String?,
      telegramFileId: m['telegram_file_id'] as String?,
      hint: m['hint'] as String?,
      passageText: m['passage_text'] as String?,
      points: (m['points'] as num?)?.toInt() ?? 1,
      timeSeconds: (m['time_seconds'] as num?)?.toInt(),
      orderIndex: (m['order_index'] as num?)?.toInt() ?? 0,
    );
  }

  /// Converts to a map suitable for inserting into Supabase (no id / quiz_id fields needed here).
  Map<String, dynamic> toInsertMap() => {
        'question_text': questionText,
        'question_type': questionType,
        if (options.isNotEmpty)
          'options': options.map((o) => o.toMap()).toList(),
        if (correctAnswer != null) 'correct_answer': correctAnswer,
        if (telegramFileId != null) 'telegram_file_id': telegramFileId,
        if (hint != null) 'hint': hint,
        if (passageText != null) 'passage_text': passageText,
        'points': points,
        if (timeSeconds != null) 'time_seconds': timeSeconds,
        'order_index': orderIndex,
      };
}
