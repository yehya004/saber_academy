import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/quiz_assignment_model.dart';
import '../../models/quiz_attempt_model.dart';
import '../../models/quiz_question_model.dart';

/// Student sees per-question correct/wrong breakdown after submitting.
/// Receives extra: QuizAssignmentModel (already refreshed with attempts)
class StudentQuizResultScreen extends StatelessWidget {
  final QuizAssignmentModel assignment;
  const StudentQuizResultScreen({super.key, required this.assignment});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final quiz      = assignment.quiz;
    final questions = quiz?.questions ?? [];
    final attempts  = assignment.attempts;
    final earned    = assignment.earnedPoints ?? 0;
    final total     = assignment.totalPoints;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme:       const IconThemeData(color: AppColors.surface),
        title: Text(
          quiz?.title ?? l10n.quizResultTitle,
          style: const TextStyle(
              color:      AppColors.surface,
              fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.medium),
        children: [
          // ── Score banner ─────────────────────────────────────────
          _ScoreBanner(earned: earned, total: total),
          const SizedBox(height: AppSpacing.medium),

          // ── Per-question result ───────────────────────────────────
          ...questions.asMap().entries.map((e) {
            final idx     = e.key;
            final q       = e.value;
            final attempt = attempts.firstWhereOrNull(
                (a) => a.questionId == q.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.small),
              child:   _ResultCard(
                index:    idx + 1,
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

// ── Score banner ──────────────────────────────────────────────────────────────

class _ScoreBanner extends StatelessWidget {
  final int earned;
  final int total;
  const _ScoreBanner({required this.earned, required this.total});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pct = total > 0 ? (earned / total).clamp(0.0, 1.0) : 0.0;
    final barColor = pct >= 0.7
        ? AppColors.success
        : pct >= 0.4
            ? AppColors.warning
            : AppColors.error;
    final msg = pct >= 0.85
        ? l10n.scoreBannerMsgExcellent
        : pct >= 0.7
            ? l10n.scoreBannerMsgVeryGood
            : pct >= 0.5
                ? l10n.scoreBannerMsgGood
                : l10n.scoreBannerMsgNeedsReview;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        children: [
          Text(
            msg,
            style: const TextStyle(
                color:      AppColors.surface,
                fontSize:   16,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '$earned / $total',
            style: const TextStyle(
                color:      AppColors.surface,
                fontSize:   42,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.localeName == 'ar' ? 'نقطة' : l10n.localeName == 'tr' ? 'Puan' : 'Points',
            style: TextStyle(
                color: AppColors.surface.withValues(alpha: 0.8),
                fontSize: 14),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value:           pct,
              minHeight:       12,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor:      AlwaysStoppedAnimation(barColor),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(pct * 100).round()}%',
            style: TextStyle(
                color:      barColor,
                fontWeight: FontWeight.bold,
                fontSize:   15),
          ),
        ],
      ),
    );
  }
}

// ── Per-question result card ───────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final int               index;
  final QuizQuestionModel question;
  final QuizAttemptModel? attempt;

  const _ResultCard({
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

  String _correctAnswer(AppLocalizations l10n) {
    if (question.questionType == 'fill_blank') {
      return question.correctAnswer ?? '—';
    }
    final separator = l10n.localeName == 'ar' ? '، ' : ', ';
    return question.options
        .where((o) => o.isCorrect)
        .map((o) => o.text)
        .join(separator);
  }

  String _studentAnswer(AppLocalizations l10n) {
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
    final unanswered = attempt == null;
    final isCorrect  = attempt?.isCorrect;

    final headerBg = unanswered
        ? AppColors.textSecondary.withValues(alpha: 0.07)
        : isCorrect == true
            ? AppColors.success.withValues(alpha: 0.07)
            : AppColors.error.withValues(alpha: 0.07);

    final borderColor = unanswered
        ? AppColors.textSecondary.withValues(alpha: 0.2)
        : isCorrect == true
            ? AppColors.success.withValues(alpha: 0.4)
            : AppColors.error.withValues(alpha: 0.4);

    final iconData = unanswered
        ? Icons.remove_circle_outline
        : isCorrect == true
            ? Icons.check_circle_rounded
            : Icons.cancel_rounded;

    final iconColor = unanswered
        ? AppColors.textSecondary
        : isCorrect == true
            ? AppColors.success
            : AppColors.error;

    return Container(
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border:       Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color:        headerBg,
              borderRadius: const BorderRadius.only(
                topLeft:  Radius.circular(AppSpacing.cardRadius),
                topRight: Radius.circular(AppSpacing.cardRadius),
              ),
            ),
            child: Row(
              children: [
                Text('$index.',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color:      AppColors.textSecondary,
                        fontSize:   13)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    question.questionText,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize:   14,
                        color:      AppColors.textPrimary),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(iconData, color: iconColor, size: 22),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student answer
                _Row(
                  label:      l10n.studentAnswerLabel,
                  value:      _studentAnswer(l10n),
                  valueColor: unanswered
                      ? AppColors.textSecondary
                      : isCorrect == true
                          ? AppColors.success
                          : AppColors.error,
                ),
                const SizedBox(height: 6),
                // Correct answer
                _Row(
                  label:      l10n.correctAnswerLabel,
                  value:      _correctAnswer(l10n),
                  valueColor: AppColors.success,
                ),
                if (attempt != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.quizPoints(attempt!.pointsEarned ?? 0, question.points),
                      style: TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.bold,
                        color:      isCorrect == true
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color  valueColor;

  const _Row({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text('$label:',
              style: const TextStyle(
                  fontSize:   12,
                  color:      AppColors.textSecondary,
                  fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize:   13,
                  color:      valueColor,
                  fontWeight: FontWeight.w600),
              textDirection: TextDirection.rtl),
        ),
      ],
    );
  }
}

// Extension
extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
