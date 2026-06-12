import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/router/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/homework_model.dart';
import '../../models/profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/homework_service.dart';
import '../../services/profile_service.dart';

/// Shows every submitted homework (status = 'submitted') for all of this
/// teacher's students in one place — the "homework inbox".
class TeacherInboxScreen extends StatefulWidget {
  const TeacherInboxScreen({super.key});

  @override
  State<TeacherInboxScreen> createState() => _TeacherInboxScreenState();
}

class _TeacherInboxScreenState extends State<TeacherInboxScreen> {
  final _hwService      = HomeworkService();
  final _profileService = ProfileService();

  /// Submitted homeworks grouped by studentId
  List<_InboxItem> _items   = [];
  bool             _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final auth      = context.read<AuthProvider>();
    final teacherId = auth.profile?.id ?? '';

    final results = await Future.wait([
      _hwService.fetchAllHomeworks(),
      _profileService.fetchStudents(),
    ]);

    final allHw       = results[0] as List<HomeworkModel>;
    final students    = results[1] as List<ProfileModel>;
    final studentMap  = {for (final s in students) s.id: s};

    final submitted = allHw
        .where((h) => h.teacherId == teacherId && h.status == 'submitted')
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (!mounted) return;
    setState(() {
      _items = submitted
          .map((h) => _InboxItem(
                homework: h,
                student:  studentMap[h.studentId],
              ))
          .toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth      = context.watch<AuthProvider>();
    final teacherId = auth.profile?.id ?? '';
    final l10n      = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        title: Row(
          children: [
            Text(l10n.homeworkInboxTitle,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.surface)),
            const SizedBox(width: 8),
            if (!_loading && _items.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color:        AppColors.error,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_items.length}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _items.isEmpty
              ? _buildEmpty(l10n)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (ctx, i) => _InboxCard(
                      item:      _items[i],
                      teacherId: teacherId,
                      onTap: () async {
                        final student = _items[i].student;
                        if (student == null) return;
                        await context.push(
                          AppRoutes.teacherHomework,
                          extra: {
                            'studentId':   student.id,
                            'studentName': student.fullName,
                            'teacherId':   teacherId,
                          },
                        );
                        _load();
                      },
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmpty(AppLocalizations l10n) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 72,
                color: AppColors.success.withValues(alpha: 0.40)),
            const SizedBox(height: 16),
            Text(
              l10n.noHomeworksToCorrect,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.allSubmittedHomeworksCorrected,
              style:
                  const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
}

class _InboxItem {
  final HomeworkModel  homework;
  final ProfileModel?  student;
  const _InboxItem({required this.homework, required this.student});
}

class _InboxCard extends StatelessWidget {
  final _InboxItem   item;
  final String       teacherId;
  final VoidCallback onTap;

  const _InboxCard({
    required this.item,
    required this.teacherId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hw      = item.homework;
    final student = item.student;
    final l10n    = AppLocalizations.of(context);
    final name    = student?.fullName ?? l10n.unknownStudent;

    // Initials
    final words    = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final initials = words.isNotEmpty ? words.take(2).map((w) => w[0]).join() : '؟';

    // Elapsed time
    final diff    = DateTime.now().difference(hw.updatedAt);
    final elapsed = diff.inDays > 0
        ? l10n.daysAgo(diff.inDays)
        : diff.inHours > 0
            ? l10n.hoursAgo(diff.inHours)
            : l10n.minutesAgo(diff.inMinutes);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Material(
        color:        Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: InkWell(
          onTap:        onTap,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              boxShadow: [
                BoxShadow(
                  color:      Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset:     const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius:          22,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color:      AppColors.surface,
                      fontWeight: FontWeight.bold,
                      fontSize:   14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize:   15,
                          color:      AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hw.assignmentText,
                        maxLines:  2,
                        overflow:  TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color:    AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // Files badge
                          if (hw.files.isNotEmpty) ...[
                            Icon(Icons.attach_file,
                                size:  13,
                                color: AppColors.primary.withValues(alpha: 0.70)),
                            const SizedBox(width: 3),
                            Text(
                              l10n.filesCount(hw.files.length),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Icon(Icons.access_time,
                              size:  12,
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.60)),
                          const SizedBox(width: 3),
                          Text(
                            elapsed,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color:        const Color(0xFFE67E22).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l10n.correctHomework,
                    style: const TextStyle(
                      color:      Color(0xFFE67E22),
                      fontSize:   12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
