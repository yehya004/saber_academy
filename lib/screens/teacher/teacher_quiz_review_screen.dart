import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/quiz_assignment_model.dart';
import '../../models/quiz_attempt_model.dart';
import '../../models/quiz_question_model.dart';

/// Teacher reviews a student's submitted quiz attempt.
/// Receives extra: QuizAssignmentModel
class TeacherQuizReviewScreen extends StatelessWidget {
  final QuizAssignmentModel assignment;
  const TeacherQuizReviewScreen({super.key, required this.assignment});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final quiz     = assignment.quiz;
    final questions = quiz?.questions ?? [];
    final attempts  = assignment.attempts;

    int earned = assignment.earnedPoints ?? 0;
    int total  = assignment.totalPoints;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.surface),
        title: Text(
          quiz?.title ?? l10n.quizReview,
          style: const TextStyle(
              color: AppColors.surface, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.medium),
        children: [
          // ── Score summary ────────────────────────────────────────
          _ScoreSummary(earned: earned, total: total),
          const SizedBox(height: AppSpacing.medium),

          // ── Question review list ─────────────────────────────────
          ...questions.asMap().entries.map((e) {
            final idx     = e.key;
            final q       = e.value;
            final attempt = attempts.firstWhereOrNull((a) => a.questionId == q.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.small),
              child:   _QuestionReviewCard(
                index:   idx + 1,
                question: q,
                attempt:  attempt,
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Score summary ──────────────────────────────────────────────────────────────

class _ScoreSummary extends StatelessWidget {
  final int earned;
  final int total;
  const _ScoreSummary({required this.earned, required this.total});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pct = total > 0 ? (earned / total).clamp(0.0, 1.0) : 0.0;
    final color = pct >= 0.7
        ? AppColors.success
        : pct >= 0.4
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        AppColors.primary,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        children: [
          Text(
            l10n.totalScoreLabel,
            style: const TextStyle(
                color:      AppColors.surface,
                fontSize:   14,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            '$earned / $total',
            style: const TextStyle(
                color:      AppColors.surface,
                fontSize:   36,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value:            pct,
              minHeight:        10,
              backgroundColor:  Colors.white.withValues(alpha: 0.25),
              valueColor:       AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(pct * 100).round()}%',
            style: TextStyle(
                color:      color,
                fontWeight: FontWeight.bold,
                fontSize:   14),
          ),
        ],
      ),
    );
  }
}

// ── Per-question review card ────────────────────────────────────────────────────

class _QuestionReviewCard extends StatelessWidget {
  final int                  index;
  final QuizQuestionModel    question;
  final QuizAttemptModel?    attempt;

  const _QuestionReviewCard({
    required this.index,
    required this.question,
    required this.attempt,
  });

  String _optionText(int idx) {
    if (idx >= 0 && idx < question.options.length) {
      return question.options[idx].text;
    }
    return '—';
  }

  String _correctText(AppLocalizations l10n) {
    if (question.questionType == 'fill_blank') {
      return question.correctAnswer ?? '—';
    }
    final separator = l10n.localeName == 'ar' ? '، ' : ', ';
    final correct = question.options
        .asMap()
        .entries
        .where((e) => e.value.isCorrect)
        .map((e) => e.value.text)
        .join(separator);
    return correct.isEmpty ? '—' : correct;
  }

  String _studentAnswerText(AppLocalizations l10n) {
    if (attempt == null) return l10n.unansweredLabel;
    if (question.questionType == 'fill_blank') {
      return attempt!.studentAnswer ?? l10n.unansweredLabel;
    }
    final separator = l10n.localeName == 'ar' ? '، ' : ', ';
    if (question.questionType == 'multiple_choice') {
      if (attempt!.selectedOptions.isEmpty) return l10n.unansweredLabel;
      return attempt!.selectedOptions.map((i) => _optionText(i)).join(separator);
    }
    final idx = int.tryParse(attempt!.studentAnswer ?? '');
    if (idx == null) return l10n.unansweredLabel;
    return _optionText(idx);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isCorrect  = attempt?.isCorrect;
    final unanswered = attempt == null;

    final borderColor = unanswered
        ? AppColors.textSecondary.withValues(alpha: 0.2)
        : isCorrect == true
            ? AppColors.success.withValues(alpha: 0.5)
            : AppColors.error.withValues(alpha: 0.5);

    final bgColor = unanswered
        ? AppColors.surface
        : isCorrect == true
            ? AppColors.success.withValues(alpha: 0.05)
            : AppColors.error.withValues(alpha: 0.05);

    final icon = unanswered
        ? Icons.remove_circle_outline
        : isCorrect == true
            ? Icons.check_circle_outline
            : Icons.cancel_outlined;

    final iconColor = unanswered
        ? AppColors.textSecondary
        : isCorrect == true
            ? AppColors.success
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color:        bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border:       Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (question.passageText != null && question.passageText!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: Text(
                question.passageText!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
          ],
          // Question header
          Row(
            children: [
              Text('$index.',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      fontSize:   13)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  question.questionText,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize:   14,
                      color:      AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: iconColor, size: 22),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Colors.black12),
          const SizedBox(height: 10),

          // Student answer
          _AnswerRow(
            label:      l10n.studentAnswerReview,
            value:      _studentAnswerText(l10n),
            labelColor: AppColors.textSecondary,
            valueColor: unanswered
                ? AppColors.textSecondary
                : isCorrect == true
                    ? AppColors.success
                    : AppColors.error,
          ),
          const SizedBox(height: 6),

          // Correct answer
          _AnswerRow(
            label:      l10n.correctAnswerReview,
            value:      _correctText(l10n),
            labelColor: AppColors.textSecondary,
            valueColor: AppColors.success,
          ),

          // Points
          if (attempt != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.quizPoints(attempt!.pointsEarned ?? 0, question.points),
                style: TextStyle(
                  fontSize:   12,
                  fontWeight: FontWeight.w600,
                  color:      isCorrect == true
                      ? AppColors.success
                      : AppColors.error,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  final String label;
  final String value;
  final Color  labelColor;
  final Color  valueColor;

  const _AnswerRow({
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text('$label:',
              style: TextStyle(
                  fontSize: 12,
                  color:    labelColor,
                  fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize:   13,
                  color:      valueColor,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// Extension utility
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
