import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/router/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/lesson_schedule_model.dart';
import '../../models/profile_model.dart';
import '../../models/lesson_postponement_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/attendance_service.dart';
import '../../services/lesson_schedule_service.dart';
import '../../services/profile_service.dart';
import '../../services/timezone_service.dart';
import '../../services/lesson_postponement_service.dart';

class StudentDetailScreen extends StatefulWidget {
  const StudentDetailScreen({super.key, required this.student});
  final ProfileModel student;

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  final _profileService    = ProfileService();
  final _attendanceService = AttendanceService();
  final _scheduleService   = LessonScheduleService();
  final _tzService         = TimezoneService();

  late ProfileModel       _student;
  int                     _totalAttended = 0;
  bool                    _loading       = true;
  LessonScheduleModel?    _schedule;
  // Per-day entries localised to teacher's timezone
  List<DayScheduleEntry>  _teacherEntries = [];
  // Per-day entries localised to student's timezone
  List<DayScheduleEntry>  _studentEntries = [];
  // Next lesson label (teacher's local time)
  String?                 _nextLessonLabel;
  List<LessonPostponementModel> _postponements = [];

  @override
  void initState() {
    super.initState();
    _student = widget.student;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _attendanceService.getStudentLevelData(_student.id),
        _scheduleService.getScheduleForStudent(_student.id),
        LessonPostponementService().getPostponementsForStudent(_student.id),
        _profileService.fetchStudentById(_student.id),
      ]);
      final levelData = results[0] as Map<String, num>;
      final schedule  = results[1] as LessonScheduleModel?;
      final postponements = results[2] as List<LessonPostponementModel>;
      final refreshedProfile = results[3] as ProfileModel?;

      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final teacherCountry = context.read<AuthProvider>().profile?.country;
      final teacherTz = _tzService.getTimezone(teacherCountry) ?? 'Africa/Cairo';
      final studentTz = refreshedProfile != null ? _tzService.getTimezone(refreshedProfile.country) : _tzService.getTimezone(_student.country);

      List<DayScheduleEntry> tEntries = [];
      List<DayScheduleEntry> sEntries = [];
      String? nextLabel;

      if (schedule != null && schedule.daySchedules.isNotEmpty) {
        tEntries = await _tzService.entriesToLocal(
          schedule.daySchedules, teacherTz);
        if (studentTz != null) {
          sEntries = await _tzService.entriesToLocal(
            schedule.daySchedules, studentTz);
        }

        if (!mounted) return;

        // Compute next lesson in teacher's local time
        final nextUtc       = _tzService.nextLessonUtcFromEntries(schedule.daySchedules);
        final offsetMin     = _tzService.getUtcOffsetMinutes(teacherTz);
        final nextLocal     = nextUtc.add(Duration(minutes: offsetMin));
        final nowUtc        = DateTime.now().toUtc();
        final diffDays      = nextLocal.difference(nowUtc).inDays;
        final timeStr       = _fmtTime(context, nextLocal.hour, nextLocal.minute);
        if (diffDays == 0) {
          nextLabel = l10n.todayAt(timeStr);
        } else if (diffDays == 1) {
          nextLabel = l10n.tomorrowAt(timeStr);
        } else {
          final dayName = getLocalizedDayName(context, nextLocal.weekday);
          nextLabel = l10n.dayAt(dayName, timeStr);
        }
      }

      if (mounted) {
        setState(() {
          if (refreshedProfile != null) {
            _student = refreshedProfile;
          }
          _totalAttended   = levelData['total_attended']?.toInt() ?? 0;
          _schedule        = schedule;
          _teacherEntries  = tEntries;
          _studentEntries  = sEntries;
          _nextLessonLabel = nextLabel;
          _postponements   = postponements;
          _loading         = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _fmtTime(BuildContext context, int h, int m) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final period = h < 12 ? (isAr ? 'ص' : 'AM') : (isAr ? 'م' : 'PM');
    final h12    = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:${m.toString().padLeft(2, '0')} $period';
  }

  String getLocalizedDayName(BuildContext context, int weekday) {
    final date = DateTime(2026, 1, 5).add(Duration(days: weekday - 1));
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat.EEEE(locale).format(date);
  }

  Future<void> _openSchedule() async {
    final updated = await context.push<bool>(
      AppRoutes.lessonSchedule,
      extra: _student,
    );
    if (updated == true && mounted) _load();
  }

  Future<void> _editLevel() async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => _EditLevelDialog(student: _student),
    );
    if (updated == true && mounted) {
      // Reload the updated profile
      final refreshed = await _profileService.fetchStudentById(_student.id);
      if (refreshed != null && mounted) {
        setState(() => _student = refreshed);
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _student.email;
    final l10n = AppLocalizations.of(context);
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noEmailForStudent),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.lock_reset_outlined, color: AppColors.warning, size: 22),
            const SizedBox(width: 8),
            Text(l10n.resetPassword, style: const TextStyle(fontSize: 15)),
          ],
        ),
        content: Text(
          l10n.resetPasswordEmailInstructions(email),
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(l10n.sendLabel),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.resetPasswordEmailInstructionsSent),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.operationFailed(e.toString())),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _editContact() async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => _EditContactDialog(student: _student),
    );
    if (updated == true && mounted) {
      final refreshed = await _profileService.fetchStudentById(_student.id);
      if (refreshed != null && mounted) {
        setState(() => _student = refreshed);
      }
    }
  }

  Future<void> _deleteStudentDialog() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    
    String title = 'Delete Student';
    String message = 'Are you sure you want to permanently delete this student? All their sessions, homeworks, messages, and progress will be lost forever. This action cannot be undone.';
    String confirmLabel = 'Delete';
    String cancelLabel = 'Cancel';
    
    if (isAr) {
      title = 'حذف الطالب';
      message = 'هل أنت متأكد من حذف هذا الطالب نهائياً؟ سيتم حذف جميع الحصص والواجبات والرسائل والبيانات الخاصة به ولا يمكن التراجع عن هذا الإجراء.';
      confirmLabel = 'حذف';
      cancelLabel = 'إلغاء';
    } else if (isTr) {
      title = 'Öğrenciyi Sil';
      message = 'Bu öğrenciyi kalıcı olarak silmek istediğinizden emin misiniz? Tüm dersleri, ödevleri, mesajları ve ilerlemesi kalıcı olarak kaybolacaktır. Bu işlem geri alınamaz.';
      confirmLabel = 'Sil';
      cancelLabel = 'İptal';
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelLabel, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await _profileService.deleteStudent(_student.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'تم حذف الطالب بنجاح' : isTr ? 'Öğrenci başarıyla silindi' : 'Student deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _postponeLesson() async {
    if (_teacherEntries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Localizations.localeOf(context).languageCode == 'ar'
              ? 'لا يوجد جدول حصص لتأجيله'
              : 'No scheduled lessons to postpone'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final teacherProfile = context.read<AuthProvider>().profile;
    final teacherId = teacherProfile?.id ?? '';
    final teacherCountry = teacherProfile?.country;
    final teacherTz = _tzService.getTimezone(teacherCountry) ?? 'Africa/Cairo';
    DayScheduleEntry? selectedEntry = _teacherEntries.first;
    DateTime? newDateTime;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isAr = Localizations.localeOf(context).languageCode == 'ar';
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                isAr ? 'تأجيل حصة' : 'Postpone Lesson',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<DayScheduleEntry>(
                    initialValue: selectedEntry,
                    decoration: InputDecoration(
                      labelText: isAr ? 'اختر الحصة المراد تأجيلها' : 'Select lesson to postpone',
                    ),
                    items: _teacherEntries.map((e) {
                      return DropdownMenuItem(
                        value: e,
                        child: Text('${getLocalizedDayName(context, e.dayOfWeek)} - ${_fmtTime(context, e.hourUtc, e.minuteUtc)}'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedEntry = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                     onPressed: () async {
                       final date = await showDatePicker(
                         context: context,
                         initialDate: DateTime.now(),
                         firstDate: DateTime.now(),
                         lastDate: DateTime.now().add(const Duration(days: 30)),
                       );
                       if (date == null) return;

                       if (!context.mounted) return;
                       final time = await showTimePicker(
                         context: context,
                         initialTime: TimeOfDay.now(),
                       );
                       if (time == null) return;

                       setDialogState(() {
                         newDateTime = DateTime(
                           date.year,
                           date.month,
                           date.day,
                           time.hour,
                           time.minute,
                         );
                       });
                     },
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(newDateTime == null
                        ? (isAr ? 'اختر موعد الحصة الجديد' : 'Pick new date & time')
                        : DateFormat('yyyy/MM/dd hh:mm a').format(newDateTime!)),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(isAr ? 'إلغاء' : 'Cancel'),
                ),
                ElevatedButton(
                  onPressed: newDateTime == null
                      ? null
                      : () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isAr ? 'حفظ التأجيل' : 'Confirm'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && selectedEntry != null && newDateTime != null) {
      if (!mounted) return;
      final changeType = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final isAr = Localizations.localeOf(context).languageCode == 'ar';
          final isTr = Localizations.localeOf(context).languageCode == 'tr';
          
          String title = 'Change Type';
          String message = 'Is this postponement a one-time exception or a permanent change to the weekly schedule?';
          String exceptionLabel = 'One-time Exception';
          String permanentLabel = 'Permanent Change';
          String cancelLabel = 'Cancel';
          
          if (isAr) {
            title = 'نوع التعديل';
            message = 'هل هذا التأجيل لمرة واحدة فقط كاستثناء، أم تعديل دائم في الجدول الأسبوعي؟';
            exceptionLabel = 'لمرة واحدة فقط (استثناء)';
            permanentLabel = 'تعديل دائم في الجدول';
            cancelLabel = 'إلغاء';
          } else if (isTr) {
            title = 'Erteleme Türü';
            message = 'Bu erteleme tek seferlik bir istisna mı yoksa haftalık programda kalıcı bir değişiklik mi?';
            exceptionLabel = 'Tek Seferlik İstisna';
            permanentLabel = 'Kalıcı Değişiklik';
            cancelLabel = 'İptal';
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop('cancel'),
                child: Text(cancelLabel, style: const TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop('exception'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(exceptionLabel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop('permanent'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(permanentLabel),
              ),
            ],
          );
        },
      );

      if (changeType == 'cancel' || changeType == null) return;

      setState(() => _loading = true);
      try {
        if (changeType == 'exception') {
          final now = DateTime.now();
          var originalDateTime = DateTime(now.year, now.month, now.day, selectedEntry!.hourUtc, selectedEntry!.minuteUtc);
          int daysDiff = selectedEntry!.dayOfWeek - now.weekday;
          if (daysDiff < 0) daysDiff += 7;
          originalDateTime = originalDateTime.add(Duration(days: daysDiff));

          await LessonPostponementService().postponeLesson(
            studentId: _student.id,
            teacherId: teacherId,
            originalDateTime: originalDateTime,
            newDateTime: newDateTime!,
          );
        } else if (changeType == 'permanent') {
          final updatedLocalEntries = List<DayScheduleEntry>.from(_teacherEntries);
          final index = updatedLocalEntries.indexWhere((e) =>
              e.dayOfWeek == selectedEntry!.dayOfWeek &&
              e.hourUtc == selectedEntry!.hourUtc &&
              e.minuteUtc == selectedEntry!.minuteUtc);
          if (index != -1) {
            updatedLocalEntries[index] = DayScheduleEntry(
              dayOfWeek: newDateTime!.weekday,
              hourUtc: newDateTime!.hour,
              minuteUtc: newDateTime!.minute,
            );
          }
          final updatedUtcEntries = await _tzService.entriesToUtc(updatedLocalEntries, teacherTz);

          await _scheduleService.upsertSchedule(
            studentId: _student.id,
            teacherId: teacherId,
            daySchedules: updatedUtcEntries,
            teacherTimezone: teacherTz,
          );
        }
        await _load();
        if (mounted) {
          final isAr = Localizations.localeOf(context).languageCode == 'ar';
          final isTr = Localizations.localeOf(context).languageCode == 'tr';
          String successMsg = 'Lesson rescheduled successfully';
          if (isAr) {
            successMsg = changeType == 'exception' ? 'تم تأجيل الحصة بنجاح' : 'تم تعديل الجدول الأسبوعي بنجاح';
          } else if (isTr) {
            successMsg = changeType == 'exception' ? 'Ders başarıyla ertelendi' : 'Haftalık program başarıyla güncellendi';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMsg),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
          );
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  String get _initials {
    final words = _student.fullName.trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    return words.isNotEmpty ? words.take(2).map((w) => w[0]).join() : '؟';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned:         true,
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: AppColors.surface),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, Color(0xFF1E6B50)],
                    begin:  Alignment.topLeft,
                    end:    Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48),
                    CircleAvatar(
                      radius:          40,
                      backgroundColor: AppColors.surface.withValues(alpha: 0.25),
                      backgroundImage: _student.avatarUrl != null
                          ? NetworkImage(_student.avatarUrl!)
                          : null,
                      child: _student.avatarUrl == null
                          ? Text(
                              _initials,
                              style: const TextStyle(
                                color:      AppColors.surface,
                                fontSize:   28,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _student.fullName,
                      style: const TextStyle(
                        color:      AppColors.surface,
                        fontSize:   20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_student.country != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        getLocalizedCountry(context, _student.country!),
                        style: TextStyle(
                          color:    AppColors.surface.withValues(alpha: 0.80),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            title: Text(
              l10n.studentDetailsTitle,
              style: const TextStyle(color: AppColors.surface, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.surface),
                tooltip: Localizations.localeOf(context).languageCode == 'ar' ? 'حذف الطالب' : 'Delete Student',
                onPressed: _deleteStudentDialog,
              ),
            ],
          ),

          // ── Body ──────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Level & Lesson card ──────────────────────────────
                _InfoCard(
                  title: l10n.academicLevelSection,
                  child: _loading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            Row(
                              children: [
                                _StatBox(
                                  icon:  Icons.signal_cellular_alt,
                                  color: AppColors.primary,
                                  label: l10n.level,
                                  value: '${_student.level}',
                                ),
                                const SizedBox(width: AppSpacing.small),
                                _StatBox(
                                  icon:  Icons.menu_book_outlined,
                                  color: AppColors.secondary,
                                  label: _student.studySystem == 'hours'
                                      ? (Localizations.localeOf(context).languageCode == 'ar'
                                          ? 'الساعات المكتملة'
                                          : Localizations.localeOf(context).languageCode == 'tr'
                                              ? 'Tamamlanan Saatler'
                                              : 'Completed Hours')
                                      : (Localizations.localeOf(context).languageCode == 'ar'
                                          ? 'الحصص المكتملة'
                                          : Localizations.localeOf(context).languageCode == 'tr'
                                              ? 'Tamamlanan Dersler'
                                              : 'Completed Classes'),
                                  value: '${_student.lessonInLevel}',
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.small),
                            Row(
                              children: [
                                _StatBox(
                                  icon:  Icons.check_circle_outline,
                                  color: AppColors.success,
                                  label: l10n.totalAttendanceLabel,
                                  value: '$_totalAttended',
                                ),
                                const SizedBox(width: AppSpacing.small),
                                Builder(
                                  builder: (ctx) {
                                    final isHours = _student.studySystem == 'hours';
                                    final double balance = _student.studyBalance;
                                    String valStr = '';
                                    String lblStr = '';
                                    if (isHours) {
                                      final totalMinutes = (balance * 60).round();
                                      final hrs = totalMinutes ~/ 60;
                                      final mins = totalMinutes % 60;
                                      if (Localizations.localeOf(context).languageCode == 'ar') {
                                        valStr = mins > 0 ? '$hrs س و $mins د' : '$hrs س';
                                        lblStr = 'الرصيد المتبقي';
                                      } else if (Localizations.localeOf(context).languageCode == 'tr') {
                                        valStr = mins > 0 ? '$hrs sa $mins dk' : '$hrs sa';
                                        lblStr = 'Kalan Bakiye';
                                      } else {
                                        valStr = mins > 0 ? '$hrs h $mins m' : '$hrs h';
                                        lblStr = 'Remaining Balance';
                                      }
                                    } else {
                                      valStr = '${balance.toInt()}';
                                      if (Localizations.localeOf(context).languageCode == 'ar') {
                                        lblStr = 'الرصيد المتبقي';
                                      } else if (Localizations.localeOf(context).languageCode == 'tr') {
                                        lblStr = 'Kalan Bakiye';
                                      } else {
                                        lblStr = 'Remaining Balance';
                                      }
                                    }
                                    return _StatBox(
                                      icon:  Icons.account_balance_wallet_outlined,
                                      color: Colors.purple,
                                      label: lblStr,
                                      value: valStr,
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.small),

                            const SizedBox(height: 12),
                            // Payment & Block status box
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Payment row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            _student.isPaid ? Icons.check_circle_outline : Icons.error_outline,
                                            color: _student.isPaid ? AppColors.success : AppColors.warning,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            l10n.courseStatusCurrent,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _student.isPaid
                                              ? AppColors.success.withValues(alpha: 0.10)
                                              : AppColors.error.withValues(alpha: 0.10),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _student.isPaid ? l10n.paid : l10n.notPaid,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _student.isPaid ? AppColors.success : AppColors.error,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8.0),
                                    child: Divider(height: 1, color: AppColors.progressTrack),
                                  ),
                                  // Block row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            _student.isBlocked ? Icons.block : Icons.check_circle_outline,
                                            color: _student.isBlocked ? AppColors.error : AppColors.success,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            l10n.accountStatus,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _student.isBlocked
                                              ? AppColors.error.withValues(alpha: 0.10)
                                              : AppColors.success.withValues(alpha: 0.10),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _student.isBlocked ? l10n.manuallyBlocked : l10n.activeCanEnter,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _student.isBlocked ? AppColors.error : AppColors.success,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Progress bar within level
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      l10n.levelProgress,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color:    AppColors.textSecondary,
                                      ),
                                    ),
                                    Builder(
                                      builder: (ctx) {
                                        final isHours = _student.studySystem == 'hours';
                                        final lessonVal = isHours ? _student.lessonInLevel : _student.lessonInLevel.toInt();
                                        final totalVal = isHours ? _student.totalInLevel : _student.totalInLevel.toInt();
                                        final isAr = Localizations.localeOf(context).languageCode == 'ar';
                                        final isTr = Localizations.localeOf(context).languageCode == 'tr';
                                        
                                        String label = '';
                                        if (isHours) {
                                          if (isAr) {
                                            label = '$lessonVal / $totalVal ساعة';
                                          } else if (isTr) {
                                            label = '$lessonVal / $totalVal saat';
                                          } else {
                                            label = '$lessonVal / $totalVal hours';
                                          }
                                        } else {
                                          if (isAr) {
                                            label = '$lessonVal / $totalVal درس';
                                          } else if (isTr) {
                                            label = '$lessonVal / $totalVal ders';
                                          } else {
                                            label = '$lessonVal / $totalVal lessons';
                                          }
                                        }
                                        return Text(
                                          label,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value:           (_student.lessonInLevel / (_student.totalInLevel > 0 ? _student.totalInLevel : 20.0)).clamp(0.0, 1.0),
                                    minHeight:       10,
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _editLevel,
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                label: Text(l10n.editLevelAndLesson),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.primary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: AppSpacing.medium),

                // ── Lesson schedule card ─────────────────────────────
                _InfoCard(
                  title: l10n.weeklyLessonsSchedule,
                  child: _loading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_schedule == null ||
                                _teacherEntries.isEmpty) ...[
                              Row(
                                children: [
                                  const Icon(Icons.schedule_outlined,
                                      color: AppColors.textSecondary, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.noScheduleSetYet,
                                    style: const TextStyle(
                                      color:    AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              // Next lesson banner
                              if (_nextLessonLabel != null) ...[
                                Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: AppColors.primary.withValues(alpha: 0.25)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.event_outlined,
                                          color: AppColors.primary, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        l10n.nextLessonPrefix,
                                        style: const TextStyle(
                                          color:      AppColors.primary,
                                          fontSize:   13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        _nextLessonLabel!,
                                        style: const TextStyle(
                                          color:    AppColors.primary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              // Per-day schedule table
                              // Match student entries by dayOfWeek (not index)
                              // because a TZ shift can move an entry to a different day.
                              ...List.generate(_teacherEntries.length, (i) {
                                final tE = _teacherEntries[i];
                                final sE = _studentEntries.cast<DayScheduleEntry?>()
                                    .firstWhere(
                                      (e) => e?.dayOfWeek == tE.dayOfWeek,
                                      orElse: () => null,
                                    );
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      _DayChip(
                                        label: getLocalizedDayName(context, tE.dayOfWeek),
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _fmtTime(context, tE.hourUtc, tE.minuteUtc),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:      AppColors.primary,
                                          fontSize:   13,
                                        ),
                                      ),
                                      if (sE != null) ...[
                                        const SizedBox(width: 6),
                                        const Icon(Icons.arrow_forward_ios,
                                            size: 10,
                                            color: AppColors.textSecondary),
                                        const SizedBox(width: 6),
                                        Text(
                                          _fmtTime(context, sE.hourUtc, sE.minuteUtc),
                                          style: const TextStyle(
                                            color:    AppColors.secondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          l10n.roleStudentLabel,
                                          style: const TextStyle(
                                            color:    AppColors.textSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }),
                            ],
                            if (_postponements.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Divider(height: 1, color: AppColors.progressTrack),
                              const SizedBox(height: 12),
                              Text(
                                Localizations.localeOf(context).languageCode == 'ar' ? 'الحصص المؤجلة هذا الشهر:' : 'Postponed lessons this month:',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              ..._postponements.map((p) {
                                final origFmt = DateFormat('EEEE hh:mm a', Localizations.localeOf(context).languageCode);
                                final newFmt = DateFormat('yyyy/MM/dd hh:mm a', Localizations.localeOf(context).languageCode);
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.swap_calls_outlined, color: Colors.orange, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${Localizations.localeOf(context).languageCode == 'ar' ? 'من:' : 'From:'} ${origFmt.format(p.originalDateTime.toLocal())}',
                                              style: const TextStyle(fontSize: 12, decoration: TextDecoration.lineThrough),
                                            ),
                                            Text(
                                              '${Localizations.localeOf(context).languageCode == 'ar' ? 'إلى:' : 'To:'} ${newFmt.format(p.newDateTime.toLocal())}',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                                        onPressed: () async {
                                          setState(() => _loading = true);
                                          await LessonPostponementService().deletePostponement(p.id);
                                          await _load();
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _openSchedule,
                                    icon: Icon(
                                      _schedule == null
                                          ? Icons.add_alarm_outlined
                                          : Icons.edit_calendar_outlined,
                                      size: 16,
                                    ),
                                    label: Text(
                                      _schedule == null
                                          ? l10n.setLessonTime
                                          : l10n.editLessonTime,
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(color: AppColors.primary),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _postponeLesson,
                                    icon: const Icon(Icons.swap_calls_outlined, size: 16),
                                    label: Text(
                                      Localizations.localeOf(context).languageCode == 'ar' ? 'تأجيل حصة' : 'Postpone Lesson',
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.orange,
                                      side: const BorderSide(color: Colors.orange),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: AppSpacing.medium),

                // ── Contact info card ────────────────────────────────
                _InfoCard(
                  title: l10n.contactDetailsSection,
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                    tooltip: l10n.editContactDetailsTooltip,
                    onPressed: _editContact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  child: Column(
                    children: [
                      _DetailRow(
                        icon:  Icons.email_outlined,
                        color: AppColors.primary,
                        label: l10n.email,
                        value: (_student.email != null && _student.email!.isNotEmpty)
                            ? _student.email!
                            : '—',
                        onTap: (_student.email != null && _student.email!.isNotEmpty)
                            ? () => _launch('mailto:${_student.email}')
                            : null,
                      ),
                      const Divider(height: 1, indent: 44, color: AppColors.progressTrack),
                      _DetailRow(
                        icon:  Icons.lock_outline,
                        color: AppColors.warning,
                        label: Localizations.localeOf(context).languageCode == 'ar'
                            ? 'كلمة المرور'
                            : Localizations.localeOf(context).languageCode == 'tr'
                                ? 'Şifre'
                                : 'Password',
                        value: (_student.studentPassword != null && _student.studentPassword!.isNotEmpty)
                            ? _student.studentPassword!
                            : '—',
                        trailing: (_student.studentPassword != null && _student.studentPassword!.isNotEmpty)
                            ? IconButton(
                                icon: const Icon(Icons.copy, size: 16, color: AppColors.textSecondary),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: _student.studentPassword!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(Localizations.localeOf(context).languageCode == 'ar'
                                          ? 'تم نسخ كلمة المرور'
                                          : Localizations.localeOf(context).languageCode == 'tr'
                                              ? 'Şifre kopyalandı'
                                              : 'Password copied'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                },
                              )
                            : null,
                      ),
                      const Divider(height: 1, indent: 44, color: AppColors.progressTrack),
                      _DetailRow(
                        icon:  Icons.chat_outlined,
                        color: const Color(0xFF25D366),
                        label: l10n.whatsappLabel,
                        value: (_student.phone != null && _student.phone!.isNotEmpty)
                            ? _student.phone!
                            : '—',
                        onTap: (_student.phone != null && _student.phone!.isNotEmpty)
                            ? () {
                                final num = _student.phone!.replaceAll(RegExp(r'[^0-9+]'), '');
                                _launch('https://wa.me/$num');
                              }
                            : null,
                      ),
                      const Divider(height: 1, indent: 44, color: AppColors.progressTrack),
                      _DetailRow(
                        icon:  Icons.chat_bubble_outline,
                        color: const Color(0xFF0084FF),
                        label: l10n.messengerLabel,
                        value: (_student.messengerLink != null && _student.messengerLink!.isNotEmpty)
                            ? _student.messengerLink!
                            : '—',
                        onTap: (_student.messengerLink != null && _student.messengerLink!.isNotEmpty)
                            ? () => _launch(_student.messengerLink!)
                            : null,
                      ),
                      const Divider(height: 1, indent: 44, color: AppColors.progressTrack),
                      _DetailRow(
                        icon:  Icons.flag_outlined,
                        color: AppColors.secondary,
                        label: l10n.countryLabel,
                        value: (_student.country != null && _student.country!.isNotEmpty)
                            ? getLocalizedCountry(context, _student.country!)
                            : '—',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.medium),

                // ── Quick actions ────────────────────────────────────
                _InfoCard(
                  title: l10n.quickActionsSection,
                  child: Column(
                    children: [
                      _ActionTile(
                        icon:    Icons.check_circle_outline,
                        color:   AppColors.success,
                        label:   l10n.attendanceLog,
                        onTap: () async {
                          await context.push(
                            AppRoutes.attendance,
                            extra: {
                              'studentId':   _student.id,
                              'studentName': _student.fullName,
                              'teacherId':   context.read<AuthProvider>().profile?.id ?? '',
                            },
                          );
                          if (mounted) _load();
                        },
                      ),
                      const Divider(height: 1, indent: 44, color: AppColors.progressTrack),
                      _ActionTile(
                        icon:    Icons.assignment_outlined,
                        color:   AppColors.warning,
                        label:   l10n.homework,
                        onTap: () async {
                          await context.push(
                            AppRoutes.teacherHomework,
                            extra: {
                              'studentId':   _student.id,
                              'studentName': _student.fullName,
                              'teacherId':   context.read<AuthProvider>().profile?.id ?? '',
                            },
                          );
                          if (mounted) _load();
                        },
                      ),
                      const Divider(height: 1, indent: 44, color: AppColors.progressTrack),
                      _ActionTile(
                        icon:    Icons.quiz_outlined,
                        color:   AppColors.secondary,
                        label:   l10n.quizzes,
                        onTap: () async {
                          await context.push(
                            AppRoutes.teacherStudentQuizzes,
                            extra: {
                              'studentId':   _student.id,
                              'studentName': _student.fullName,
                              'teacherId':   context.read<AuthProvider>().profile?.id ?? '',
                            },
                          );
                          if (mounted) _load();
                        },
                      ),
                      const Divider(height: 1, indent: 44, color: AppColors.progressTrack),
                      _ActionTile(
                        icon:    Icons.chat_bubble_outline,
                        color:   const Color(0xFF9B59B6),
                        label:   l10n.chatLabel,
                        onTap: () => context.push(
                          AppRoutes.chat,
                          extra: {
                            'partnerId':   _student.id,
                            'partnerName': _student.fullName,
                          },
                        ),
                      ),
                      const Divider(height: 1, indent: 44, color: AppColors.progressTrack),
                      _ActionTile(
                        icon:    Icons.lock_reset_outlined,
                        color:   AppColors.warning,
                        label:   l10n.resetPassword,
                        onTap:   _resetPassword,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.large),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Edit Contact Dialog ───────────────────────────────────────────────────────

class _EditContactDialog extends StatefulWidget {
  const _EditContactDialog({required this.student});
  final ProfileModel student;

  @override
  State<_EditContactDialog> createState() => _EditContactDialogState();
}

class _EditContactDialogState extends State<_EditContactDialog> {
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _messengerCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;
  String? _country;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _phoneCtrl     = TextEditingController(text: widget.student.phone ?? '');
    _messengerCtrl = TextEditingController(text: widget.student.messengerLink ?? '');
    _emailCtrl     = TextEditingController(text: widget.student.email ?? '');
    _passwordCtrl  = TextEditingController(text: widget.student.studentPassword ?? '');
    _country       = widget.student.country;
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _messengerCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final oldEmail = widget.student.email?.trim() ?? '';
      final newEmail = _emailCtrl.text.trim();
      final oldPassword = widget.student.studentPassword?.trim() ?? '';
      final newPassword = _passwordCtrl.text.trim();

      if (newEmail != oldEmail || newPassword != oldPassword) {
        await ProfileService().updateStudentCredentials(
          studentId: widget.student.id,
          email: newEmail == oldEmail ? null : newEmail,
          password: newPassword == oldPassword ? null : (newPassword.isEmpty ? null : newPassword),
        );
      }

      await ProfileService().updateStudentContact(
        studentId:    widget.student.id,
        phone:        _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        messengerLink: _messengerCtrl.text.trim().isEmpty ? null : _messengerCtrl.text.trim(),
        country:      _country,
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
      shape:          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding:   const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      title: Row(
        children: [
          const Icon(Icons.contact_phone_outlined, color: AppColors.primary, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.editContactDetailsTooltip,
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
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: l10n.email,
                prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordCtrl,
              decoration: InputDecoration(
                labelText: Localizations.localeOf(context).languageCode == 'ar'
                    ? 'كلمة المرور'
                    : Localizations.localeOf(context).languageCode == 'tr'
                        ? 'Şifre'
                        : 'Password',
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.warning),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l10n.whatsappPhoneLabel,
                prefixIcon: const Icon(Icons.chat_outlined, color: Color(0xFF25D366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messengerCtrl,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: l10n.messengerLinkLabel,
                prefixIcon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF0084FF)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _country,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.countryLabel,
                prefixIcon: const Icon(Icons.flag_outlined, color: AppColors.secondary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              hint: Text(
                l10n.chooseStudentCountry,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              items: _kCountries
                  .map((c) => DropdownMenuItem(value: c, child: Text(getLocalizedCountry(context, c))))
                  .toList(),
              onChanged: (v) => setState(() => _country = v),
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
              : Text(l10n.saveLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// ── Edit Level Dialog ─────────────────────────────────────────────────────────

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
  late double _studyBalance;
  late bool   _isPaid;
  late bool   _isBlocked;
  late String _studySystem;
  bool        _saving = false;

  @override
  void initState() {
    super.initState();
    _level  = widget.student.level;
    _lesson = widget.student.lessonInLevel;
    _total  = widget.student.totalInLevel;
    _studyBalance = widget.student.studyBalance;
    _isPaid = widget.student.isPaid;
    _isBlocked = widget.student.isBlocked;
    _studySystem = widget.student.studySystem;
  }

  String _getStudySystemLabel() {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'ar') return 'نظام الدراسة';
    if (locale == 'tr') return 'Çalışma Sistemi';
    return 'Study System';
  }

  String _getClassesLabel() {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'ar') return 'حصص';
    if (locale == 'tr') return 'Dersler';
    return 'Classes';
  }

  String _getHoursLabel() {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'ar') return 'ساعات';
    if (locale == 'tr') return 'Saatler';
    return 'Hours';
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
        studySystem:   _studySystem,
        studyBalance:  _studyBalance,
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
      shape:          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding:   const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      title: Row(
        children: [
          const Icon(Icons.edit_outlined, color: AppColors.primary, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.editLevelForStudent(widget.student.fullName),
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
            // ── Study System Selector ──────────────────────────
            DropdownButtonFormField<String>(
              initialValue: _studySystem,
              decoration: InputDecoration(
                labelText: _getStudySystemLabel(),
                prefixIcon: const Icon(Icons.settings_outlined, color: AppColors.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: [
                DropdownMenuItem(
                  value: 'classes',
                  child: Text(_getClassesLabel()),
                ),
                DropdownMenuItem(
                  value: 'hours',
                  child: Text(_getHoursLabel()),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _studySystem = val;
                    _studyBalance = (_total - _lesson).clamp(0.0, 99999.0);
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            const Divider(),
            _PickerRow(
              icon:     Icons.signal_cellular_alt,
              color:    AppColors.primary,
              label:    l10n.level,
              value:    _level,
              min:      1,
              max:      99,
              onMinus:  () => setState(() => _level--),
              onPlus:   () => setState(() => _level++),
            ),
            const Divider(),
            // ── Lesson picker or hours text field ─────────────────────────
            if (_studySystem == 'hours') ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: TextFormField(
                  key: const ValueKey('completed_hours'),
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
                      setState(() {
                        _lesson = parsed;
                        _studyBalance = (_total - _lesson).clamp(0.0, 99999.0);
                      });
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: TextFormField(
                  key: const ValueKey('total_hours'),
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
                      setState(() {
                        _total = parsed;
                        _studyBalance = (_total - _lesson).clamp(0.0, 99999.0);
                      });
                    }
                  },
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: TextFormField(
                  key: const ValueKey('completed_classes'),
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
                      setState(() {
                        _lesson = parsed;
                        _studyBalance = (_total - _lesson).clamp(0.0, 99999.0);
                      });
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: TextFormField(
                  key: const ValueKey('total_classes'),
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
                      setState(() {
                        _total = parsed;
                        _studyBalance = (_total - _lesson).clamp(0.0, 99999.0);
                      });
                    }
                  },
                ),
              ),
            ],
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: TextFormField(
                key: ValueKey('study_balance_${_studySystem}_$_studyBalance'),
                initialValue: _studyBalance % 1 == 0 ? '${_studyBalance.toInt()}' : '$_studyBalance',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _studySystem == 'hours'
                      ? (Localizations.localeOf(context).languageCode == 'ar'
                          ? 'الرصيد المتبقي من الساعات'
                          : Localizations.localeOf(context).languageCode == 'tr'
                              ? 'Kalan Saat Bakiyesi'
                              : 'Remaining Hours Balance')
                      : (Localizations.localeOf(context).languageCode == 'ar'
                          ? 'الرصيد المتبقي من الحصص'
                          : Localizations.localeOf(context).languageCode == 'tr'
                              ? 'Kalan Ders Bakiyesi'
                              : 'Remaining Classes Balance'),
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined, color: Colors.purple),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (val) {
                  final parsed = double.tryParse(val);
                  if (parsed != null) {
                    setState(() {
                      _studyBalance = parsed;
                    });
                  }
                },
              ),
            ),
          // ── Payment switch ─────────────────────────
          SwitchListTile(
            title: Text(
              l10n.coursePaymentStatus,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              _isPaid ? l10n.paid : l10n.notPaid,
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
              l10n.blockStudentAccount,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              _isBlocked ? l10n.blockedFromApp : l10n.activeCanEnter,
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
          child: Text(l10n.cancel,
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: _saving
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                      color: AppColors.surface, strokeWidth: 2),
                )
              : Text(l10n.saveLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child, this.trailing});
  final String  title;
  final Widget  child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color:        AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset:     const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize:   15,
                        color:      AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.progressTrack),
            Padding(
              padding: const EdgeInsets.all(12),
              child: child,
            ),
          ],
        ),
      );
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color    color;
  final String   label;
  final String   value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color:        color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize:   20,
                  fontWeight: FontWeight.bold,
                  color:      color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color:    AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.onTap,
    this.trailing,
  });
  final IconData   icon;
  final Color      color;
  final String     label;
  final String     value;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              color:    AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize:   13,
                color:      onTap != null ? AppColors.primary : AppColors.textPrimary,
                decoration: onTap != null ? TextDecoration.underline : null,
              ),
            ),
          ),
          if (trailing != null) trailing!,
          if (onTap != null && trailing == null)
            const Icon(Icons.open_in_new, size: 14, color: AppColors.textSecondary),
        ],
      ),
    );
    if (onTap != null) {
      return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: row);
    }
    return row;
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });
  final IconData     icon;
  final Color        color;
  final String       label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize:   14,
                    fontWeight: FontWeight.w500,
                    color:      AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size:  14,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      );
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onMinus,
    required this.onPlus,
  });
  final IconData     icon;
  final Color        color;
  final String       label;
  final int          value;
  final int          min;
  final int          max;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize:   14,
              ),
            ),
          ),
          IconButton(
            onPressed:   value > min ? onMinus : null,
            icon:        const Icon(Icons.remove_circle_outline),
            color:       color,
            iconSize:    22,
            padding:     EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize:   18,
                fontWeight: FontWeight.bold,
                color:      color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed:   value < max ? onPlus : null,
            icon:        const Icon(Icons.add_circle_outline),
            color:       color,
            iconSize:    22,
            padding:     EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      );
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.label, required this.color});
  final String label;
  final Color  color;

  @override
  Widget build(BuildContext context) => Chip(
        label: Text(
          label,
          style: TextStyle(
            fontSize:   11,
            color:      color,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: color.withValues(alpha: 0.10),
        side: BorderSide(color: color.withValues(alpha: 0.35)),
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
}

const List<String> _kCountries = [
  'المملكة العربية السعودية',
  'مصر',
  'الأردن',
  'فلسطين',
  'الإمارات العربية المتحدة',
  'الكويت',
  'البحرين',
  'قطر',
  'عُمان',
  'اليمن',
  'العراق',
  'سوريا',
  'لبنان',
  'ليبيا',
  'تونس',
  'الجزائر',
  'المغرب',
  'السودان',
  'الصومال',
  'موريتانيا',
  'تركيا',
  'باكستان',
  'أفغانستان',
  'بنغلاديش',
  'الهند',
  'الصين',
  'اليابان',
  'ماليزيا',
  'إندونيسيا',
  'تركمنستان',
  'أوزبكستان',
  'طاجيكستان',
  'قيرغيزستان',
  'كازاخستان',
  'أذربيجان',
  'جورجيا',
  'أرمينيا',
  'المملكة المتحدة',
  'ألمانيا',
  'فرنسا',
  'السويد',
  'النرويج',
  'الدنمارك',
  'هولندا',
  'بلجيكا',
  'سويسرا',
  'إيطاليا',
  'إسبانيا',
  'البرتغال',
  'النمسا',
  'اليونان',
  'بولندا',
  'أوكرانيا',
  'روسيا',
  'الولايات المتحدة الأمريكية',
  'كندا',
  'البرازيل',
  'الأرجنتين',
  'أستراليا',
  'جنوب إفريقيا',
  'دولة أخرى',
];

String getLocalizedCountry(BuildContext context, String countryName) {
  final locale = Localizations.localeOf(context).languageCode;
  if (locale == 'en') {
    switch (countryName) {
      case 'المملكة العربية السعودية': return 'Saudi Arabia';
      case 'مصر': return 'Egypt';
      case 'الأردن': return 'Jordan';
      case 'فلسطين': return 'Palestine';
      case 'الإمارات العربية المتحدة': return 'United Arab Emirates';
      case 'الكويت': return 'Kuwait';
      case 'البحرين': return 'Bahrain';
      case 'قطر': return 'Qatar';
      case 'عُمان': return 'Oman';
      case 'اليمن': return 'Yemen';
      case 'العراق': return 'Iraq';
      case 'سوريا': return 'Syria';
      case 'لبنان': return 'Lebanon';
      case 'ليبيا': return 'Libya';
      case 'تونس': return 'Tunisia';
      case 'الجزائر': return 'Algeria';
      case 'المغرب': return 'Morocco';
      case 'السودان': return 'Sudan';
      case 'الصومال': return 'Somalia';
      case 'موريتانيا': return 'Mauritania';
      case 'تركيا': return 'Turkey';
      case 'باكستان': return 'Pakistan';
      case 'أفغانستان': return 'Afghanistan';
      case 'بنغلاديش': return 'Bangladesh';
      case 'الهند': return 'India';
      case 'الصين': return 'China';
      case 'اليابان': return 'Japan';
      case 'ماليزيا': return 'Malaysia';
      case 'إندونيسيا': return 'Indonesia';
      case 'تركمنستان': return 'Turkmenistan';
      case 'أوزبكستان': return 'Uzbekistan';
      case 'طاجيكستان': return 'Tajikistan';
      case 'قيرغيزستان': return 'Kyrgyzstan';
      case 'كازاخستان': return 'Kazakhstan';
      case 'أذربيجان': return 'Azerbaijan';
      case 'جورجيا': return 'Georgia';
      case 'أرمينيا': return 'Armenia';
      case 'المملكة المتحدة': return 'United Kingdom';
      case 'ألمانيا': return 'Germany';
      case 'فرنسا': return 'France';
      case 'السويد': return 'Sweden';
      case 'النرويج': return 'Norway';
      case 'الدنمارك': return 'Denmark';
      case 'هولندا': return 'Netherlands';
      case 'بلجيكا': return 'Belgium';
      case 'سويسرا': return 'Switzerland';
      case 'إيطاليا': return 'Italy';
      case 'إسبانيا': return 'Spain';
      case 'البرتغال': return 'Portugal';
      case 'النمسا': return 'Austria';
      case 'اليونان': return 'Greece';
      case 'بولندا': return 'Poland';
      case 'أوكرانيا': return 'Ukraine';
      case 'روسيا': return 'Russia';
      case 'الولايات المتحدة الأمريكية': return 'United States';
      case 'كندا': return 'Canada';
      case 'البرازيل': return 'Brazil';
      case 'الأرجنتين': return 'Argentina';
      case 'أستراليا': return 'Australia';
      case 'جنوب إفريقيا': return 'South Africa';
      case 'دولة أخرى': return 'Other Country';
      default: return countryName;
    }
  } else if (locale == 'tr') {
    switch (countryName) {
      case 'المملكة العربية السعودية': return 'Suudi Arabistan';
      case 'مصر': return 'Mısır';
      case 'الأردن': return 'Ürdün';
      case 'فلسطين': return 'Filistin';
      case 'الإمارات العربية المتحدة': return 'Birleşik Arap Emirlikleri';
      case 'الكويت': return 'Kuveyt';
      case 'البحرين': return 'Bahreyn';
      case 'قطر': return 'Katar';
      case 'عُمان': return 'Umman';
      case 'اليمن': return 'Yemen';
      case 'العراق': return 'Irak';
      case 'سوريا': return 'Suriye';
      case 'لبنان': return 'Lübnan';
      case 'ليبيا': return 'Libya';
      case 'تونس': return 'Tunus';
      case 'الجزائر': return 'Cezayir';
      case 'المغرب': return 'Fas';
      case 'السودان': return 'Sudan';
      case 'الصومال': return 'Somali';
      case 'موريتانيا': return 'Moritanya';
      case 'تركيا': return 'Türkiye';
      case 'باكستان': return 'Pakistan';
      case 'أفغانستان': return 'Afganistan';
      case 'بنغلاديش': return 'Bangladeş';
      case 'الهند': return 'Hindistan';
      case 'الصين': return 'Çin';
      case 'اليابان': return 'Japonya';
      case 'ماليزيا': return 'Malezya';
      case 'إندونيسيا': return 'Endonezya';
      case 'تركمنستان': return 'Türkmenistan';
      case 'أوزبكستان': return 'Özbekistan';
      case 'طاجيكستان': return 'Tacikistan';
      case 'قيرغيزستان': return 'Kırgızistan';
      case 'كازاخستان': return 'Kazakistan';
      case 'أذربيجان': return 'Azerbaycan';
      case 'جورجيا': return 'Gürcistan';
      case 'أرمينيا': return 'Ermenistan';
      case 'المملكة المتحدة': return 'Birleşik Krallık';
      case 'ألمانيا': return 'Almanya';
      case 'فرنسا': return 'Fransa';
      case 'السويد': return 'İsveç';
      case 'النرويج': return 'Norveç';
      case 'الدنمارك': return 'Danimarka';
      case 'هولندا': return 'Hollanda';
      case 'بلجيكا': return 'Belçika';
      case 'سويسرا': return 'İsviçre';
      case 'إيطاليا': return 'İtalya';
      case 'إسبانيا': return 'İspanya';
      case 'البرتغال': return 'Portekiz';
      case 'النمسا': return 'Avusturya';
      case 'اليونان': return 'Yunanistan';
      case 'بولندا': return 'Polonya';
      case 'أوكرانيا': return 'Ukrayna';
      case 'روسيا': return 'Rusya';
      case 'الولايات المتحدة الأمريكية': return 'Amerika Birleşik Devletleri';
      case 'كندا': return 'Kanada';
      case 'البرازيل': return 'Brezilya';
      case 'الأرجنتين': return 'Arjantin';
      case 'أستراليا': return 'Avustralya';
      case 'جنوب إفريقيا': return 'Güney Afrika';
      case 'دولة أخرى': return 'Diğer Ülke';
      default: return countryName;
    }
  }
  return countryName;
}
