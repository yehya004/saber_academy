class QuizOptionModel {
  final String text;
  final bool isCorrect;

  const QuizOptionModel({required this.text, required this.isCorrect});

  factory QuizOptionModel.fromMap(Map<String, dynamic> m) => QuizOptionModel(
        text:      m['text']       as String? ?? '',
        isCorrect: m['is_correct'] as bool?   ?? false,
      );

  Map<String, dynamic> toMap() => {'text': text, 'is_correct': isCorrect};

  QuizOptionModel copyWith({String? text, bool? isCorrect}) => QuizOptionModel(
        text:      text      ?? this.text,
        isCorrect: isCorrect ?? this.isCorrect,
      );
}
