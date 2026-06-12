import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/router/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/homework_file_model.dart';
import '../../models/homework_model.dart';
import '../../models/quiz_assignment_model.dart';
import '../../models/quiz_model.dart';
import '../../services/homework_service.dart';
import '../../services/quiz_service.dart';
import '../../services/telegram_storage_service.dart';
import '../../widgets/homework_card.dart';
import '../../widgets/image_view_dialog.dart';

class TeacherHomeworkScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String teacherId;

  const TeacherHomeworkScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.teacherId,
  });

  @override
  State<TeacherHomeworkScreen> createState() => _TeacherHomeworkScreenState();
}

class _TeacherHomeworkScreenState extends State<TeacherHomeworkScreen> {
  final _service       = HomeworkService();
  final _quizService   = QuizService();
  final _telegram      = TelegramStorageService();
  List<HomeworkModel>        _homeworks       = [];
  List<QuizAssignmentModel>  _quizAssignments = [];
  List<QuizModel>            _teacherQuizzes  = [];
  bool _loading = true;
  final _assignCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _loadTeacherQuizzes();
  }

  Future<void> _loadTeacherQuizzes() async {
    if (widget.teacherId.isEmpty) return;
    final list = await _quizService.fetchTeacherQuizzes(widget.teacherId);
    if (mounted) setState(() => _teacherQuizzes = list);
  }

  @override
  void dispose() {
    _assignCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _service.fetchStudentHomeworks(widget.studentId),
      if (widget.teacherId.isNotEmpty)
        _quizService.fetchTeacherStudentAssignments(
          teacherId: widget.teacherId,
          studentId: widget.studentId,
        )
      else
        Future.value(<QuizAssignmentModel>[]),
    ]);
    if (mounted) {
      setState(() {
        _homeworks       = results[0] as List<HomeworkModel>;
        _quizAssignments = results[1] as List<QuizAssignmentModel>;
        _loading         = false;
      });
    }
  }

  Future<void> _assign() async {
    final text = _assignCtrl.text.trim();
    if (text.isEmpty) return;

    try {
      await _service.assignHomework(
        studentId:      widget.studentId,
        teacherId:      widget.teacherId,
        assignmentText: text,
      );
      _assignCtrl.clear();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text(AppLocalizations.of(context).homeworkAssignedSuccess),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  // ── Assign quiz ───────────────────────────────────────────────────────

  Future<void> _assignQuiz() async {
    final l10n = AppLocalizations.of(context);
    if (_teacherQuizzes.isEmpty) {
      _showError(l10n.noQuizzesInBank);
      return;
    }

    QuizModel? picked;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.quiz_outlined, color: AppColors.secondary),
              const SizedBox(width: 8),
              Text(l10n.assignQuizToStudent),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: DropdownButtonFormField<QuizModel>(
              initialValue: picked,
              isExpanded: true,
              decoration: InputDecoration(
                labelText:  l10n.selectQuiz,
                prefixIcon: const Icon(Icons.quiz_outlined,
                    color: AppColors.secondary),
                filled:    true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:   BorderSide.none,
                ),
              ),
              items: _teacherQuizzes.map((q) {
                final pts = q.questions
                    .fold<int>(0, (s, qq) => s + qq.points);
                return DropdownMenuItem(
                  value: q,
                  child: Text(
                    l10n.quizPointsAndQuestions(q.title, pts, q.questions.length),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                );
              }).toList(),
              onChanged: (q) => setDlg(() => picked = q),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.surface,
              ),
              onPressed: picked == null ? null : () => Navigator.pop(ctx),
              child: Text(l10n.assign),
            ),
          ],
        ),
      ),
    );

    if (picked == null) return;

    try {
      final totalPoints =
          picked!.questions.fold<int>(0, (s, q) => s + q.points);
      await _quizService.assignQuiz(
        quizId:      picked!.id,
        studentId:   widget.studentId,
        teacherId:   widget.teacherId,
        totalPoints: totalPoints,
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.quizAssignedSuccess(picked!.title)),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  // ── Section label helper ──────────────────────────────────────────────

  Widget _sectionLabel(String title, {Widget? trailing}) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.medium, AppSpacing.medium, AppSpacing.medium, 6),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize:   15,
                  color:      AppColors.textPrimary),
            ),
            const Spacer(),
            if (trailing != null) trailing,
          ],
        ),
      );

  // ── View a specific file ───────────────────────────────────────────────

  Future<void> _viewFile(HomeworkFileModel file) async {
    final l10n = AppLocalizations.of(context);
    try {
      final info = await _telegram.getFileInfo(file.telegramFileId);
      if (!mounted) return;
      if (info.isImage) {
        await showDialog(
          context: context,
          builder: (_) => ImageViewDialog(url: info.url, fileName: info.fileName),
        );
      } else {
        final uri = Uri.parse(info.url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          _showError(l10n.failedToOpenFile);
        }
      }
    } catch (e) {
      _showError(l10n.operationFailed(e.toString()));
    }
  }

  // ── Mark corrected ────────────────────────────────────────────────────

  Future<void> _markCorrected(HomeworkModel hw) async {
    final l10n = AppLocalizations.of(context);
    final notesCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.rate_review_outlined, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(l10n.correctHomework),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: notesCtrl,
            maxLines:   5,
            autofocus:  true,
            decoration: InputDecoration(
              hintText:  l10n.correctionNotesHint,
              filled:    true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:   BorderSide.none,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.confirmCorrection),
          ),
        ],
      ),
    );

    final notes = notesCtrl.text.trim();
    notesCtrl.dispose();
    if (confirmed != true) return;

    try {
      await _service.markCorrected(
        homeworkId:      hw.id,
        correctionNotes: notes.isEmpty ? null : notes,
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text(l10n.homeworkCorrectedSuccess),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  // ── Edit correction ───────────────────────────────────────────────────

  Future<void> _editCorrection(HomeworkModel hw) async {
    final l10n = AppLocalizations.of(context);
    final notesCtrl = TextEditingController(text: hw.correctionNotes ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.edit_outlined, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(l10n.editCorrection),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: notesCtrl,
            maxLines:   5,
            autofocus:  true,
            decoration: InputDecoration(
              hintText:  l10n.editNotesHint,
              filled:    true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:   BorderSide.none,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.saveLabel),
          ),
        ],
      ),
    );

    final notes = notesCtrl.text.trim();
    notesCtrl.dispose();
    if (confirmed != true) return;

    try {
      await _service.editCorrection(
        homeworkId:      hw.id,
        correctionNotes: notes,
      );
      await _load();
    } catch (e) {
      _showError(e.toString());
    }
  }

  // ── Delete correction ─────────────────────────────────────────────────

  Future<void> _deleteCorrection(HomeworkModel hw) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteCorrection),
        content: Text(l10n.deleteCorrectionConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _service.deleteCorrection(hw.id);
      await _load();
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
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
              l10n.homework,
              style: const TextStyle(
                color: AppColors.surface, fontWeight: FontWeight.bold, fontSize: 16,
              ),
            ),
            Text(
              widget.studentName,
              style: TextStyle(
                color: AppColors.surface.withValues(alpha: 0.75), fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color:     AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Assign new file homework ─────────────────────
                    Container(
                      margin:  const EdgeInsets.all(AppSpacing.medium),
                      padding: const EdgeInsets.all(AppSpacing.medium),
                      decoration: BoxDecoration(
                        color:        AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:      Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset:     const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.assignment_outlined,
                                  color: AppColors.warning, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                l10n.assignTextOrFileHomework,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize:   15,
                                    color:      AppColors.textPrimary),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.medium),
                          TextField(
                            controller: _assignCtrl,
                            maxLines:   3,
                            decoration: InputDecoration(
                              hintText:  l10n.typeHomeworkTextHint,
                              filled:    true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.cardRadius),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.medium),
                          SizedBox(
                            width:  double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed: _assign,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.cardRadius),
                                ),
                              ),
                              icon:  const Icon(Icons.send_outlined, size: 18),
                              label: Text(l10n.assignHomework),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Assign quiz card ─────────────────────────────
                    Container(
                      margin:  const EdgeInsets.fromLTRB(
                          AppSpacing.medium, 0,
                          AppSpacing.medium, AppSpacing.medium),
                      padding: const EdgeInsets.all(AppSpacing.medium),
                      decoration: BoxDecoration(
                        color:        AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.35)),
                        boxShadow: [
                          BoxShadow(
                            color:      Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset:     const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.quiz_outlined,
                                color: AppColors.secondary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.assignQuizTooltip,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize:   14,
                                        color:      AppColors.textPrimary)),
                                Text(l10n.chooseQuizToAssign,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color:    AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _assignQuiz,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: AppColors.surface,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.cardRadius),
                              ),
                            ),
                            child: Text(l10n.assign,
                                style: const TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    ),

                    // ── File homework section ────────────────────────
                    _sectionLabel(
                      l10n.fileHomeworks,
                      trailing: _homeworks.isNotEmpty
                          ? _TypeBadge(label: '${_homeworks.length}', color: AppColors.warning)
                          : null,
                    ),
                    if (_homeworks.isEmpty)
                      _EmptyHint(icon: Icons.assignment_outlined, text: l10n.noFileHomeworks)
                    else
                      ...List.generate(_homeworks.length, (i) {
                        final hw = _homeworks[i];
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.medium, 0,
                              AppSpacing.medium, AppSpacing.small),
                          child: HomeworkCard(
                            homework: hw,
                            onViewFile: hw.files.isNotEmpty ? (f) => _viewFile(f) : null,
                            onAction: hw.status == 'submitted'
                                ? () => _markCorrected(hw)
                                : null,
                            actionLabel: l10n.markCorrected,
                            onSecondaryAction: hw.status == 'corrected'
                                ? () => _editCorrection(hw)
                                : null,
                            secondaryActionLabel: l10n.editCorrection,
                            onTertiaryAction: hw.status == 'corrected'
                                ? () => _deleteCorrection(hw)
                                : null,
                            tertiaryActionLabel: l10n.deleteCorrection,
                          ),
                        );
                      }),

                    // ── Quiz assignment section ──────────────────────
                    _sectionLabel(
                      l10n.assignedQuizzes,
                      trailing: Row(
                        children: [
                          if (_quizAssignments.isNotEmpty)
                            _TypeBadge(
                                label: '${_quizAssignments.length}',
                                color: AppColors.secondary),
                          const SizedBox(width: 6),
                          TextButton.icon(
                            onPressed: () => context.push(
                              AppRoutes.teacherStudentQuizzes,
                              extra: {
                                'studentId':   widget.studentId,
                                'studentName': widget.studentName,
                                'teacherId':   widget.teacherId,
                              },
                            ),
                            style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                            icon:  const Icon(Icons.quiz_outlined, size: 16),
                            label: Text(l10n.manage, style: const TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                    if (_quizAssignments.isEmpty)
                      _EmptyHint(icon: Icons.quiz_outlined, text: l10n.noAssignedQuizzes)
                    else
                      ...List.generate(_quizAssignments.length, (i) {
                        final qa = _quizAssignments[i];
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.medium, 0,
                              AppSpacing.medium, AppSpacing.small),
                          child: _QuizAssignmentCard(
                            assignment: qa,
                            onTap: qa.status == 'submitted'
                                ? () => context.push(
                                    AppRoutes.teacherQuizReview,
                                    extra: qa)
                                : null,
                          ),
                        );
                      }),

                    const SizedBox(height: AppSpacing.large),
                  ],
                ),
              ),
            ),
    );
  }
}

// ── Quiz assignment card ───────────────────────────────────────────────────────

class _QuizAssignmentCard extends StatelessWidget {
  final QuizAssignmentModel assignment;
  final VoidCallback?       onTap;
  const _QuizAssignmentCard({required this.assignment, this.onTap});

  @override
  Widget build(BuildContext context) {
    final qa      = assignment;
    final isPending   = qa.status == 'pending';
    final l10n    = AppLocalizations.of(context);
    final statusColor = isPending ? AppColors.warning : AppColors.success;
    final statusLabel = isPending ? l10n.pendingStatus : l10n.submittedStatus;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.medium),
        decoration: BoxDecoration(
          color:        AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.30), width: 1),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset:     const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color:        AppColors.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.quiz_outlined,
                  color: AppColors.secondary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    qa.quiz?.title ?? '—',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize:   14,
                        color:      AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _TypeBadge(label: l10n.quiz, color: AppColors.secondary),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:        statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(statusLabel,
                            style: TextStyle(
                                fontSize: 11,
                                color:    statusColor,
                                fontWeight: FontWeight.w600)),
                      ),
                      if (!isPending) ...[
                        const SizedBox(width: 6),
                        Text(
                          l10n.pointsEarnedOutOf(qa.earnedPoints ?? 0, qa.totalPoints),
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
            if (!isPending)
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Shared small widgets ───────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  final String label;
  final Color  color;
  const _TypeBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color:        color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize:   11,
              color:      color,
              fontWeight: FontWeight.w600),
        ),
      );
}

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String   text;
  const _EmptyHint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.medium, 8, AppSpacing.medium, 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(width: 6),
            Text(text,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      );
}
