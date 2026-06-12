import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/router/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/homework_file_model.dart';
import '../../models/homework_model.dart';
import '../../models/quiz_assignment_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/homework_service.dart';
import '../../services/quiz_service.dart';
import '../../services/telegram_storage_service.dart';
import '../../widgets/homework_card.dart';
import '../../widgets/image_view_dialog.dart';

class StudentHomeworkScreen extends StatefulWidget {
  const StudentHomeworkScreen({super.key});

  @override
  State<StudentHomeworkScreen> createState() => _StudentHomeworkScreenState();
}

class _StudentHomeworkScreenState extends State<StudentHomeworkScreen> {
  final _service      = HomeworkService();
  final _quizService  = QuizService();
  final _telegram     = TelegramStorageService();

  List<HomeworkModel>        _all             = [];
  List<QuizAssignmentModel>  _quizAssignments = [];
  bool                       _loading         = true;
  String?                    _uploading; // homeworkId currently uploading

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final studentId = context.read<AuthProvider>().profile?.id;
    if (studentId == null) return;
    setState(() => _loading = true);
    final results = await Future.wait([
      _service.fetchStudentHomeworks(studentId),
      _quizService.fetchStudentAssignments(studentId),
    ]);
    if (mounted) {
      setState(() {
        _all             = results[0] as List<HomeworkModel>;
        _quizAssignments = results[1] as List<QuizAssignmentModel>;
        _loading         = false;
      });
    }
  }

  int _count(String status) => _all.where((h) => h.status == status).length;

  // ── View a submitted file ──────────────────────────────────────────────

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
      _showError(l10n.failedToLoadFile(e.toString()));
    }
  }

  // ── Add files ──────────────────────────────────────────────────────────

  Future<void> _addFiles(HomeworkModel hw) async {
    final l10n = AppLocalizations.of(context);
    final result = await FilePicker.pickFiles(
      type:          FileType.any,
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return;

    const maxBytes = 5 * 1024 * 1024; // 5 MB per file

    // Validate all files first
    for (final pf in result.files) {
      if (pf.size > maxBytes) {
        _showError(
            l10n.maxFileSizeError(pf.name, '5'));
        return;
      }
      if (pf.path == null) return;
    }

    setState(() => _uploading = hw.id);
    try {
      for (final pf in result.files) {
        final fileId = await _telegram.uploadFile(File(pf.path!));
        await _service.addFile(
          homeworkId:      hw.id,
          telegramFileId:  fileId,
          fileName:        pf.name,
        );
      }
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.files.length == 1
                ? l10n.fileUploadedSuccessfully
                : l10n.filesUploadedSuccessfully(result.files.length)),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      _showError(l10n.failedToUpload(e.toString()));
    } finally {
      if (mounted) setState(() => _uploading = null);
    }
  }

  // ── Delete one file ────────────────────────────────────────────────────

  Future<void> _deleteFile(HomeworkModel hw, HomeworkFileModel file) async {
    final l10n = AppLocalizations.of(context);
    final filePlaceholder = l10n.localeName == 'ar'
        ? 'هذا الملف'
        : l10n.localeName == 'tr'
            ? 'bu dosyayı'
            : 'this file';
    final confirm = await _confirmDialog(
      l10n.deleteFile,
      l10n.confirmDeleteFile(file.fileName.isNotEmpty ? file.fileName : filePlaceholder),
    );
    if (!confirm) return;

    try {
      await _service.deleteFile(fileId: file.id, homeworkId: hw.id);
      await _load();
    } catch (e) {
      _showError(l10n.failedToDelete(e.toString()));
    }
  }

  // ── Reset whole submission ─────────────────────────────────────────────

  Future<void> _resetSubmission(HomeworkModel hw) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await _confirmDialog(
      l10n.resubmit,
      l10n.confirmResubmit,
    );
    if (!confirm) return;

    try {
      await _service.resetSubmission(hw.id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text(l10n.homeworkResetSuccess),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      _showError(l10n.operationFailed(e.toString()));
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  Future<bool> _confirmDialog(String title, String body) async {
    final l10n = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: Text(l10n.confirm),
              ),
            ],
          ),
        ) ??
        false;
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
          l10n.homework,
          style: const TextStyle(
              color: AppColors.surface, fontWeight: FontWeight.bold),
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
                    // ── Summary strip ──────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.medium),
                      child: Row(
                        children: [
                          _SummaryChip(
                            label: l10n.pending,
                            count: _count('pending'),
                            color: AppColors.warning,
                            icon:  Icons.hourglass_empty_rounded,
                          ),
                          const SizedBox(width: AppSpacing.small),
                          _SummaryChip(
                            label: l10n.submitted,
                            count: _count('submitted'),
                            color: const Color(0xFF4A90D9),
                            icon:  Icons.upload_outlined,
                          ),
                          const SizedBox(width: AppSpacing.small),
                          _SummaryChip(
                            label: l10n.corrected,
                            count: _count('corrected'),
                            color: AppColors.success,
                            icon:  Icons.check_circle_outline,
                          ),
                        ],
                      ),
                    ),

                    // ── File / text homework section ───────────────────
                    _SectionHeader(
                      icon:  Icons.assignment_outlined,
                      color: AppColors.warning,
                      title: l10n.fileHomeworks,
                      count: _all.length,
                    ),
                    if (_all.isEmpty)
                      _EmptyRow(text: l10n.noFileHomeworks)
                    else
                      ...List.generate(_all.length, (i) {
                        final hw          = _all[i];
                        final isUploading = _uploading == hw.id;
                        final canModify   = hw.status != 'corrected';
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.medium, 0,
                              AppSpacing.medium, AppSpacing.small),
                          child: HomeworkCard(
                            homework:      hw,
                            actionLoading: isUploading,
                            onViewFile:   (f) => _viewFile(f),
                            onDeleteFile: canModify
                                ? (f) => _deleteFile(hw, f)
                                : null,
                            onAddFiles: canModify && _uploading == null
                                ? () => _addFiles(hw)
                                : null,
                            onSecondaryAction:
                                hw.files.isNotEmpty && canModify
                                    ? () => _resetSubmission(hw)
                                    : null,
                            secondaryActionLabel: l10n.resubmit,
                            secondaryActionIcon:  Icons.refresh_rounded,
                          ),
                        );
                      }),

                    // ── Quiz assignment section ────────────────────────
                    _SectionHeader(
                      icon:  Icons.quiz_outlined,
                      color: AppColors.secondary,
                      title: l10n.assignedQuizzes,
                      count: _quizAssignments.length,
                    ),
                    if (_quizAssignments.isEmpty)
                      _EmptyRow(text: l10n.noAssignedQuizzes)
                    else
                      ...List.generate(_quizAssignments.length, (i) {
                        final qa          = _quizAssignments[i];
                        final isPending   = qa.status == 'pending';
                        final statusColor = isPending
                            ? AppColors.warning
                            : AppColors.success;
                        final statusLabel = isPending ? l10n.pendingStatus : l10n.submittedStatus;
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.medium, 0,
                              AppSpacing.medium, AppSpacing.small),
                          child: InkWell(
                            onTap: isPending
                                ? () => context.push(
                                    AppRoutes.studentTakeQuiz, extra: qa)
                                : () => context.push(
                                    AppRoutes.studentQuizResult, extra: qa),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.cardRadius),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.medium),
                              decoration: BoxDecoration(
                                color:        AppColors.surface,
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.cardRadius),
                                border: Border.all(
                                  color: AppColors.secondary
                                      .withValues(alpha: 0.30),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary
                                          .withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.quiz_outlined,
                                        color: AppColors.secondary,
                                        size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          qa.quiz?.title ?? l10n.quiz,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize:   14,
                                              color: AppColors.textPrimary),
                                        ),
                                        if (qa.quiz?.description != null &&
                                            qa.quiz!.description!.isNotEmpty)
                                          Text(qa.quiz!.description!,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors
                                                      .textSecondary),
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: statusColor
                                                    .withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(statusLabel,
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: statusColor)),
                                            ),
                                            if (!isPending &&
                                                qa.earnedPoints != null) ...[
                                              const SizedBox(width: 8),
                                              Text(
                                                l10n.quizPoints(qa.earnedPoints!, qa.totalPoints),
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors
                                                        .textSecondary),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    isPending
                                        ? Icons.play_circle_outline
                                        : Icons.visibility_outlined,
                                    color: isPending
                                        ? AppColors.secondary
                                        : AppColors.textSecondary,
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
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

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   title;
  final int      count;
  const _SectionHeader(
      {required this.icon,
      required this.color,
      required this.title,
      required this.count});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.medium, AppSpacing.medium, AppSpacing.medium, 8),
        child: Row(
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 6),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize:   15,
                    color:      AppColors.textPrimary)),
            const SizedBox(width: 6),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color:        color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$count',
                    style: TextStyle(
                        fontSize:   11,
                        color:      color,
                        fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      );
}

class _EmptyRow extends StatelessWidget {
  final String text;
  const _EmptyRow({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.medium, 4, AppSpacing.medium, 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary)),
      );
}

// ── Summary chip ───────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final String   label;
  final int      count;
  final Color    color;
  final IconData icon;

  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color:        color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border:       Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14, color: color),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 11, color: color),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

