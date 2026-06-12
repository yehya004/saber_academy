import 'quiz_question_model.dart';

class QuizModel {
  final String  id;
  final String  teacherId;
  final String  title;
  final String? description;
  final List<QuizQuestionModel> questions;
  final DateTime createdAt;

  const QuizModel({
    required this.id,
    required this.teacherId,
    required this.title,
    this.description,
    this.questions = const [],
    required this.createdAt,
  });

  int get totalPoints => questions.fold(0, (s, q) => s + q.points);

  factory QuizModel.fromMap(Map<String, dynamic> m) {
    final rawQ = m['quiz_questions'] as List<dynamic>? ?? [];
    final questions = rawQ
        .map((e) => QuizQuestionModel.fromMap(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return QuizModel(
      id:          m['id']          as String,
      teacherId:   m['teacher_id']  as String,
      title:       m['title']       as String,
      description: m['description'] as String?,
      questions:   questions,
      createdAt:   DateTime.parse(m['created_at'] as String),
    );
  }
}
