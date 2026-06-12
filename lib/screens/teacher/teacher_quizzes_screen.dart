import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/router/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/profile_model.dart';
import '../../models/quiz_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/profile_service.dart';
import '../../services/quiz_service.dart';

/// Lists all quizzes created by the teacher; allows creation, deletion, and assignment.
class TeacherQuizzesScreen extends StatefulWidget {
  const TeacherQuizzesScreen({super.key});

  @override
  State<TeacherQuizzesScreen> createState() => _TeacherQuizzesScreenState();
}

class _TeacherQuizzesScreenState extends State<TeacherQuizzesScreen> {
  final _service = QuizService();
  List<QuizModel> _quizzes = [];
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
    final list = await _service.fetchTeacherQuizzes(uid);
    if (mounted) {
      setState(() {
        _quizzes = list;
        _loading = false;
      });
    }
  }

  Future<void> _createQuiz() async {
    final uid = context.read<AuthProvider>().profile?.id;
    if (uid == null) return;

    await context.push(AppRoutes.createQuiz, extra: {'teacherId': uid});
    _load();
  }

  Future<void> _delete(QuizModel quiz, AppLocalizations l10n) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title:   Text(l10n.deleteQuizTitle),
        content: Text(l10n.deleteQuizConfirmation(quiz.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style:    TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await _service.deleteQuiz(quiz.id);
    _load();
  }

  Future<void> _assignQuizToStudents(QuizModel quiz) async {
    final l10n = AppLocalizations.of(context);
    final profileService = ProfileService();

    // Show loading spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    List<ProfileModel> students = [];
    try {
      students = await profileService.fetchStudents();
      if (mounted) Navigator.pop(context); // pop loading
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.failedToLoadData}: $e'), backgroundColor: AppColors.error),
        );
        return;
      }
    }

    if (students.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noStudentsRegistered), backgroundColor: AppColors.error),
        );
      }
      return;
    }

    if (!mounted) return;
    // Show multi-select student dialog
    final selectedStudents = await showDialog<List<ProfileModel>>(
      context: context,
      builder: (ctx) => _StudentMultiSelectDialog(students: students),
    );

    if (!mounted) return;
    if (selectedStudents != null && selectedStudents.isNotEmpty) {
      final uid = context.read<AuthProvider>().profile?.id;
      if (uid == null) return;

      // Show saving spinner
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );

      try {
        final studentIds = selectedStudents.map((s) => s.id).toList();
        await _service.assignQuizToMultipleStudents(
          quizId: quiz.id,
          studentIds: studentIds,
          teacherId: uid,
          totalPoints: quiz.totalPoints,
        );
        if (mounted) {
          Navigator.pop(context); // pop saving
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.assignmentSuccess), backgroundColor: AppColors.success),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // pop saving
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.profileSaveError}: $e'), backgroundColor: AppColors.error),
          );
        }
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
        title: Text(
          l10n.quizBankTitle,
          style: const TextStyle(color: AppColors.surface, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:        _createQuiz,
        backgroundColor:  AppColors.primary,
        foregroundColor:  AppColors.surface,
        icon:  const Icon(Icons.add_rounded),
        label: Text(l10n.newQuizButton, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _quizzes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.quiz_outlined,
                          size: 72,
                          color: AppColors.textSecondary.withValues(alpha: 0.35)),
                      const SizedBox(height: 12),
                      Text(
                        l10n.noQuizzesYet,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.clickPlusToCreateQuiz,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color:     AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.medium, AppSpacing.medium,
                        AppSpacing.medium, 100),
                    itemCount:        _quizzes.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.small),
                    itemBuilder: (ctx, i) {
                      final q = _quizzes[i];
                      return _QuizCard(
                        quiz:     q,
                        onEdit:   () async {
                          await context.push(AppRoutes.editQuiz, extra: q);
                          _load();
                        },
                        onDelete: () => _delete(q, l10n),
                        onAssign: () => _assignQuizToStudents(q),
                      );
                    },
                  ),
                ),
    );
  }
}

// ── Quiz card ──────────────────────────────────────────────────────────────────

class _QuizCard extends StatelessWidget {
  final QuizModel     quiz;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onAssign;

  const _QuizCard({required this.quiz, this.onEdit, this.onDelete, this.onAssign});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
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
              color:        AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.quiz_outlined,
                color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quiz.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize:   15,
                    color:      AppColors.textPrimary,
                  ),
                ),
                if (quiz.description != null && quiz.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    quiz.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    _Chip(
                      icon:  Icons.help_outline_rounded,
                      label: l10n.questionsCount(quiz.questions.length),
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    _Chip(
                      icon:  Icons.star_outline_rounded,
                      label: l10n.pointsLabel(quiz.totalPoints),
                      color: AppColors.secondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon:    const Icon(Icons.assignment_ind_outlined, color: AppColors.primary),
            onPressed: onAssign,
            tooltip: l10n.assignButton,
          ),
          IconButton(
            icon:    const Icon(Icons.edit_outlined, color: AppColors.primary),
            onPressed: onEdit,
            tooltip: l10n.edit,
          ),
          IconButton(
            icon:    const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: onDelete,
            tooltip: l10n.delete,
          ),
        ],
      ),
    ),  // Container
    );  // InkWell
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final Color    color;

  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StudentMultiSelectDialog extends StatefulWidget {
  final List<ProfileModel> students;
  const _StudentMultiSelectDialog({required this.students});

  @override
  State<_StudentMultiSelectDialog> createState() => _StudentMultiSelectDialogState();
}

class _StudentMultiSelectDialogState extends State<_StudentMultiSelectDialog> {
  final List<ProfileModel> _selected = [];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.assignToStudentsTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.students.length,
          itemBuilder: (ctx, idx) {
            final s = widget.students[idx];
            final isSel = _selected.contains(s);
            return CheckboxListTile(
              value: isSel,
              activeColor: AppColors.primary,
              title: Text(s.fullName),
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _selected.add(s);
                  } else {
                    _selected.remove(s);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _selected.isEmpty ? null : () => Navigator.pop(context, _selected),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.surface,
          ),
          child: Text(l10n.assign),
        ),
      ],
    );
  }
}
