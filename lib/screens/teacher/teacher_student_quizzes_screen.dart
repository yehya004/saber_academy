import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/router/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/quiz_assignment_model.dart';
import '../../models/quiz_model.dart';
import '../../services/quiz_service.dart';

/// Shows all quiz assignments teacher gave to a specific student.
/// Receives extra: {'studentId': String, 'studentName': String, 'teacherId': String}
class TeacherStudentQuizzesScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String teacherId;

  const TeacherStudentQuizzesScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.teacherId,
  });

  @override
  State<TeacherStudentQuizzesScreen> createState() =>
      _TeacherStudentQuizzesScreenState();
}

class _TeacherStudentQuizzesScreenState
    extends State<TeacherStudentQuizzesScreen> {
  final _service = QuizService();
  List<QuizAssignmentModel> _assignments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _service.fetchTeacherStudentAssignments(
      teacherId: widget.teacherId,
      studentId: widget.studentId,
    );
    if (mounted) {
      setState(() {
        _assignments = list;
        _loading = false;
      });
    }
  }

  Future<void> _assign() async {
    final l10n = AppLocalizations.of(context);
    // Fetch teacher's quiz bank
    final quizzes = await _service.fetchTeacherQuizzes(widget.teacherId);
    if (!mounted) return;

    if (quizzes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:         Text(l10n.noQuizzesInBankShort),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Pick a quiz
    QuizModel? picked;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.chooseQuizToAssign,
          textDirection: TextDirection.rtl,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        content: SizedBox(
          width: 360,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount:        quizzes.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final q = quizzes[i];
              // Disable if already assigned
              final alreadyAssigned = _assignments.any((a) => a.quizId == q.id);
              return ListTile(
                enabled: !alreadyAssigned,
                leading: Icon(
                  Icons.quiz_outlined,
                  color: alreadyAssigned
                      ? AppColors.textSecondary
                      : AppColors.primary,
                ),
                title: Text(q.title,
                    style: TextStyle(
                        color: alreadyAssigned
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize:   13)),
                subtitle: Text(
                  '${l10n.questionsCount(q.questions.length)} · ${l10n.pointsLabel(q.totalPoints)}'
                  '${alreadyAssigned ? ' · ${l10n.quizStatusAssigned}' : ''}',
                  style: const TextStyle(fontSize: 11),
                ),
                onTap: alreadyAssigned
                    ? null
                    : () {
                        picked = q;
                        Navigator.pop(ctx);
                      },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );

    if (picked == null) return;

    try {
      await _service.assignQuiz(
        quizId:      picked!.id,
        studentId:   widget.studentId,
        teacherId:   widget.teacherId,
        totalPoints: picked!.totalPoints,
      );
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text(l10n.operationFailed(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.surface),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.quizzes,
              style: const TextStyle(
                  color:      AppColors.surface,
                  fontWeight: FontWeight.bold,
                  fontSize:   16),
            ),
            Text(
              widget.studentName,
              style: const TextStyle(
                  color:    AppColors.surface,
                  fontSize: 12,
                  fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon:     const Icon(Icons.add_circle_outline,
                color: AppColors.surface),
            onPressed: _assign,
            tooltip:   l10n.assignQuizTooltip,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _assignments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.assignment_outlined,
                          size: 72,
                          color: AppColors.textSecondary
                              .withValues(alpha: 0.35)),
                      const SizedBox(height: 12),
                      Text(
                        l10n.noQuizzesAssigned,
                        style: const TextStyle(
                            color:    AppColors.textSecondary,
                            fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.clickPlusToAssignQuiz,
                        style: const TextStyle(
                            color:    AppColors.textSecondary,
                            fontSize: 13),
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
                      return _AssignmentCard(
                        assignment: a,
                        onTap:      a.status == 'submitted'
                            ? () => context.push(
                                  AppRoutes.teacherQuizReview,
                                  extra: a,
                                 )
                            : null,
                      );
                    },
                  ),
                ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final QuizAssignmentModel assignment;
  final VoidCallback?        onTap;

  const _AssignmentCard({required this.assignment, this.onTap});

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
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isSubmitted
                    ? AppColors.success.withValues(alpha: 0.12)
                    : AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isSubmitted
                    ? Icons.check_circle_outline
                    : Icons.pending_outlined,
                color: isSubmitted ? AppColors.success : AppColors.warning,
                size: 22,
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
                        fontSize:   14,
                        color:      AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
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
                      if (isSubmitted && assignment.earnedPoints != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          l10n.quizPoints(assignment.earnedPoints!, assignment.totalPoints),
                          style: const TextStyle(
                              fontSize:   12,
                              fontWeight: FontWeight.w600,
                              color:      AppColors.primary),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (isSubmitted)
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
