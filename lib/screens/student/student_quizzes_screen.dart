import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/router/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/quiz_assignment_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/quiz_service.dart';

/// Student's list of assigned quizzes.
class StudentQuizzesScreen extends StatefulWidget {
  const StudentQuizzesScreen({super.key});

  @override
  State<StudentQuizzesScreen> createState() => _StudentQuizzesScreenState();
}

class _StudentQuizzesScreenState extends State<StudentQuizzesScreen> {
  final _service = QuizService();
  List<QuizAssignmentModel> _assignments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = context.read<AuthProvider>().profile?.id;
    if (uid == null) return;
    setState(() => _loading = true);
    final list = await _service.fetchStudentAssignments(uid);
    if (mounted) setState(() { _assignments = list; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.surface),
        title: Text(
          l10n.quizzes,
          style: const TextStyle(
              color: AppColors.surface, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _assignments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.quiz_outlined,
                          size: 72,
                          color: AppColors.textSecondary
                              .withValues(alpha: 0.35)),
                      const SizedBox(height: 12),
                      Text(
                        l10n.noAssignedQuizzes,
                        style: const TextStyle(
                            color:    AppColors.textSecondary,
                            fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color:     AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.medium),
                    itemCount:        _assignments.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.small),
                    itemBuilder: (ctx, i) {
                      final a = _assignments[i];
                      return _StudentAssignmentCard(
                        assignment: a,
                        onTap: () {
                          if (a.status == 'submitted') {
                            context.push(AppRoutes.studentQuizResult,
                                extra: a);
                          } else {
                            context.push(AppRoutes.studentTakeQuiz,
                                extra: a);
                          }
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

class _StudentAssignmentCard extends StatelessWidget {
  final QuizAssignmentModel assignment;
  final VoidCallback?        onTap;

  const _StudentAssignmentCard({required this.assignment, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSubmitted = assignment.status == 'submitted';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.medium),
        decoration: BoxDecoration(
          color:        AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset:     const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: isSubmitted
                    ? AppColors.success.withValues(alpha: 0.12)
                    : AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isSubmitted
                    ? Icons.check_circle_outline
                    : Icons.play_circle_outline_rounded,
                color: isSubmitted ? AppColors.success : AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assignment.quiz?.title ?? l10n.quiz,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize:   15,
                        color:      AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Status chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSubmitted
                              ? AppColors.success.withValues(alpha: 0.12)
                              : AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isSubmitted ? l10n.submittedStatus : l10n.pendingStatus,
                          style: TextStyle(
                              fontSize:   11,
                              fontWeight: FontWeight.w600,
                              color: isSubmitted
                                  ? AppColors.success
                                  : AppColors.warning),
                        ),
                      ),
                      if (isSubmitted &&
                          assignment.earnedPoints != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          l10n.quizPoints(assignment.earnedPoints!, assignment.totalPoints),
                          style: const TextStyle(
                              fontSize:   12,
                              fontWeight: FontWeight.w600,
                              color:      AppColors.primary),
                        ),
                      ],
                      if (!isSubmitted) ...[
                        const SizedBox(width: 8),
                        Text(
                          l10n.questionsCount(assignment.quiz?.questions.length ?? 0),
                          style: const TextStyle(
                              fontSize: 11,
                              color:    AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              isSubmitted
                  ? Icons.bar_chart_rounded
                  : Icons.arrow_forward_ios_rounded,
              size:  16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
