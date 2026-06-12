import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/lesson_schedule_model.dart';
import '../../models/profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/lesson_schedule_service.dart';
import '../../services/timezone_service.dart';

/// Teacher screen for setting (or editing) a student's weekly lesson schedule.
///
/// Each selected day can have its **own** start time.
/// Times are entered in the teacher's local timezone and stored as UTC.
/// A live preview shows what the student will see in their own timezone.
class LessonScheduleScreen extends StatefulWidget {
  const LessonScheduleScreen({super.key, required this.student});
  final ProfileModel student;

  @override
  State<LessonScheduleScreen> createState() => _LessonScheduleScreenState();
}

class _LessonScheduleScreenState extends State<LessonScheduleScreen> {
  final _scheduleService = LessonScheduleService();
  final _tzService       = TimezoneService();

  bool _loading = true;
  bool _saving  = false;

  // ── Per-day state (teacher's local timezone) ──────────────────────────────
  // dayOfWeek (ISO 1=Mon…7=Sun) → TimeOfDay in teacher local time
  final Map<int, TimeOfDay> _dayTimes = {};

  String  _teacherTimezone = 'Africa/Cairo'; // IANA
  String? _studentTimezone;                  // IANA or null

  // ── Per-day student preview ────────────────────────────────────────────────
  // teacher local dayOfWeek → formatted student time string
  Map<int, String> _studentPreview  = {};
  bool             _fetchingPreview = false;
  bool             _previewFromOnline = false;

  // Arab/Islamic week display order: Saturday first
  static const List<int> _dayOrder = [6, 7, 1, 2, 3, 4, 5];

  String _getDayName(BuildContext context, int day) {
    final date = DateTime(2026, 1, 5).add(Duration(days: day - 1));
    final locale = Localizations.localeOf(context).languageCode;
    final formatted = intl.DateFormat.EEEE(locale).format(date);
    if (locale != 'ar' && formatted.isNotEmpty) {
      return formatted[0].toUpperCase() + formatted.substring(1);
    }
    return formatted;
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final teacherProfile = context.read<AuthProvider>().profile;

    _teacherTimezone =
        _tzService.getTimezone(teacherProfile?.country) ?? 'Africa/Cairo';
    _studentTimezone = _tzService.getTimezone(widget.student.country);

    // Load existing schedule and convert UTC → teacher local
    final existing =
        await _scheduleService.getScheduleForStudent(widget.student.id);
    if (existing != null && existing.daySchedules.isNotEmpty) {
      final localEntries =
          await _tzService.entriesToLocal(existing.daySchedules, _teacherTimezone);
      for (final e in localEntries) {
        _dayTimes[e.dayOfWeek] =
            TimeOfDay(hour: e.hourUtc, minute: e.minuteUtc);
      }
    }

    await _refreshPreview();
    if (mounted) setState(() => _loading = false);
  }

  // ── Preview ───────────────────────────────────────────────────────────────

  Future<void> _refreshPreview() async {
    if (_dayTimes.isEmpty || _studentTimezone == null) {
      if (mounted) setState(() => _studentPreview = {});
      return;
    }

    if (mounted) setState(() => _fetchingPreview = true);

    try {
      // Build teacher local entries
      final teacherEntries = _dayTimes.entries
          .map((e) => DayScheduleEntry(
                dayOfWeek: e.key,
                hourUtc:   e.value.hour,
                minuteUtc: e.value.minute,
              ))
          .toList();

      // Convert teacher local → UTC → student local
      final utcEntries =
          await _tzService.entriesToUtc(teacherEntries, _teacherTimezone);
      final studentEntries =
          await _tzService.entriesToLocal(utcEntries, _studentTimezone!);

      if (!mounted) return;

      // Map teacher local day → student formatted time
      final preview = <int, String>{};
      for (int i = 0; i < teacherEntries.length; i++) {
        if (i < studentEntries.length) {
          preview[teacherEntries[i].dayOfWeek] =
              _fmt(context, studentEntries[i].hourUtc, studentEntries[i].minuteUtc);
        }
      }

      if (mounted) {
        setState(() {
          _studentPreview    = preview;
          _fetchingPreview   = false;
          _previewFromOnline = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _fetchingPreview = false);
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _toggleDay(int day) async {
    if (_dayTimes.containsKey(day)) {
      setState(() => _dayTimes.remove(day));
    } else {
      setState(() => _dayTimes[day] = const TimeOfDay(hour: 18, minute: 0));
    }
    await _refreshPreview();
  }

  Future<void> _pickTimeForDay(int day) async {
    final current = _dayTimes[day] ?? const TimeOfDay(hour: 18, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (ctx, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
    );
    if (picked != null) {
      setState(() => _dayTimes[day] = picked);
      await _refreshPreview();
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_dayTimes.isEmpty) {
      _showSnack(l10n.selectAtLeastOneDay, AppColors.error);
      return;
    }
    setState(() => _saving = true);
    try {
      final teacherId = context.read<AuthProvider>().profile!.id;

      final teacherEntries = _dayTimes.entries
          .map((e) => DayScheduleEntry(
                dayOfWeek: e.key,
                hourUtc:   e.value.hour,
                minuteUtc: e.value.minute,
                ))
          .toList();

      final utcEntries =
          await _tzService.entriesToUtc(teacherEntries, _teacherTimezone);

      await _scheduleService.upsertSchedule(
        studentId:       widget.student.id,
        teacherId:       teacherId,
        daySchedules:    utcEntries,
        teacherTimezone: _teacherTimezone,
      );
      if (mounted) {
        _showSnack(l10n.scheduleSavedSuccess, AppColors.success);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _showSnack(l10n.operationFailed(e.toString()), AppColors.error);
      }
    }
  }

  void _showSnack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:         Text(msg),
      backgroundColor: bg,
      behavior:        SnackBarBehavior.floating,
    ));
  }

  String _fmt(BuildContext context, int h, int m) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final period = h < 12 ? (isAr ? 'ص' : 'AM') : (isAr ? 'م' : 'PM');
    final h12    = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:${m.toString().padLeft(2, '0')} $period';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final teacherProfile = context.watch<AuthProvider>().profile;
    final teacherCity    = _tzService.timezoneCity(teacherProfile?.country);
    final studentCity    = _tzService.timezoneCity(widget.student.country);
    final showStudentTz  = _studentTimezone != null;

    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.lessonsScheduleTitle(widget.student.fullName),
          style: const TextStyle(
            color:      AppColors.surface,
            fontWeight: FontWeight.bold,
            fontSize:   16,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.surface),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Warnings ───────────────────────────────────────────
                  if (teacherProfile?.country == null)
                    _WarningBanner(
                      l10n.teacherCountryNotSet,
                    ),
                  if (widget.student.country == null)
                    _WarningBanner(
                      l10n.studentCountryNotSet,
                    ),

                  // ── Per-day schedule ───────────────────────────────────
                  _Card(
                    title:    l10n.daysAndLessonTimes,
                    subtitle: l10n.teacherTimezoneTime(
                        '$teacherCity / ${teacherProfile?.country ?? (l10n.localeName == 'ar' ? 'مصر' : l10n.localeName == 'tr' ? 'Mısır' : 'Egypt')}'),
                    child: Column(
                      children: _dayOrder.map((day) {
                        final isSelected = _dayTimes.containsKey(day);
                        final time       = _dayTimes[day];
                        final studentTimeStr = _studentPreview[day];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: InkWell(
                            onTap: () => _toggleDay(day),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.08)
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary.withValues(alpha: 0.40)
                                      : AppColors.progressTrack,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Circle checkbox visual
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 22, height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.textSecondary,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check,
                                            color: AppColors.surface, size: 14)
                                        : null,
                                  ),
                                  const SizedBox(width: 10),

                                  // Day name
                                  SizedBox(
                                    width: 72,
                                    child: Text(
                                      _getDayName(context, day),
                                      style: TextStyle(
                                        fontSize:   14,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),

                                  const Spacer(),

                                  // Time button (selected) or hint (not selected)
                                  if (isSelected && time != null)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        GestureDetector(
                                          onTap: () => _pickTimeForDay(day),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  _fmt(context, time.hour, time.minute),
                                                  style: const TextStyle(
                                                    color:      AppColors.surface,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize:   14,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                const Icon(Icons.edit_outlined,
                                                    color: AppColors.surface,
                                                    size: 13),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (showStudentTz &&
                                            studentTimeStr != null) ...[
                                          const SizedBox(height: 3),
                                          _fetchingPreview
                                              ? const SizedBox(
                                                  width: 14, height: 14,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: AppColors.secondary,
                                                  ),
                                                )
                                              : Text(
                                                  '$studentTimeStr ($studentCity)',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.secondary,
                                                  ),
                                                ),
                                        ],
                                      ],
                                    )
                                  else
                                    Text(
                                      l10n.clickToAdd,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color:    AppColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.medium),

                  // ── Online sync indicator ──────────────────────────────
                  if (_previewFromOnline && showStudentTz)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_done_outlined,
                              size: 14, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text(
                            l10n.timezoneUpdatedOnline,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.success),
                          ),
                        ],
                      ),
                    ),

                  // ── Save button ────────────────────────────────────────
                  SizedBox(
                    width:  double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.surface),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(_saving ? l10n.savingSchedule : l10n.saveSchedule),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.medium),
                ],
              ),
            ),
    );
  }
}

// ── Reusable card widget ──────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child, this.subtitle});
  final String  title;
  final String? subtitle;
  final Widget  child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset:     const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize:   15,
                  fontWeight: FontWeight.bold,
                  color:      AppColors.textPrimary)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ── Warning banner ────────────────────────────────────────────────────────────

class _WarningBanner extends StatelessWidget {
  const _WarningBanner(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.only(bottom: AppSpacing.medium),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: AppColors.warning.withValues(alpha: 0.40)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
