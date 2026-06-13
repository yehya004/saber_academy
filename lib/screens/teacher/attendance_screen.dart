import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../models/quiz_model.dart';
import '../../models/session_model.dart';
import '../../models/profile_model.dart';
import '../../services/attendance_service.dart';
import '../../services/quiz_service.dart';
import '../../services/profile_service.dart';
import '../../widgets/status_badge.dart';

class AttendanceScreen extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String teacherId;

  const AttendanceScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.teacherId,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _service      = AttendanceService();
  final _quizService  = QuizService();
  final _profileService = ProfileService();
  
  List<SessionModel>  _sessions   = [];
  List<QuizModel>     _quizzes    = [];
  bool                _loading    = true;
  bool                _submitting = false;
  DateTime            _selectedDate   = DateTime.now();
  String              _selectedStatus = 'present';
  String              _homeworkType   = 'text'; // 'text' | 'file' | 'quiz'
  QuizModel?          _selectedQuiz;   // chosen from picker when type == 'quiz'
  
  final _excuseCtrl   = TextEditingController();
  final _topicCtrl    = TextEditingController();
  final _homeworkCtrl = TextEditingController();
  final _resourceCtrl = TextEditingController();
  
  // For duration input (Hours system)
  ProfileModel?       _studentProfile;
  int                 _selectedDurationMinutes = 60;
  final _customDurationCtrl = TextEditingController();
  bool                _isCustomDuration = false;

  @override
  void initState() {
    super.initState();
    _load();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    if (widget.teacherId.isEmpty) return;
    final list = await _quizService.fetchTeacherQuizzes(widget.teacherId);
    if (mounted) setState(() => _quizzes = list);
  }

  @override
  void dispose() {
    _excuseCtrl.dispose();
    _topicCtrl.dispose();
    _homeworkCtrl.dispose();
    _resourceCtrl.dispose();
    _customDurationCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.fetchStudentSessions(widget.studentId),
        _profileService.fetchStudentById(widget.studentId),
      ]);
      if (mounted) {
        setState(() {
          _sessions = results[0] as List<SessionModel>;
          _studentProfile = results[1] as ProfileModel?;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context:      context,
      initialDate:  _selectedDate,
      firstDate:    DateTime(2020),
      lastDate:     DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    final locale = Localizations.localeOf(context).languageCode;
    setState(() => _submitting = true);
    try {
      final hwText   = _homeworkCtrl.text.trim();
      final typeLabel = switch (_homeworkType) {
        'file' => '[ملف] ',
        'quiz' => '[اختبار] ',
        _      => '',
      };

      // If type is quiz and a quiz was chosen, create a real quiz_assignment
      if (_homeworkType == 'quiz' && _selectedQuiz != null) {
        final q = _selectedQuiz!;
        final totalPoints = q.questions.fold<int>(0, (s, qq) => s + qq.points);
        await _quizService.assignQuiz(
          quizId:      q.id,
          studentId:   widget.studentId,
          teacherId:   widget.teacherId,
          totalPoints: totalPoints,
        );
      }

      // Always record the session (homework text is optional)
      final hwValue = hwText.isNotEmpty
          ? '$typeLabel$hwText'
          : _homeworkType == 'quiz' && _selectedQuiz != null
              ? '[اختبار] ${_selectedQuiz!.title}'
              : null;

      double finalDeduction = 1.0;
      if (_studentProfile?.studySystem == 'hours') {
        if (_isCustomDuration) {
          final parsed = double.tryParse(_customDurationCtrl.text.trim());
          if (parsed != null && parsed > 0) {
            finalDeduction = parsed / 60.0;
          } else {
            throw Exception(
              locale == 'ar'
                  ? 'الرجاء إدخال مدة الجلسة بالدقائق بشكل صحيح'
                  : 'Please enter a valid session duration in minutes'
            );
          }
        } else {
          finalDeduction = _selectedDurationMinutes / 60.0;
        }
      }

      await _service.markAttendance(
        studentId:     widget.studentId,
        teacherId:     widget.teacherId,
        sessionDate:   _selectedDate,
        status:        _selectedStatus,
        absenceExcuse: _selectedStatus == 'absent' ? _excuseCtrl.text.trim() : null,
        topic:         _topicCtrl.text.trim(),
        homework:      hwValue,
        resourceUrl:   _resourceCtrl.text.trim(),
        deductedAmount: finalDeduction,
        deductForAbsence: false,
      );
      _excuseCtrl.clear();
      _topicCtrl.clear();
      _homeworkCtrl.clear();
      _resourceCtrl.clear();
      _customDurationCtrl.clear();
      setState(() {
        _selectedDate  = DateTime.now();
        _homeworkType  = 'text';
        _selectedQuiz  = null;
        _selectedDurationMinutes = 60;
        _isCustomDuration = false;
      });
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text(AppLocalizations.of(context).sessionSavedSuccess),
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
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fmt  = intl.DateFormat('yyyy/MM/dd', 'ar');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.surface),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.attendance,
              style: const TextStyle(
                  color: AppColors.surface, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              widget.studentName,
              style: TextStyle(
                  color: AppColors.surface.withValues(alpha: 0.75), fontSize: 12),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.medium),
        children: [
          // ── Remaining Balance Banner ─────────────────────────
          if (_studentProfile != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin:  Alignment.topLeft,
                  end:    Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? 'الرصيد المتبقي للطالب'
                              : Localizations.localeOf(context).languageCode == 'tr'
                                  ? 'Öğrencinin Kalan Bakiyesi'
                                  : 'Student Remaining Balance',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Builder(
                          builder: (ctx) {
                            final double balance = (_studentProfile!.studyBalance == 0.0 && _studentProfile!.totalInLevel > _studentProfile!.lessonInLevel)
                                ? _studentProfile!.totalInLevel - _studentProfile!.lessonInLevel
                                : _studentProfile!.studyBalance;
                            final isHours = _studentProfile!.studySystem == 'hours';
                            if (isHours) {
                              final totalMinutes = (balance * 60).round();
                              final hrs = totalMinutes ~/ 60;
                              final mins = totalMinutes % 60;
                              
                              if (Localizations.localeOf(context).languageCode == 'ar') {
                                return Text(
                                  mins > 0 ? '$hrs ساعة و $mins دقيقة' : '$hrs ساعة',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              } else if (Localizations.localeOf(context).languageCode == 'tr') {
                                return Text(
                                  mins > 0 ? '$hrs saat, $mins dakika' : '$hrs saat',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              } else {
                                return Text(
                                  mins > 0 ? '$hrs hrs, $mins mins' : '$hrs hrs',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }
                            } else {
                              final count = balance.toInt();
                              if (Localizations.localeOf(context).languageCode == 'ar') {
                                return Text(
                                  '$count حصة',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              } else if (Localizations.localeOf(context).languageCode == 'tr') {
                                return Text(
                                  '$count ders',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              } else {
                                return Text(
                                  '$count classes',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
          ],

          // ── New session form ─────────────────────────────────
          _FormSection(
            title: l10n.recordSession,
            children: [
              // Date
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color:        AppColors.background,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        fmt.format(_selectedDate),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color:      AppColors.textPrimary),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down,
                          color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.medium),

              // Status toggle
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _StatusChip(
                      label:    l10n.present,
                      selected: _selectedStatus == 'present',
                      color:    AppColors.success,
                      onTap: () => setState(() => _selectedStatus = 'present'),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    _StatusChip(
                      label:    Localizations.localeOf(context).languageCode == 'ar' ? 'متأخر' : 'Late',
                      selected: _selectedStatus == 'late',
                      color:    Colors.orange,
                      onTap: () => setState(() => _selectedStatus = 'late'),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    _StatusChip(
                      label:    l10n.absent,
                      selected: _selectedStatus == 'absent',
                      color:    AppColors.error,
                      onTap: () => setState(() => _selectedStatus = 'absent'),
                    ),
                  ],
                ),
              ),

              // Excuse field
              if (_selectedStatus == 'absent') ...[
                const SizedBox(height: AppSpacing.medium),
                _TextInput(
                  controller: _excuseCtrl,
                  label:      l10n.absenceExcuse,
                  icon:       Icons.info_outline,
                  iconColor:  AppColors.warning,
                  maxLines:   2,
                ),
              ],

              // Duration selector (Hours system only)
              if (_studentProfile?.studySystem == 'hours' &&
                  (_selectedStatus == 'present' || _selectedStatus == 'late')) ...[
                const SizedBox(height: AppSpacing.medium),
                Text(
                  Localizations.localeOf(context).languageCode == 'ar'
                      ? 'مدة الجلسة المستهلكة'
                      : Localizations.localeOf(context).languageCode == 'tr'
                          ? 'Ders Süresi'
                          : 'Session Duration',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize:   13,
                      color:      AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  initialValue: _isCustomDuration ? null : _selectedDurationMinutes,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.alarm_outlined, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  hint: Text(
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? 'اختر المدة'
                        : 'Select duration',
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 30,
                      child: Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? '30 دقيقة (نصف ساعة)'
                            : '30 minutes (0.5 hour)',
                      ),
                    ),
                    DropdownMenuItem(
                      value: 45,
                      child: Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? '45 دقيقة (0.75 ساعة)'
                            : '45 minutes (0.75 hour)',
                      ),
                    ),
                    DropdownMenuItem(
                      value: 60,
                      child: Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? '60 دقيقة (ساعة كاملة)'
                            : '60 minutes (1 hour)',
                      ),
                    ),
                    DropdownMenuItem(
                      value: 90,
                      child: Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? '90 دقيقة (ساعة ونصف)'
                            : '90 minutes (1.5 hours)',
                      ),
                    ),
                    DropdownMenuItem(
                      value: 120,
                      child: Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? '120 دقيقة (ساعتان)'
                            : '120 minutes (2 hours)',
                      ),
                    ),
                    DropdownMenuItem(
                      value: -1,
                      child: Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? 'مدة مخصصة (كتابة بالدقائق)'
                            : 'Custom duration (type in minutes)',
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        if (val == -1) {
                          _isCustomDuration = true;
                        } else {
                          _isCustomDuration = false;
                          _selectedDurationMinutes = val;
                        }
                      });
                    }
                  },
                ),
                if (_isCustomDuration) ...[
                  const SizedBox(height: AppSpacing.small),
                  TextField(
                    controller: _customDurationCtrl,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: Localizations.localeOf(context).languageCode == 'ar'
                          ? 'المدة بالدقائق (مثال: 50)'
                          : 'Duration in minutes (e.g. 50)',
                      prefixIcon: const Icon(Icons.edit_note_outlined, color: AppColors.secondary),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ],

              const SizedBox(height: AppSpacing.medium),
              const Divider(height: 1, color: AppColors.progressTrack),
              const SizedBox(height: AppSpacing.medium),

              // Topic
              _TextInput(
                controller: _topicCtrl,
                label:      l10n.sessionTopicLabel,
                hint:       l10n.sessionTopicHint,
                icon:       Icons.menu_book_outlined,
                iconColor:  AppColors.primary,
                maxLines:   3,
              ),
              const SizedBox(height: AppSpacing.medium),

              // Homework type selector
              Text(
                l10n.homeworkType,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize:   13,
                    color:      AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _HomeworkTypeChip(
                    icon:     Icons.notes_outlined,
                    label:    l10n.homeworkTypeText,
                    value:    'text',
                    selected: _homeworkType,
                    color:    AppColors.primary,
                    onTap:    (v) => setState(() { _homeworkType = v; _selectedQuiz = null; }),
                  ),
                  _HomeworkTypeChip(
                    icon:     Icons.attach_file_outlined,
                    label:    l10n.homeworkTypeFile,
                    value:    'file',
                    selected: _homeworkType,
                    color:    AppColors.warning,
                    onTap:    (v) => setState(() { _homeworkType = v; _selectedQuiz = null; }),
                  ),
                  _HomeworkTypeChip(
                    icon:     Icons.quiz_outlined,
                    label:    l10n.homeworkTypeQuiz,
                    value:    'quiz',
                    selected: _homeworkType,
                    color:    AppColors.secondary,
                    onTap:    (v) => setState(() { _homeworkType = v; }),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.medium),

              // Quiz picker — shown only when type == 'quiz'
              if (_homeworkType == 'quiz') ...[
                if (_quizzes.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:        AppColors.secondary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                      border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 16, color: AppColors.secondary),
                        const SizedBox(width: 8),
                        Text(l10n.noQuizzesInBank,
                            style: const TextStyle(
                                fontSize: 12,
                                color:    AppColors.textSecondary)),
                      ],
                    ),
                  )
                else
                  DropdownButtonFormField<QuizModel>(
                    initialValue: _selectedQuiz,
                    isExpanded:  true,
                    decoration: InputDecoration(
                      labelText:  l10n.selectQuizFromBank,
                      prefixIcon: const Icon(Icons.quiz_outlined,
                          color: AppColors.secondary),
                      filled:    true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.cardRadius),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: _quizzes.map((q) {
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
                    onChanged: (q) => setState(() => _selectedQuiz = q),
                  ),
                const SizedBox(height: AppSpacing.medium),
              ],

              // Homework notes (optional when quiz is selected)
              _TextInput(
                controller: _homeworkCtrl,
                label:      l10n.homework,
                hint: _homeworkType == 'quiz'
                    ? l10n.homeworkNoteOptional
                    : _homeworkType == 'file'
                        ? l10n.homeworkNoteFileHint
                        : l10n.homeworkNoteTextHint,
                icon:       Icons.assignment_outlined,
                iconColor:  _homeworkType == 'quiz'
                    ? AppColors.secondary
                    : _homeworkType == 'file'
                        ? AppColors.warning
                        : AppColors.primary,
                maxLines:   3,
              ),
              const SizedBox(height: AppSpacing.medium),

              // Resource link
              _TextInput(
                controller: _resourceCtrl,
                label:      l10n.referenceLinkOptional,
                hint:       'https://...',
                icon:       Icons.link_outlined,
                iconColor:  AppColors.secondary,
                keyboard:   TextInputType.url,
              ),

              const SizedBox(height: AppSpacing.medium),

              SizedBox(
                width:  double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    ),
                  ),
                  icon: _submitting
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.surface),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: Text(_submitting ? '...' : l10n.saveSession),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.large),

          // ── Session history ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.small),
            child: Text(
              l10n.sessionHistory,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize:   15,
                color:      AppColors.textPrimary,
              ),
            ),
          ),

          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_sessions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.noSessionsYet,
                    style: const TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            ...List.generate(
              _sessions.length,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SessionCard(
                  session: _sessions[i],
                  fmt: fmt,
                  studySystem: _studentProfile?.studySystem ?? 'classes',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Session Card (expandable) ─────────────────────────────────────────────────

class _SessionCard extends StatefulWidget {
  const _SessionCard({
    required this.session,
    required this.fmt,
    required this.studySystem,
  });
  final SessionModel session;
  final intl.DateFormat   fmt;
  final String studySystem;
  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  bool _expanded = false;

  bool get _hasDetails =>
      (widget.session.topic?.isNotEmpty ?? false) ||
      (widget.session.homework?.isNotEmpty ?? false) ||
      (widget.session.resourceUrl?.isNotEmpty ?? false) ||
      (widget.session.absenceExcuse?.isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row
          InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            onTap: _hasDetails ? () => setState(() => _expanded = !_expanded) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.medium, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    s.status == 'late'
                        ? Icons.watch_later_outlined
                        : (s.isPresent ? Icons.check_circle : Icons.cancel_outlined),
                    color: s.status == 'late'
                        ? Colors.orange
                        : (s.isPresent ? AppColors.success : AppColors.error),
                    size:  20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.fmt.format(s.sessionDate),
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${formatSessionDuration(s.deductedAmount, widget.studySystem, l10n.localeName)})',
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (s.topic != null && s.topic!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.topic!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                  ] else
                    const Spacer(),
                  StatusBadge(status: s.status),
                  if (_hasDetails) ...[
                    const SizedBox(width: 6),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary,
                      size:  18,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Expanded details
          if (_expanded && _hasDetails) ...[
            const Divider(
                height: 1, indent: 16, endIndent: 16,
                color: AppColors.progressTrack),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (s.absenceExcuse != null && s.absenceExcuse!.isNotEmpty)
                    _DetailRow(
                      icon:  Icons.info_outline,
                      color: AppColors.warning,
                      label: l10n.absenceExcuse,
                      text:  s.absenceExcuse!,
                    ),
                  if (s.topic != null && s.topic!.isNotEmpty)
                    _DetailRow(
                      icon:  Icons.menu_book_outlined,
                      color: AppColors.primary,
                      label: l10n.topicCovered,
                      text:  s.topic!,
                    ),
                  if (s.homework != null && s.homework!.isNotEmpty) ...[
                    Builder(builder: (ctx) {
                      final hw = s.homework!;
                      final isFile = hw.startsWith('[ملف] ');
                      final isQuiz = hw.startsWith('[اختبار] ');
                      final icon  = isQuiz
                          ? Icons.quiz_outlined
                          : isFile
                              ? Icons.attach_file_outlined
                              : Icons.assignment_outlined;
                      final color = isQuiz
                          ? AppColors.secondary
                          : isFile
                              ? AppColors.warning
                              : AppColors.primary;
                      final displayText = isFile
                          ? hw.substring('[ملف] '.length)
                          : isQuiz
                              ? hw.substring('[اختبار] '.length)
                              : hw;
                      final typeLabel = isFile
                          ? l10n.homeworkTypeFile
                          : isQuiz
                              ? l10n.homeworkTypeQuiz
                              : l10n.homework;
                      return _DetailRow(
                          icon:  icon,
                          color: color,
                          label: typeLabel,
                          text:  displayText);
                    }),
                  ],
                  if (s.resourceUrl != null && s.resourceUrl!.isNotEmpty)
                    _ResourceRow(url: s.resourceUrl!),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.text,
  });
  final IconData icon;
  final Color    color;
  final String   label;
  final String   text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(text,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textPrimary)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ResourceRow extends StatelessWidget {
  const _ResourceRow({required this.url});
  final String url;

  Future<void> _open() async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.link_outlined, color: AppColors.secondary, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context).resourceLabel,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: _open,
                    child: Text(
                      url,
                      maxLines:  2,
                      overflow:  TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize:   13,
                        color:      AppColors.secondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

// ── Form helpers ──────────────────────────────────────────────────────────────

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.children});
  final String       title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
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
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize:   15,
                color:      AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            ...children,
          ],
        ),
      );
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.controller,
    required this.label,
    required this.icon,
    required this.iconColor,
    this.hint,
    this.maxLines = 1,
    this.keyboard = TextInputType.text,
  });
  final TextEditingController controller;
  final String                label;
  final String?               hint;
  final IconData              icon;
  final Color                 iconColor;
  final int                   maxLines;
  final TextInputType         keyboard;

  @override
  Widget build(BuildContext context) {
    final dir = keyboard == TextInputType.url
        ? TextDirection.ltr
        : TextDirection.rtl;
    return TextField(
      controller:   controller,
      maxLines:     maxLines,
      keyboardType: keyboard,
      textDirection: dir,
      decoration: InputDecoration(
        labelText:  label,
        hintText:   hint,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: iconColor, size: 20),
        filled:     true,
        fillColor:  AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          borderSide:   BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String       label;
  final bool         selected;
  final Color        color;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color:        selected ? color : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border:       Border.all(color: color, width: 1.5),
          ),
          child: Text(
            label,
            style: TextStyle(
              color:      selected ? Colors.white : color,
            fontWeight: FontWeight.w600,
            fontSize:   13,
          ),
        ),
      ),
    );
}

// ── Homework type chip ────────────────────────────────────────────────────────

class _HomeworkTypeChip extends StatelessWidget {
  final IconData              icon;
  final String                label;
  final String                value;
  final String                selected;
  final Color                 color;
  final void Function(String) onTap;

  const _HomeworkTypeChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color:        isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15,
                color: isSelected ? Colors.white : color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w600,
                  color:      isSelected ? Colors.white : color),
            ),
          ],
        ),
      ),
    );
  }
}

String formatSessionDuration(double amount, String studySystem, String locale) {
  final isHours = studySystem == 'hours';
  final isAr = locale == 'ar';
  final isTr = locale == 'tr';
  if (isHours) {
    if (isAr) {
      if (amount == 1.0) return 'ساعة واحدة';
      if (amount == 1.5) return 'ساعة ونصف';
      if (amount == 2.0) return 'ساعتان';
      final totalMinutes = (amount * 60).round();
      final hrs = totalMinutes ~/ 60;
      final mins = totalMinutes % 60;
      return mins > 0 ? '$hrs س و $mins د' : '$hrs س';
    } else if (isTr) {
      final totalMinutes = (amount * 60).round();
      final hrs = totalMinutes ~/ 60;
      final mins = totalMinutes % 60;
      return mins > 0 ? '$hrs sa $mins dk' : '$hrs sa';
    } else {
      final totalMinutes = (amount * 60).round();
      final hrs = totalMinutes ~/ 60;
      final mins = totalMinutes % 60;
      return mins > 0 ? '$hrs h $mins m' : '$hrs h';
    }
  } else {
    if (isAr) {
      if (amount == 1.0) return 'حصة واحدة';
      if (amount == 2.0) return 'حصتان';
      return '${amount.toInt()} حصص';
    } else if (isTr) {
      return '${amount.toInt()} Ders';
    } else {
      return '${amount.toInt()} classes';
    }
  }
}
