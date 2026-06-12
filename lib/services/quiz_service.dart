import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/quiz_assignment_model.dart';
import '../models/quiz_model.dart';
import '../models/quiz_question_model.dart';

/// Carries a student's answer for a single question.
class QuestionAnswer {
  /// For true_false / single_choice: option index as string ("0", "1", …).
  /// For fill_blank: the student's typed text.
  final String? textAnswer;

  /// For multiple_choice: indices of selected options.
  final List<int> selected;

  final int? timeTakenSeconds;

  const QuestionAnswer({
    this.textAnswer,
    this.selected = const [],
    this.timeTakenSeconds,
  });
}

class QuizService {
  final _client = Supabase.instance.client;

  // ── Quiz CRUD ──────────────────────────────────────────────────────────────

  /// Creates a new quiz template. Returns the new quiz's id.
  Future<String> createQuiz({
    required String teacherId,
    required String title,
    String? description,
  }) async {
    final res = await _client
        .from('quizzes')
        .insert({
          'teacher_id':  teacherId,
          'title':       title,
          if (description != null && description.isNotEmpty)
            'description': description,
        })
        .select('id')
        .single();
    return res['id'] as String;
  }

  Future<void> deleteQuiz(String id) =>
      _client.from('quizzes').delete().eq('id', id);

  /// Updates title/description of an existing quiz.
  Future<void> updateQuiz({
    required String id,
    required String title,
    String? description,
  }) =>
      _client.from('quizzes').update({
        'title':       title,
        'description': description ?? '',
        'updated_at':  DateTime.now().toIso8601String(),
      }).eq('id', id);

  /// Deletes all questions for a quiz (used before re-inserting on edit).
  Future<void> deleteAllQuestions(String quizId) =>
      _client.from('quiz_questions').delete().eq('quiz_id', quizId);

  /// Fetches all quizzes created by [teacherId], including their questions.
  Future<List<QuizModel>> fetchTeacherQuizzes(String teacherId) async {
    final data = await _client
        .from('quizzes')
        .select('*, quiz_questions(*)')
        .eq('teacher_id', teacherId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => QuizModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // ── Questions ──────────────────────────────────────────────────────────────

  /// Bulk-inserts questions for a newly created quiz.
  Future<void> insertQuestions(
      String quizId, List<QuizQuestionModel> questions) async {
    if (questions.isEmpty) return;
    await _client.from('quiz_questions').insert(
          questions
              .map((q) => {...q.toInsertMap(), 'quiz_id': quizId})
              .toList(),
        );
  }

  // ── Assignments ────────────────────────────────────────────────────────────

  /// Assigns [quizId] to [studentId]. Throws if already assigned.
  Future<void> assignQuiz({
    required String quizId,
    required String studentId,
    required String teacherId,
    required int    totalPoints,
  }) =>
      _client.from('quiz_assignments').upsert(
        {
          'quiz_id':      quizId,
          'student_id':   studentId,
          'teacher_id':   teacherId,
          'total_points': totalPoints,
          'status':       'pending',
        },
        onConflict: 'quiz_id,student_id',
        ignoreDuplicates: true,
      );

  /// Assigns [quizId] to multiple students at once.
  Future<void> assignQuizToMultipleStudents({
    required String quizId,
    required List<String> studentIds,
    required String teacherId,
    required int    totalPoints,
  }) async {
    if (studentIds.isEmpty) return;
    final rows = studentIds.map((sid) => {
      'quiz_id':      quizId,
      'student_id':   sid,
      'teacher_id':   teacherId,
      'total_points': totalPoints,
      'status':       'pending',
    }).toList();
    await _client.from('quiz_assignments').upsert(
      rows,
      onConflict: 'quiz_id,student_id',
      ignoreDuplicates: true,
    );
  }

  /// All quiz assignments for a student (with quiz + questions + attempts).
  /// Falls back to a direct quiz_questions query when quizzes table is blocked.
  Future<List<QuizAssignmentModel>> fetchStudentAssignments(
      String studentId) async {
    final data = await _client
        .from('quiz_assignments')
        .select('*, quizzes(*, quiz_questions(*)), quiz_attempts(*)')
        .eq('student_id', studentId)
        .order('assigned_at', ascending: false);
    var models = (data as List)
        .map((e) => QuizAssignmentModel.fromMap(e as Map<String, dynamic>))
        .toList();

    // Collect quiz_ids where questions are missing (RLS blocking quizzes table).
    final missing = models
        .where((m) => m.quiz == null || m.quiz!.questions.isEmpty)
        .map((m) => m.quizId)
        .toSet()
        .toList();

    if (missing.isNotEmpty) {
      final qRows = await _client
          .from('quiz_questions')
          .select('*')
          .inFilter('quiz_id', missing)
          .order('order_index');
      final byQuiz = <String, List<QuizQuestionModel>>{};
      for (final row in qRows as List) {
        final q = QuizQuestionModel.fromMap(row as Map<String, dynamic>);
        byQuiz.putIfAbsent(q.quizId, () => []).add(q);
      }
      models = models.map((m) {
        final qs = byQuiz[m.quizId];
        if (qs == null || qs.isEmpty) return m;
        final quiz = QuizModel(
          id:          m.quizId,
          teacherId:   m.teacherId,
          title:       m.quiz?.title ?? '',
          description: m.quiz?.description,
          questions:   qs,
          createdAt:   m.quiz?.createdAt ?? m.assignedAt,
        );
        return QuizAssignmentModel(
          id:           m.id,
          quizId:       m.quizId,
          studentId:    m.studentId,
          teacherId:    m.teacherId,
          status:       m.status,
          totalPoints:  m.totalPoints,
          earnedPoints: m.earnedPoints,
          assignedAt:   m.assignedAt,
          submittedAt:  m.submittedAt,
          quiz:         quiz,
          attempts:     m.attempts,
        );
      }).toList();
    }
    return models;
  }

  /// All quiz assignments teacher gave to a specific student.
  Future<List<QuizAssignmentModel>> fetchTeacherStudentAssignments({
    required String teacherId,
    required String studentId,
  }) async {
    final data = await _client
        .from('quiz_assignments')
        .select('*, quizzes(*, quiz_questions(*)), quiz_attempts(*)')
        .eq('teacher_id', teacherId)
        .eq('student_id', studentId)
        .order('assigned_at', ascending: false);
    return (data as List)
        .map((e) => QuizAssignmentModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches a single assignment with all related data.
  /// Falls back to a direct quiz_questions query when the student cannot
  /// read the quizzes table (i.e. migration 015 not yet applied).
  Future<QuizAssignmentModel> fetchAssignment(String assignmentId) async {
    final data = await _client
        .from('quiz_assignments')
        .select('*, quizzes(*, quiz_questions(*)), quiz_attempts(*)')
        .eq('id', assignmentId)
        .single();
    var model = QuizAssignmentModel.fromMap(data);

    // If quiz or its questions are missing (student blocked from quizzes table
    // by RLS), fall back to a direct query on quiz_questions which the student
    // CAN read via student_select_quiz_questions policy.
    if (model.quiz == null || model.quiz!.questions.isEmpty) {
      final qRows = await _client
          .from('quiz_questions')
          .select('*')
          .eq('quiz_id', model.quizId)
          .order('order_index');
      final questions = (qRows as List)
          .map((e) => QuizQuestionModel.fromMap(e as Map<String, dynamic>))
          .toList();
      if (questions.isNotEmpty) {
        final quiz = QuizModel(
          id:          model.quizId,
          teacherId:   model.teacherId,
          title:       model.quiz?.title ?? '',
          description: model.quiz?.description,
          questions:   questions,
          createdAt:   model.quiz?.createdAt ?? model.assignedAt,
        );
        model = QuizAssignmentModel(
          id:           model.id,
          quizId:       model.quizId,
          studentId:    model.studentId,
          teacherId:    model.teacherId,
          status:       model.status,
          totalPoints:  model.totalPoints,
          earnedPoints: model.earnedPoints,
          assignedAt:   model.assignedAt,
          submittedAt:  model.submittedAt,
          quiz:         quiz,
          attempts:     model.attempts,
        );
      }
    }
    return model;
  }

  // ── Submit / grade ─────────────────────────────────────────────────────────

  /// Auto-grades the quiz and persists all attempts.
  /// Returns the total points earned.
  Future<int> submitAttempt({
    required String                       assignmentId,
    required List<QuizQuestionModel>      questions,
    required Map<String, QuestionAnswer>  answers,
  }) async {
    int earnedPoints = 0;
    final List<Map<String, dynamic>> rows = [];

    for (final q in questions) {
      final a = answers[q.id];
      bool? isCorrect;
      int   ptEarned = 0;
      String?   studentAnswer;
      List<int>? selectedOptions;

      if (a != null) {
        switch (q.questionType) {
          case 'true_false':
          case 'single_choice':
            studentAnswer = a.textAnswer;
            if (studentAnswer != null) {
              final idx = int.tryParse(studentAnswer);
              if (idx != null && idx >= 0 && idx < q.options.length) {
                isCorrect = q.options[idx].isCorrect;
                ptEarned  = isCorrect ? q.points : 0;
              }
            }
          case 'multiple_choice':
            selectedOptions = a.selected;
            final correctSet = q.options
                .asMap()
                .entries
                .where((e) => e.value.isCorrect)
                .map((e) => e.key)
                .toSet();
            final studentSet = selectedOptions.toSet();
            isCorrect = studentSet.length == correctSet.length &&
                studentSet.every(correctSet.contains);
            ptEarned = isCorrect ? q.points : 0;
          case 'fill_blank':
            studentAnswer = a.textAnswer;
            if (studentAnswer != null && q.correctAnswer != null) {
              isCorrect = studentAnswer.trim().toLowerCase() ==
                  q.correctAnswer!.trim().toLowerCase();
              ptEarned = isCorrect ? q.points : 0;
            }
        }
      }

      earnedPoints += ptEarned;

      rows.add({
        'assignment_id':    assignmentId,
        'question_id':      q.id,
        if (studentAnswer   != null) 'student_answer':   studentAnswer,
        if (selectedOptions != null) 'selected_options': selectedOptions,
        'is_correct':       isCorrect,
        'points_earned':    ptEarned,
        if (a?.timeTakenSeconds != null) 'time_taken_seconds': a!.timeTakenSeconds,
      });
    }

    if (rows.isNotEmpty) {
      await _client.from('quiz_attempts').upsert(rows);
    }

    await _client.from('quiz_assignments').update({
      'status':        'submitted',
      'earned_points': earnedPoints,
      'submitted_at':  DateTime.now().toIso8601String(),
    }).eq('id', assignmentId);

    return earnedPoints;
  }
}
