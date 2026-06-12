import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_spacing.dart';
import '../core/constants/app_text_styles.dart';
import '../models/homework_file_model.dart';
import '../models/homework_model.dart';
import 'status_badge.dart';

class HomeworkCard extends StatelessWidget {
  final HomeworkModel homework;
  final VoidCallback? onTap;

  // Per-file interactions
  final Function(HomeworkFileModel)? onViewFile;    // view a specific file
  final Function(HomeworkFileModel)? onDeleteFile;  // delete (student only, null hides button)

  // File upload
  final VoidCallback? onAddFiles;     // pick & upload files
  final bool          actionLoading;  // shows spinner while uploading

  // Primary action (e.g. "تصحيح الواجب")
  final VoidCallback? onAction;
  final String?       actionLabel;

  // Secondary action (e.g. "تعديل التصحيح" / "إعادة التسليم")
  final VoidCallback? onSecondaryAction;
  final String?       secondaryActionLabel;
  final IconData      secondaryActionIcon;

  // Tertiary action (e.g. "حذف التصحيح")
  final VoidCallback? onTertiaryAction;
  final String?       tertiaryActionLabel;

  const HomeworkCard({
    super.key,
    required this.homework,
    this.onTap,
    this.onViewFile,
    this.onDeleteFile,
    this.onAddFiles,
    this.actionLoading = false,
    this.onAction,
    this.actionLabel,
    this.onSecondaryAction,
    this.secondaryActionLabel,
    this.secondaryActionIcon = Icons.edit_outlined,
    this.onTertiaryAction,
    this.tertiaryActionLabel,
  });

  @override
  Widget build(BuildContext context) {
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
              offset:     const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header: text + badge ──────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(homework.assignmentText, style: AppTextStyles.bodyText),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('yyyy-MM-dd').format(homework.createdAt.toLocal()),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                if (homework.files.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.attach_file_rounded,
                      size:  16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                StatusBadge(status: homework.status),
              ],
            ),

            // ── Correction notes ──────────────────────────────
            if (homework.correctionNotes != null &&
                homework.correctionNotes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.small),
              Container(
                width:   double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:        const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFD54F), width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.rate_review_outlined,
                        size: 16, color: Color(0xFFE65100)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ملاحظات الأستاذ:',
                            style: TextStyle(
                              fontSize:   11,
                              fontWeight: FontWeight.bold,
                              color:      Color(0xFFE65100),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            homework.correctionNotes!,
                            style: const TextStyle(
                              fontSize: 13,
                              color:    AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Uploaded files list ───────────────────────────
            if (homework.files.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 4),
              ...homework.files.map(
                (f) => _FileTile(
                  file:     f,
                  onView:   onViewFile   != null ? () => onViewFile!(f)   : null,
                  onDelete: onDeleteFile != null ? () => onDeleteFile!(f) : null,
                ),
              ),
            ],

            // ── Upload button ─────────────────────────────────
            if (onAddFiles != null || actionLoading) ...[
              const SizedBox(height: AppSpacing.small),
              SizedBox(
                width:  double.infinity,
                height: 38,
                child: actionLoading
                    ? const Center(
                        child: SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color:       AppColors.primary,
                          ),
                        ),
                      )
                    : OutlinedButton.icon(
                        onPressed: onAddFiles,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon:  const Icon(Icons.upload_file_outlined, size: 16),
                        label: Text(
                          homework.files.isEmpty
                              ? 'رفع الواجب'
                              : 'إضافة ملفات أخرى',
                          style: const TextStyle(
                            fontSize:   13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            ],

            // ── Primary action button ─────────────────────────
            if (onAction != null) ...[
              const SizedBox(height: AppSpacing.small),
              SizedBox(
                width:  double.infinity,
                height: 38,
                child: ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    actionLabel ?? '',
                    style: const TextStyle(
                      fontSize:   13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],

            // ── Secondary + Tertiary action row ──────────────
            if (onSecondaryAction != null || onTertiaryAction != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  if (onSecondaryAction != null)
                    Expanded(
                      child: TextButton.icon(
                        onPressed: onSecondaryAction,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                        ),
                        icon:  Icon(secondaryActionIcon, size: 15),
                        label: Text(
                          secondaryActionLabel ?? '',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  if (onSecondaryAction != null && onTertiaryAction != null)
                    const SizedBox(width: 4),
                  if (onTertiaryAction != null)
                    Expanded(
                      child: TextButton.icon(
                        onPressed: onTertiaryAction,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        icon:  const Icon(Icons.delete_outline, size: 15),
                        label: Text(
                          tertiaryActionLabel ?? '',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ],

          ],
        ),
      ),
    );
  }
}

// ── File tile ──────────────────────────────────────────────────────────────────

class _FileTile extends StatelessWidget {
  final HomeworkFileModel file;
  final VoidCallback? onView;
  final VoidCallback? onDelete;

  const _FileTile({
    required this.file,
    this.onView,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(_iconForFile(file.fileName),
              size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              file.fileName.isEmpty ? 'ملف مرفق' : file.fileName,
              style: const TextStyle(
                fontSize: 13,
                color:    AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onView != null)
            IconButton(
              icon:         const Icon(Icons.visibility_outlined,
                                size: 18, color: Color(0xFF4A90D9)),
              onPressed:    onView,
              padding:      EdgeInsets.zero,
              constraints:  const BoxConstraints(minWidth: 32, minHeight: 32),
              visualDensity: VisualDensity.compact,
              tooltip:      'عرض',
            ),
          if (onDelete != null)
            IconButton(
              icon:         const Icon(Icons.delete_outline,
                                size: 18, color: AppColors.error),
              onPressed:    onDelete,
              padding:      EdgeInsets.zero,
              constraints:  const BoxConstraints(minWidth: 32, minHeight: 32),
              visualDensity: VisualDensity.compact,
              tooltip:      'حذف',
            ),
        ],
      ),
    );
  }

  IconData _iconForFile(String name) {
    final ext = name.split('.').last.toLowerCase();
    if ({'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'}.contains(ext)) {
      return Icons.image_outlined;
    }
    if (ext == 'pdf') return Icons.picture_as_pdf_outlined;
    if ({'doc', 'docx'}.contains(ext)) return Icons.description_outlined;
    if ({'xls', 'xlsx'}.contains(ext)) return Icons.table_chart_outlined;
    return Icons.attach_file_rounded;
  }
}
