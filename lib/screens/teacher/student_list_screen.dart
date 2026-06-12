import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/router/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/profile_service.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final _profileService = ProfileService();
  List<ProfileModel> _students  = [];
  List<ProfileModel> _filtered  = [];
  bool               _loading   = true;
  final _searchCtrl = TextEditingController();

  Future<void> _openLevelEditor(BuildContext ctx, ProfileModel student) async {
    final updated = await showDialog<bool>(
      context: ctx,
      builder: (_) => _EditLevelDialog(student: student),
    );
    if (updated == true) _load();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _profileService.fetchStudents();
    if (mounted) {
      setState(() {
        _students = list;
        _filtered = list;
        _loading  = false;
      });
    }
  }

  void _onSearch(String q) {
    setState(() {
      _filtered = _students
          .where((s) => s.fullName.toLowerCase().contains(q.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n      = AppLocalizations.of(context);
    final authProvider = context.watch<AuthProvider>();
    final teacherId = authProvider.profile?.id ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.surface),
        title: Text(
          l10n.students,
          style: const TextStyle(color: AppColors.surface, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GestureDetector(
              onTap: () => context.push(AppRoutes.settings).then((_) => _load()),
              child: Center(
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.surface.withValues(alpha: 0.2),
                  backgroundImage: authProvider.profile?.avatarUrl != null
                      ? NetworkImage(authProvider.profile!.avatarUrl!)
                      : null,
                  child: authProvider.profile?.avatarUrl == null
                      ? const Icon(Icons.person, size: 18, color: AppColors.surface)
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: TextField(
              controller: _searchCtrl,
              onChanged:  _onSearch,
              decoration: InputDecoration(
                hintText:   l10n.searchForStudent,
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                filled:     true,
                fillColor:  AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ── List ────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _filtered.isEmpty
                    ? Center(
                        child: Text(
                          l10n.noStudentsRegistered,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color:     AppColors.primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.medium,
                          ),
                          itemCount:   _filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.small),
                          itemBuilder: (ctx, i) {
                            final s = _filtered[i];
                            return _StudentCard(
                              student:   s,
                              teacherId: teacherId,
                              onAttendance: () => context.push(
                                AppRoutes.attendance,
                                extra: {
                                  'studentId':   s.id,
                                  'studentName': s.fullName,
                                  'teacherId':   teacherId,
                                },
                              ),
                              onHomework: () => context.push(
                                AppRoutes.teacherHomework,
                                extra: {
                                  'studentId':   s.id,
                                  'studentName': s.fullName,
                                  'teacherId':   teacherId,
                                },
                              ),
                              onChat: () => context.push(
                                AppRoutes.chat,
                                extra: {
                                  'partnerId':   s.id,
                                  'partnerName': s.fullName,
                                },
                              ),
                              onEditLevel: () => _openLevelEditor(context, s),
                              onViewDetail: () => context.push(
                                AppRoutes.studentDetail,
                                extra: s,
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final ProfileModel student;
  final String       teacherId;
  final VoidCallback onAttendance;
  final VoidCallback onHomework;
  final VoidCallback onChat;
  final VoidCallback onEditLevel;
  final VoidCallback onViewDetail;

  const _StudentCard({
    required this.student,
    required this.teacherId,
    required this.onAttendance,
    required this.onHomework,
    required this.onChat,
    required this.onEditLevel,
    required this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final initials = () {
      final words = student.fullName.trim()
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .toList();
      return words.isNotEmpty
          ? words.take(2).map((w) => w[0]).join()
          : '؟';
    }();

    return Material(
      color:        Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: InkWell(
        onTap:        onViewDetail,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Container(
          decoration: BoxDecoration(
            color:        AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            boxShadow: [
              BoxShadow(
                color:      Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset:     const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius:          24,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color:      AppColors.surface,
                      fontWeight: FontWeight.bold,
                      fontSize:   16,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.medium),

                // Name + level badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize:   15,
                          color:      AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color:        AppColors.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l10n.studentLevelAbbr(student.level),
                              style: const TextStyle(
                                fontSize:   11,
                                color:      AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color:        AppColors.secondary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              student.studySystem == 'hours'
                                  ? (Localizations.localeOf(context).languageCode == 'ar'
                                      ? 'س ${student.lessonInLevel}'
                                      : 'H ${student.lessonInLevel}')
                                  : l10n.studentLessonAbbr(student.lessonInLevel.toInt()),
                              style: const TextStyle(
                                fontSize:   11,
                                color:      AppColors.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color:        student.isPaid
                                  ? AppColors.success.withValues(alpha: 0.15)
                                  : AppColors.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              student.isPaid ? l10n.paid : l10n.notPaid,
                              style: TextStyle(
                                fontSize:   11,
                                color:      student.isPaid ? AppColors.success : AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (student.isBlocked) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color:        AppColors.error.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
                              ),
                              child: Text(
                                l10n.statusBlocked,
                                style: const TextStyle(
                                  fontSize:   11,
                                  color:      AppColors.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Action icons
                _ActionIcon(
                  icon:    Icons.edit_outlined,
                  color:   AppColors.primary,
                  tooltip: l10n.editLevelAndLesson,
                  onTap:   onEditLevel,
                ),
                _ActionIcon(
                  icon:    Icons.check_circle_outline,
                  color:   AppColors.success,
                  tooltip: l10n.attendanceTooltip,
                  onTap:   onAttendance,
                ),
                _ActionIcon(
                  icon:    Icons.assignment_outlined,
                  color:   AppColors.warning,
                  tooltip: l10n.homeworkTooltip,
                  onTap:   onHomework,
                ),
                _ActionIcon(
                  icon:    Icons.chat_bubble_outline,
                  color:   const Color(0xFF9B59B6),
                  tooltip: l10n.chatTooltip,
                  onTap:   onChat,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Edit Level Dialog ────────────────────────────────────────────────────────

class _EditLevelDialog extends StatefulWidget {
  const _EditLevelDialog({required this.student});
  final ProfileModel student;

  @override
  State<_EditLevelDialog> createState() => _EditLevelDialogState();
}

class _EditLevelDialogState extends State<_EditLevelDialog> {
  late int    _level;
  late double _lesson;
  late double _total;
  late bool   _isPaid;
  late bool   _isBlocked;
  bool        _saving = false;

  @override
  void initState() {
    super.initState();
    _level  = widget.student.level;
    _lesson = widget.student.lessonInLevel;
    _total  = widget.student.totalInLevel;
    _isPaid = widget.student.isPaid;
    _isBlocked = widget.student.isBlocked;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ProfileService().updateStudentLevel(
        studentId:     widget.student.id,
        level:         _level,
        lessonInLevel: _lesson,
        totalInLevel:  _total,
        isPaid:        _isPaid,
        isBlocked:     _isBlocked,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text(e.toString()),
            backgroundColor: AppColors.error,
            behavior:        SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      shape:    RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      title: Row(
        children: [
          const Icon(Icons.edit_outlined, color: AppColors.primary, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${l10n.editLevelAndPaymentTitle} – ${widget.student.fullName}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // ── Level picker ──────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.level,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                IconButton(
                  onPressed: _level > 1
                      ? () => setState(() => _level--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppColors.primary,
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    '$_level',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize:   18,
                      fontWeight: FontWeight.bold,
                      color:      AppColors.primary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _level++),
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppColors.primary,
                ),
              ],
            ),
            const Divider(),
            // ── Lesson picker or hours text field ─────────────────────────
            if (widget.student.studySystem == 'hours') ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: TextFormField(
                  initialValue: '$_lesson',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: Localizations.localeOf(context).languageCode == 'ar'
                        ? 'عدد الساعات المكتملة في المستوى'
                        : 'Completed Hours in Level',
                    prefixIcon: const Icon(Icons.menu_book_outlined, color: AppColors.secondary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (val) {
                    final parsed = double.tryParse(val);
                    if (parsed != null) {
                      _lesson = parsed;
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: TextFormField(
                  initialValue: '$_total',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: Localizations.localeOf(context).languageCode == 'ar'
                        ? 'إجمالي ساعات المستوى'
                        : 'Total Hours in Level',
                    prefixIcon: const Icon(Icons.alarm_on_outlined, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (val) {
                    final parsed = double.tryParse(val);
                    if (parsed != null) {
                      _total = parsed;
                    }
                  },
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: TextFormField(
                  initialValue: '${_lesson.toInt()}',
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: Localizations.localeOf(context).languageCode == 'ar'
                        ? 'عدد الحصص المكتملة في المستوى'
                        : 'Completed Classes in Level',
                    prefixIcon: const Icon(Icons.menu_book_outlined, color: AppColors.secondary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (val) {
                    final parsed = double.tryParse(val);
                    if (parsed != null) {
                      _lesson = parsed;
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: TextFormField(
                  initialValue: '${_total.toInt()}',
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: Localizations.localeOf(context).languageCode == 'ar'
                        ? 'إجمالي حصص المستوى'
                        : 'Total Classes in Level',
                    prefixIcon: const Icon(Icons.class_outlined, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (val) {
                    final parsed = double.tryParse(val);
                    if (parsed != null) {
                      _total = parsed;
                    }
                  },
                ),
              ),
            ],
            const Divider(),
            // ── Payment switch ─────────────────────────
            SwitchListTile(
              title: Text(
                l10n.paymentStatus,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text(
                _isPaid
                    ? l10n.paid
                    : l10n.notPaid,
                style: TextStyle(
                  color: _isPaid ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              value: _isPaid,
              activeThumbColor: AppColors.primary,
              onChanged: (v) => setState(() => _isPaid = v),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            // ── Block switch ─────────────────────────
            SwitchListTile(
              title: Text(
                l10n.accountBlocked,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text(
                _isBlocked ? l10n.manuallyBlocked : l10n.activeCanEnter,
                style: TextStyle(
                  color: _isBlocked ? AppColors.error : AppColors.success,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              value: _isBlocked,
              activeThumbColor: AppColors.error,
              onChanged: (v) => setState(() => _isBlocked = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel, style: const TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _saving
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(color: AppColors.surface, strokeWidth: 2),
                )
              : Text(l10n.saveChanges, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   tooltip;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}
