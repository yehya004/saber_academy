import 'dart:convert';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/router/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/lesson_schedule_model.dart';
import '../../models/profile_model.dart';
import '../../models/session_model.dart';
import '../../models/lesson_postponement_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/attendance_service.dart';
import '../../services/chat_service.dart';
import '../../services/lesson_schedule_service.dart';
import '../../services/profile_service.dart';
import '../../models/quiz_assignment_model.dart';
import '../../services/quiz_service.dart';
import '../../services/timezone_service.dart';
import '../../widgets/level_progress_indicator.dart';
import '../../services/notification_service.dart';
import '../../services/lesson_postponement_service.dart';
import '../../widgets/status_badge.dart';

const Map<String, Map<int, String>> _localizedDayNames = {
  'ar': {
    1: 'الاثنين', 2: 'الثلاثاء', 3: 'الأربعاء',
    4: 'الخميس',  5: 'الجمعة',   6: 'السبت',  7: 'الأحد',
  },
  'en': {
    1: 'Monday', 2: 'Tuesday', 3: 'Wednesday',
    4: 'Thursday', 5: 'Friday', 6: 'Saturday', 7: 'Sunday',
  },
  'tr': {
    1: 'Pazartesi', 2: 'Salı', 3: 'Çarşamba',
    4: 'Perşembe', 5: 'Cuma', 6: 'Cumartesi', 7: 'Pazar',
  },
};

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final _attendanceService = AttendanceService();
  final _profileService    = ProfileService();
  final _scheduleService   = LessonScheduleService();
  final _tzService         = TimezoneService();

  final _chatService = ChatService();

  Map<String, num>?        _levelData;
  ProfileModel?            _studentProfile;
  ProfileModel?            _teacher;
  LessonScheduleModel?     _schedule;
  // Per-day entries converted to student's local timezone
  List<DayScheduleEntry>   _localEntries   = [];
  DateTime?                _nextLessonDateTime;
  bool                     _scheduleFromOnline = false;
  List<SessionModel>       _recentSessions = [];
  int                      _unreadMessages  = 0;
  int                      _pendingQuizzes  = 0;
  List<LessonPostponementModel> _postponements = [];
  bool                     _hasAutoOpenedChat = false;

  final _quizService = QuizService();
  String? _loadedUserId;

  @override
  void initState() {
    super.initState();
    NotificationService().requestPermissions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final auth = Provider.of<AuthProvider>(context);
    final userId = auth.profile?.id;
    if (userId != null && userId != _loadedUserId) {
      _loadedUserId = userId;
      _loadData();
    } else if (userId == null && _loadedUserId != null) {
      _loadedUserId = null;
      _clearState();
    }

    if (!_hasAutoOpenedChat) {
      try {
        final state = GoRouterState.of(context);
        final partnerId = state.uri.queryParameters['chat_partner_id'];
        final partnerName = state.uri.queryParameters['chat_partner_name'];
        if (partnerId != null && partnerName != null) {
          _hasAutoOpenedChat = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.push(
                AppRoutes.chat,
                extra: {
                  'partnerId': partnerId,
                  'partnerName': partnerName,
                },
              );
            }
          });
        }
      } catch (e) {
        debugPrint("Error checking auto-open chat: $e");
      }
    }
  }

  void _clearState() {
    _levelData = null;
    _studentProfile = null;
    _teacher = null;
    _schedule = null;
    _localEntries = [];
    _nextLessonDateTime = null;
    _scheduleFromOnline = false;
    _recentSessions = [];
    _unreadMessages = 0;
    _pendingQuizzes = 0;
    _postponements = [];
  }

  Future<void> _loadData() async {
    final profile = context.read<AuthProvider>().profile;
    final userId  = profile?.id;
    if (userId == null) return;

    final cacheKey = 'cached_student_data_$userId';
    final prefs = await SharedPreferences.getInstance();

    // 1. Immediately load cached data from local SharedPreferences if it exists
    final cachedStr = prefs.getString(cacheKey);
    if (cachedStr != null) {
      try {
        final cached = jsonDecode(cachedStr) as Map<String, dynamic>;
        
        final levelData = Map<String, num>.from(cached['levelData'] ?? {});
        final teacher = cached['teacher'] != null ? ProfileModel.fromMap(cached['teacher']) : null;
        final schedule = cached['schedule'] != null ? LessonScheduleModel.fromMap(cached['schedule']) : null;
        final recentSessions = (cached['recentSessions'] as List? ?? [])
            .map((s) => SessionModel.fromMap(s as Map<String, dynamic>))
            .toList();
        final unreadMessages = cached['unreadMessages'] as int? ?? 0;
        final pendingQuizzes = cached['pendingQuizzes'] as int? ?? 0;
        final studentProfile = cached['studentProfile'] != null ? ProfileModel.fromMap(cached['studentProfile']) : null;

        DateTime? nextLessonDateTime;
        bool fromOnline = false;
        List<DayScheduleEntry> localEntries = [];

        if (schedule != null && schedule.daySchedules.isNotEmpty) {
          final studentTz = _tzService.getTimezone(profile?.country);
          if (studentTz != null) {
            try {
              localEntries = await _tzService.entriesToLocal(schedule.daySchedules, studentTz);
              fromOnline = true;
              final nextUtc = _tzService.nextLessonUtcFromEntries(schedule.daySchedules);
              final offsetMin = _tzService.getUtcOffsetMinutes(studentTz);
              nextLessonDateTime = nextUtc.add(Duration(minutes: offsetMin));
            } catch (_) {}
          }
        }

        if (mounted) {
          setState(() {
            _levelData = levelData;
            _studentProfile = studentProfile;
            _teacher = teacher;
            _schedule = schedule;
            _localEntries = localEntries;
            _nextLessonDateTime = nextLessonDateTime;
            _scheduleFromOnline = fromOnline;
            _recentSessions = recentSessions;
            _unreadMessages = unreadMessages;
            _pendingQuizzes = pendingQuizzes;
          });
        }
      } catch (e) {
        debugPrint("Error parsing cached student data: $e");
      }
    }

    // 2. Fetch fresh data and update cache
    try {
      final results = await Future.wait([
        _attendanceService.getStudentLevelData(userId)
            .catchError((_) => <String, num>{'total_attended': 0, 'level': 1, 'progress_in_level': 0.0}),
        _profileService.fetchTeacherForStudent(userId)
            .catchError((_) => null),
        _scheduleService.getScheduleForStudent(userId)
            .catchError((_) => null),
        _attendanceService.fetchStudentSessions(userId)
            .catchError((_) => <SessionModel>[]),
        _chatService.getUnreadCount(userId)
            .catchError((_) => 0),
        _quizService.fetchStudentAssignments(userId)
            .catchError((_) => <QuizAssignmentModel>[]),
        LessonPostponementService().getPostponementsForStudent(userId)
            .catchError((_) => <LessonPostponementModel>[]),
        _profileService.fetchStudentById(userId)
            .catchError((_) => null),
      ]);

      final levelData = results[0] as Map<String, num>;
      final teacher   = results[1] as ProfileModel?;
      final schedule  = results[2] as LessonScheduleModel?;
      final allSessions = results[3] as List<SessionModel>;
      final unreadMessages = results[4] as int;
      final quizAssignments = results[5] as List<dynamic>;
      final pendingQuizzes = quizAssignments
          .where((a) => (a as dynamic).status == 'pending')
          .length;
      final recentSessions = allSessions;
      final postponements = results[6] as List<LessonPostponementModel>;
      final studentProfile = results[7] as ProfileModel?;

      DateTime?              nextLessonDateTime;
      bool                   fromOnline  = false;
      List<DayScheduleEntry> localEntries = [];

      if (schedule != null && schedule.daySchedules.isNotEmpty) {
        final studentTz = _tzService.getTimezone(profile?.country);
        if (studentTz != null) {
          try {
            localEntries = await _tzService.entriesToLocal(
                schedule.daySchedules, studentTz);
            fromOnline = true;

            // Next lesson label
            final nextUtc   = _tzService.nextLessonUtcFromEntries(schedule.daySchedules);
            final offsetMin = _tzService.getUtcOffsetMinutes(studentTz);
            nextLessonDateTime = nextUtc.add(Duration(minutes: offsetMin));
          } catch (_) {}
        }
      }

      if (mounted) {
        setState(() {
          _levelData          = levelData;
          _studentProfile     = studentProfile;
          _teacher            = teacher;
          _schedule           = schedule;
          _localEntries       = localEntries;
          _nextLessonDateTime = nextLessonDateTime;
          _scheduleFromOnline = fromOnline;
          _recentSessions     = recentSessions;
          _unreadMessages     = unreadMessages;
          _pendingQuizzes     = pendingQuizzes;
          _postponements      = postponements;
        });

        // Trigger local notifications scheduling
        if (localEntries.isNotEmpty && (profile?.fullName ?? '').isNotEmpty) {
          NotificationService().scheduleLessonReminders(localEntries, profile!.fullName);
        }
      }

      // Save fresh data to local cache
      final dataToCache = {
        'levelData': levelData,
        'teacher': teacher?.toMap(),
        'schedule': schedule?.toMap(),
        'recentSessions': recentSessions.map((s) => s.toMap()).toList(),
        'unreadMessages': unreadMessages,
        'pendingQuizzes': pendingQuizzes,
        'studentProfile': studentProfile?.toMap(),
      };
      await prefs.setString(cacheKey, jsonEncode(dataToCache));

    } catch (e) {
      debugPrint("StudentHomeScreen._loadData offline fetch error: $e");
    }
  }



  static String _fmtTime(int h, int m, String locale) {
    final isAr = locale == 'ar';
    final period = h < 12 ? (isAr ? 'ص' : 'AM') : (isAr ? 'م' : 'PM');
    final h12    = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:${m.toString().padLeft(2, '0')} $period';
  }


  String _nextLessonText(DateTime nextLocal, int localH, int localM, AppLocalizations l10n) {
    final nowUtc      = DateTime.now().toUtc();
    final diffDays    = nextLocal.difference(nowUtc).inDays;
    final timeStr     = _fmtTime(localH, localM, l10n.localeName);
    if (diffDays == 0) return l10n.todayAt(timeStr);
    if (diffDays == 1) return l10n.tomorrowAt(timeStr);
    final days = _localizedDayNames[l10n.localeName] ?? _localizedDayNames['en']!;
    return l10n.dayAt(days[nextLocal.weekday] ?? '', timeStr);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context);
    final name = auth.profile?.fullName ?? '';
    final isBlocked = auth.profile?.isBlocked ?? false;
    final nextLabel = _nextLessonDateTime != null
        ? _nextLessonText(_nextLessonDateTime!, _nextLessonDateTime!.hour, _nextLessonDateTime!.minute, l10n)
        : null;

    if (isBlocked) {
      return Scaffold(
        backgroundColor: const Color(0xFF06120E),
        bottomNavigationBar: NavigationBar(
          selectedIndex: 0,
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primary.withValues(alpha: 0.12),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (i) {
            if (i == 1) {
              context.push(AppRoutes.settings).then((_) => _loadData());
            }
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home, color: AppColors.primary),
              label: l10n.home,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings, color: AppColors.primary),
              label: l10n.settings,
            ),
          ],
        ),
        body: _buildBlockedScreen(context, l10n),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: NavigationBar(
        selectedIndex:           0,
        backgroundColor:         AppColors.surface,
        indicatorColor:          AppColors.primary.withValues(alpha: 0.12),
        labelBehavior:           NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected:   (i) {
          if (i == 1) context.push(AppRoutes.studentHomework);
          if (i == 2) context.push(AppRoutes.studentQuizzes).then((_) => _loadData());
          if (i == 3) context.push(AppRoutes.mushaf);
          if (i == 4) context.push(AppRoutes.settings);
        },
        destinations: [
          NavigationDestination(
            icon:         const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home, color: AppColors.primary),
            label:        l10n.home,
          ),
          NavigationDestination(
            icon:         const Icon(Icons.assignment_outlined),
            selectedIcon: const Icon(Icons.assignment, color: AppColors.primary),
            label:        l10n.homework,
          ),
          NavigationDestination(
            icon: _pendingQuizzes > 0
                ? Badge(label: Text('$_pendingQuizzes'), child: const Icon(Icons.quiz_outlined))
                : const Icon(Icons.quiz_outlined),
            selectedIcon: const Icon(Icons.quiz, color: AppColors.primary),
            label:        l10n.quizzes,
          ),
          NavigationDestination(
            icon:         const Icon(Icons.auto_stories_outlined),
            selectedIcon: const Icon(Icons.auto_stories, color: AppColors.primary),
            label:        l10n.mushaf,
          ),
          NavigationDestination(
            icon:         const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings, color: AppColors.primary),
            label:        l10n.settings,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color:     AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // ── Gradient header ────────────────────────────────
            SliverAppBar(
              expandedHeight:  220,
              pinned:          true,
              backgroundColor: AppColors.primary,
              actions: [
                // Chat with teacher button
                GestureDetector(
                  onTap: () {
                    if (_teacher == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:  Text(l10n.noTeacherAssigned),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    context.push(
                      AppRoutes.chat,
                      extra: {
                        'partnerId':   _teacher!.id,
                        'partnerName': _teacher!.fullName,
                      },
                    ).then((_) => _loadData());
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          backgroundImage: _teacher?.avatarUrl != null && _teacher!.avatarUrl!.isNotEmpty
                              ? NetworkImage(_teacher!.avatarUrl!)
                              : null,
                          child: _teacher?.avatarUrl == null || _teacher!.avatarUrl!.isEmpty
                              ? const Icon(Icons.chat_bubble_outline, color: AppColors.surface, size: 18)
                              : null,
                        ),
                      ),
                      if (_unreadMessages > 0)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                _unreadMessages > 9 ? '9+' : '$_unreadMessages',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon:      const Icon(Icons.settings_outlined, color: AppColors.surface),
                  onPressed: () => context.push(AppRoutes.settings),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin:  Alignment.topLeft,
                      end:    Alignment.bottomRight,
                      colors: [AppColors.primary, Color(0xFF1E6147)],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.localeName == 'ar'
                                      ? 'السلام عليكم،'
                                      : l10n.localeName == 'tr'
                                          ? 'Selamun Aleykum,'
                                          : 'Assalamu Alaykum,',
                                  style: TextStyle(
                                    color:    AppColors.surface.withValues(alpha: 0.75),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  name.isNotEmpty ? name : l10n.myProgress,
                                  style: const TextStyle(
                                    color:      AppColors.surface,
                                    fontSize:   24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Student Avatar
                          Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1.5,
                              ),
                              image: auth.profile?.avatarUrl != null && auth.profile!.avatarUrl!.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(auth.profile!.avatarUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: auth.profile?.avatarUrl == null || auth.profile!.avatarUrl!.isEmpty
                                ? Center(
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : '؟',
                                      style: const TextStyle(
                                        color:      AppColors.secondary,
                                        fontSize:   22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      // Level pill
                      if (_levelData != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:        AppColors.secondary.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.secondary.withValues(alpha: 0.50),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: AppColors.secondary,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${l10n.level} ${_levelData!['level']}',
                                style: const TextStyle(
                                  color:      AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize:   13,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.medium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (auth.profile?.isPaid == false) ...[
                      // Premium alert bar with gradient border and a trailing chat trigger
                      Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.medium),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFF39C12).withValues(alpha: 0.08),
                              const Color(0xFFE67E22).withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFF39C12).withValues(alpha: 0.25),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE67E22).withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: () {
                              if (_teacher != null) {
                                context.push(
                                  AppRoutes.chat,
                                  extra: {
                                    'partnerId': _teacher!.id,
                                    'partnerName': _teacher!.fullName,
                                  },
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE67E22).withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.star_half_rounded,
                                      color: Color(0xFFE67E22),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.paymentStatus,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFD35400),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          l10n.paymentReminder,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: const Color(0xFFD35400).withValues(alpha: 0.8),
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Color(0xFFE67E22),
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.medium),
                    ],
                    // ── Progress card ────────────────────────────
                    _SectionTitle(title: l10n.myProgress),
                    const SizedBox(height: AppSpacing.small),

                    Container(
                      padding: const EdgeInsets.all(AppSpacing.large),
                      decoration: BoxDecoration(
                        color:        AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color:      Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset:     const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _levelData != null
                          ? Builder(
                              builder: (ctx) {
                                final profile = _studentProfile ?? auth.profile;
                                final level = _levelData!['level']!.toInt();
                                final progress = _levelData!['progress_in_level']!.toDouble();
                                final total = profile?.totalInLevel ?? 20.0;
                                final totalAttended = _levelData!['total_attended']!.toInt();
                                final studySystem = profile?.studySystem ?? 'classes';
                                final double rawBalance = profile?.studyBalance ?? 0.0;

                                final double balance = (rawBalance == 0.0 && total > progress)
                                    ? (total - progress)
                                    : rawBalance;

                                final isHours = studySystem == 'hours';

                                String progressText = '';
                                String progressLabel = '';
                                if (isHours) {
                                  progressText = '${progress % 1 == 0 ? progress.toInt() : progress.toStringAsFixed(1)} / ${total % 1 == 0 ? total.toInt() : total.toStringAsFixed(1)}';
                                  progressLabel = l10n.localeName == 'ar' ? 'ساعة مكتملة' : (l10n.localeName == 'tr' ? 'Tamamlanan Saat' : 'Hours Completed');
                                } else {
                                  progressText = '${progress.toInt()} / ${total.toInt()}';
                                  progressLabel = l10n.localeName == 'ar' ? 'حصة مكتملة' : (l10n.localeName == 'tr' ? 'Tamamlanan Ders' : 'Classes Completed');
                                }

                                String balanceStr = '';
                                if (isHours) {
                                  final totalMinutes = (balance * 60).round();
                                  final hrs = totalMinutes ~/ 60;
                                  final mins = totalMinutes % 60;
                                  if (l10n.localeName == 'ar') {
                                    balanceStr = mins > 0 ? '$hrs س و $mins د' : '$hrs س';
                                  } else if (l10n.localeName == 'tr') {
                                    balanceStr = mins > 0 ? '$hrs sa $mins dk' : '$hrs sa';
                                  } else {
                                    balanceStr = mins > 0 ? '$hrs h $mins m' : '$hrs h';
                                  }
                                } else {
                                  if (l10n.localeName == 'ar') {
                                    balanceStr = '${balance.toInt()} حصة';
                                  } else if (l10n.localeName == 'tr') {
                                    balanceStr = '${balance.toInt()} Ders';
                                  } else {
                                    balanceStr = '${balance.toInt()} classes';
                                  }
                                }

                                return Row(
                                  children: [
                                    LevelProgressIndicator(
                                      level:           level,
                                      progressInLevel: progress,
                                      totalInLevel:    total,
                                    ),
                                    const SizedBox(width: AppSpacing.large),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _StatRow(
                                            icon:  Icons.check_circle_outline,
                                            color: AppColors.success,
                                            label: l10n.totalAttended(totalAttended),
                                          ),
                                          const SizedBox(height: 12),
                                          _StatRow(
                                            icon:  Icons.menu_book_outlined,
                                            color: AppColors.secondary,
                                            label: '$progressText $progressLabel',
                                          ),
                                          const SizedBox(height: 12),
                                          _StatRow(
                                            icon:  Icons.account_balance_wallet_outlined,
                                            color: Colors.purple,
                                            label: l10n.localeName == 'ar' 
                                                ? 'الرصيد المتبقي: $balanceStr' 
                                                : (l10n.localeName == 'tr' 
                                                    ? 'Kalan Bakiye: $balanceStr' 
                                                    : 'Remaining Balance: $balanceStr'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }
                            )
                          : const Center(
                              child: Padding(
                                padding: EdgeInsets.all(AppSpacing.medium),
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                    ),

                    const SizedBox(height: AppSpacing.large),

                    // ── Upcoming lesson ──────────────────────────
                    _SectionTitle(title: l10n.upcomingLesson),
                    const SizedBox(height: AppSpacing.small),
                    _UpcomingLessonCard(
                      schedule:     _schedule,
                      localEntries: _localEntries,
                      nextLabel:    nextLabel,
                      fromOnline:   _scheduleFromOnline,
                      hasCountry:   context.read<AuthProvider>().profile?.country != null,
                      postponements: _postponements,
                      onPostpone:    null,
                      onCancelPostpone: null,
                    ),

                    const SizedBox(height: AppSpacing.large),

                    // ── Quick actions ────────────────────────────
                    _SectionTitle(title: l10n.quickActions),
                    const SizedBox(height: AppSpacing.small),

                    _QuickActionCard(
                      icon:        Icons.assignment_outlined,
                      title:       l10n.homework,
                      subtitle:    l10n.viewSubmitHomework,
                      accentColor: AppColors.warning,
                      onTap:       () => context.push(AppRoutes.studentHomework),
                    ),
                    const SizedBox(height: AppSpacing.small),
                    _QuickActionCard(
                      icon:        Icons.quiz_outlined,
                      title:       l10n.quizzes,
                      subtitle:    _pendingQuizzes > 0
                          ? l10n.pendingQuizzesCount(_pendingQuizzes)
                          : l10n.viewAssignedQuizzes,
                      accentColor: AppColors.secondary,
                      badge:       _pendingQuizzes > 0 ? '$_pendingQuizzes' : null,
                      onTap:       () => context.push(AppRoutes.studentQuizzes)
                          .then((_) => _loadData()),
                    ),
                    const SizedBox(height: AppSpacing.small),
                    _QuickActionCard(
                      icon:        Icons.auto_stories_outlined,
                      title:       l10n.quranMushaf,
                      subtitle:    l10n.browseReadMushaf,
                      accentColor: AppColors.primary,
                      onTap:       () => context.push(AppRoutes.mushaf),
                    ),


                    const SizedBox(height: AppSpacing.large),

                    // ── Recent sessions ──────────────────────────
                    if (_recentSessions.isNotEmpty) ...[
                      _SectionTitle(title: l10n.recentSessions),
                      const SizedBox(height: AppSpacing.small),
                      ..._recentSessions.map((s) => _StudentSessionCard(
                            session: s,
                            studySystem: _studentProfile?.studySystem ?? auth.profile?.studySystem ?? 'classes',
                          )),
                      const SizedBox(height: AppSpacing.large),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedScreen(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0F3A2E), // Rich dark spruce green
            Color(0xFF081C17), // Deep pine dark green
            Color(0xFF040C0A), // Extremely deep charcoal-green
          ],
        ),
      ),
      child: Stack(
        children: [
          // Ambient glowing blobs
          Positioned(
            top: -100,
            left: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFD700).withValues(alpha: 0.12),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
            ),
          ),
          // Main Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated/pulsing glowing Lock Icon
                        const _BlockedLockIcon(),
                        const SizedBox(height: 28),
                        // Title
                        Text(
                          l10n.accountBlocked,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        // Reason description
                        Text(
                          l10n.accountBlockedReason,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.70),
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 36),
                        // Primary CTA: Chat with Teacher inside app
                        if (_teacher != null) ...[
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, Color(0xFF1E6147)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                context.push(
                                  AppRoutes.chat,
                                  extra: {
                                    'partnerId': _teacher!.id,
                                    'partnerName': _teacher!.fullName,
                                  },
                                ).then((_) => _loadData());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                minimumSize: const Size(double.infinity, 54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.chat_bubble_outline, size: 22, color: Colors.white),
                              label: Text(
                                l10n.chatWithTeacher,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          // WhatsApp contact if phone is available
                          if (_teacher!.phone != null && _teacher!.phone!.isNotEmpty) ...[
                            OutlinedButton.icon(
                              onPressed: () {
                                final num = _teacher!.phone!.replaceAll(RegExp(r'[^0-9+]'), '');
                                launchUrl(
                                  Uri.parse('https://wa.me/$num'),
                                  mode: LaunchMode.externalApplication,
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF25D366),
                                side: const BorderSide(color: Color(0xFF25D366), width: 1.5),
                                minimumSize: const Size(double.infinity, 54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.chat_outlined, size: 22),
                              label: Text(
                                l10n.contactTeacher,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                        ],
                        // Status refresh action
                        TextButton.icon(
                          onPressed: () async {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.localeName == 'ar'
                                      ? 'جاري تحديث الحالة...'
                                      : l10n.localeName == 'tr'
                                          ? 'Durum güncelleniyor...'
                                          : 'Updating status...',
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                            await context.read<AuthProvider>().loadProfile();
                            await _loadData();
                          },
                          icon: const Icon(Icons.refresh, size: 20, color: Colors.white70),
                          label: Text(
                            l10n.localeName == 'ar'
                                ? 'تحديث الحالة'
                                : l10n.localeName == 'tr'
                                    ? 'Durumu Güncelle'
                                    : 'Refresh Status',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockedLockIcon extends StatefulWidget {
  const _BlockedLockIcon();

  @override
  State<_BlockedLockIcon> createState() => _BlockedLockIconState();
}

class _BlockedLockIconState extends State<_BlockedLockIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(
                  alpha: 0.25 * _animation.value,
                ),
                blurRadius: 30 * _animation.value,
                spreadRadius: 4 * _animation.value,
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: Colors.white,
              size: 52,
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4, height: 20,
          decoration: BoxDecoration(
            color:        AppColors.secondary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize:   17,
            fontWeight: FontWeight.bold,
            color:      AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   label;
  const _StatRow({required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

// ── Session card for student ──────────────────────────────────────────────────

class _StudentSessionCard extends StatefulWidget {
  const _StudentSessionCard({required this.session, required this.studySystem});
  final SessionModel session;
  final String studySystem;
  @override
  State<_StudentSessionCard> createState() => _StudentSessionCardState();
}

class _StudentSessionCardState extends State<_StudentSessionCard> {
  bool _expanded = false;

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n   = AppLocalizations.of(context);
    final s      = widget.session;
    final day    = s.sessionDate;
    final dateStr = '${day.day}/${day.month}/${day.year}';

    final IconData icon = switch (s.status) {
      'absent' => Icons.cancel_outlined,
      'late'   => Icons.access_time_outlined,
      _        => Icons.check_circle_outline,
    };
    final Color iconColor = switch (s.status) {
      'absent' => AppColors.error,
      'late'   => Colors.orange.shade800,
      _        => AppColors.success,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.small),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                s.topic?.isNotEmpty == true
                                    ? s.topic!
                                    : (s.status == 'absent'
                                        ? (l10n.localeName == 'ar' ? 'جلسة غياب' : 'Absence Session')
                                        : (s.status == 'late'
                                            ? (l10n.localeName == 'ar' ? 'جلسة تأخير' : 'Late Session')
                                            : l10n.attendanceSession)),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize:   14,
                                  color:      AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            StatusBadge(status: s.status),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              dateStr,
                              style: const TextStyle(
                                fontSize: 12,
                                color:    AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '•',
                              style: TextStyle(
                                fontSize: 12,
                                color:    AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              formatSessionDuration(s.deductedAmount, widget.studySystem, l10n.localeName),
                              style: const TextStyle(
                                fontSize: 12,
                                color:    AppColors.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.progressTrack),
                const SizedBox(height: 8),

                // 1. Topic Covered
                Builder(builder: (context) {
                  final topicVal = s.topic;
                  if (topicVal != null && topicVal.isNotEmpty) {
                    return _SDetailRow(
                      icon: Icons.subject,
                      label: l10n.topicCovered,
                      value: topicVal,
                    );
                  } else {
                    final noTopicText = switch (l10n.localeName) {
                      'ar' => 'لم يتم تسجيل موضوع لهذه الجلسة',
                      'tr' => 'Bu ders için konu kaydedilmedi',
                      _    => 'No topic registered for this session',
                    };
                    return _SDetailRow(
                      icon: Icons.subject,
                      label: l10n.topicCovered,
                      value: noTopicText,
                      isMuted: true,
                    );
                  }
                }),

                // 2. Homework (with file/quiz prefix parsing)
                Builder(builder: (context) {
                  final hw = s.homework;
                  if (hw != null && hw.isNotEmpty) {
                    final isFile = hw.startsWith('[ملف] ');
                    final isQuiz = hw.startsWith('[اختبار] ');
                    final hwIcon = isQuiz
                        ? Icons.quiz_outlined
                        : isFile
                            ? Icons.attach_file_outlined
                            : Icons.assignment_outlined;
                    final hwColor = isQuiz
                        ? AppColors.secondary
                        : (isFile ? AppColors.warning : AppColors.primary);
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
                    return _SDetailRow(
                      icon: hwIcon,
                      label: typeLabel,
                      value: displayText,
                      valueColor: hwColor,
                    );
                  } else {
                    final noHomeworkText = switch (l10n.localeName) {
                      'ar' => 'لا يوجد واجب مسجل لهذه الجلسة',
                      'tr' => 'Bu ders için ödev tanımlanmadı',
                      _    => 'No homework assigned for this session',
                    };
                    return _SDetailRow(
                      icon: Icons.assignment_outlined,
                      label: l10n.homework,
                      value: noHomeworkText,
                      isMuted: true,
                    );
                  }
                }),

                // 3. Absence Excuse (only for absent status)
                if (s.status == 'absent')
                  Builder(builder: (context) {
                    final excuse = s.absenceExcuse;
                    if (excuse != null && excuse.isNotEmpty) {
                      return _SDetailRow(
                        icon: Icons.info_outline,
                        label: l10n.absenceExcuse,
                        value: excuse,
                      );
                    } else {
                      final noExcuseText = switch (l10n.localeName) {
                        'ar' => 'لم يتم تسجيل عذر غياب',
                        'tr' => 'Katılmama mazereti bildirilmedi',
                        _    => 'No absence excuse registered',
                      };
                      return _SDetailRow(
                        icon: Icons.info_outline,
                        label: l10n.absenceExcuse,
                        value: noExcuseText,
                        isMuted: true,
                      );
                    }
                  }),

                // 4. Resource Url
                if (s.resourceUrl?.isNotEmpty ?? false)
                  GestureDetector(
                    onTap: () => _launch(s.resourceUrl!),
                    child: _SDetailRow(
                      icon:      Icons.link,
                      label:     l10n.resourceLabel,
                      value:     s.resourceUrl!,
                      valueColor: AppColors.primary,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SDetailRow extends StatelessWidget {
  const _SDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isMuted = false,
  });
  final IconData icon;
  final String   label;
  final String   value;
  final Color?   valueColor;
  final bool     isMuted;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon, 
              size: 15, 
              color: isMuted 
                  ? AppColors.textSecondary.withValues(alpha: 0.5) 
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              '$label: ',
              style: TextStyle(
                fontSize: 12, 
                color: isMuted 
                    ? AppColors.textSecondary.withValues(alpha: 0.7) 
                    : AppColors.textSecondary,
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize:   12,
                  color:      valueColor ?? (isMuted ? AppColors.textSecondary.withValues(alpha: 0.6) : AppColors.textPrimary),
                  decoration: valueColor != null ? TextDecoration.underline : null,
                  fontStyle: isMuted ? FontStyle.italic : null,
                ),
              ),
            ),
          ],
        ),
      );
}

class _QuickActionCard extends StatelessWidget {
  final IconData      icon;
  final String        title;
  final String        subtitle;
  final Color         accentColor;
  final VoidCallback? onTap;
  final String?       badge;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
    this.badge,
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
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color:        accentColor.withValues(alpha: onTap != null ? 0.12 : 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: onTap != null ? accentColor : AppColors.textSecondary, size: 24),
                ),
                if (badge != null)
                  Positioned(
                    top: -4, right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color:        AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color:      Colors.white,
                          fontSize:   10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize:   15,
                      color:      AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color:    badge != null ? accentColor : AppColors.textSecondary,
                      fontWeight: badge != null ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size:  14,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Upcoming lesson card ──────────────────────────────────────────────────────

class _UpcomingLessonCard extends StatelessWidget {
  const _UpcomingLessonCard({
    required this.schedule,
    required this.localEntries,
    required this.nextLabel,
    required this.fromOnline,
    required this.hasCountry,
    required this.postponements,
    this.onPostpone,
    this.onCancelPostpone,
  });

  final LessonScheduleModel?   schedule;
  final List<DayScheduleEntry> localEntries;
  final String?                nextLabel;
  final bool                   fromOnline;
  final bool                   hasCountry;
  final List<LessonPostponementModel> postponements;
  final VoidCallback?           onPostpone;
  final void Function(String)?  onCancelPostpone;

  String _fmt(int h, int m, String localeName) {
    final isAr = localeName == 'ar';
    final period = h < 12 ? (isAr ? 'ص' : 'AM') : (isAr ? 'م' : 'PM');
    final h12    = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:${m.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final days = _localizedDayNames[l10n.localeName] ?? _localizedDayNames['en']!;

    return Container(
      width:   double.infinity,
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
      child: schedule == null
          ? Row(
              children: [
                const Icon(Icons.schedule_outlined,
                    color: AppColors.textSecondary, size: 22),
                const SizedBox(width: 10),
                Text(
                  l10n.teacherNoSchedule,
                  style: const TextStyle(
                    color:    AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Postponed lessons listing
                if (postponements.isNotEmpty) ...[
                  ...postponements.map((p) {
                    final origFmt = DateFormat('EEEE hh:mm a', l10n.localeName);
                    final newFmt = DateFormat('yyyy/MM/dd hh:mm a', l10n.localeName);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.swap_calls_outlined, color: Colors.orange, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    l10n.localeName == 'ar' ? 'درس مؤجل' : 'Postponed Lesson',
                                    style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${l10n.localeName == 'ar' ? 'من:' : 'From:'} ${origFmt.format(p.originalDateTime.toLocal())}',
                                  style: const TextStyle(fontSize: 12, decoration: TextDecoration.lineThrough),
                                ),
                                Text(
                                  '${l10n.localeName == 'ar' ? 'إلى:' : 'To:'} ${newFmt.format(p.newDateTime.toLocal())}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange),
                                ),
                              ],
                            ),
                          ),
                          if (onCancelPostpone != null)
                            IconButton(
                              icon: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 20),
                              onPressed: () => onCancelPostpone!(p.id),
                            ),
                        ],
                      ),
                    );
                  }),
                ],

                // Next lesson highlight
                if (nextLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color:        AppColors.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_available_outlined,
                            color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.nextLesson,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary)),
                              Text(nextLabel!,
                                  style: const TextStyle(
                                      fontSize:   15,
                                      fontWeight: FontWeight.bold,
                                      color:      AppColors.primary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Per-day schedule list
                if (localEntries.isNotEmpty) ...[
                  ...localEntries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.secondary
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: AppColors.secondary
                                        .withValues(alpha: 0.35)),
                              ),
                              child: Text(
                                days[e.dayOfWeek] ?? '',
                                style: const TextStyle(
                                  fontSize:   12,
                                  color:      AppColors.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _fmt(e.hourUtc, e.minuteUtc, l10n.localeName),
                              style: const TextStyle(
                                fontSize:   16,
                                fontWeight: FontWeight.bold,
                                color:      AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      )),
                ] else if (!hasCountry) ...[
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.warning, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.selectCountryForTimezone,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ],

                // Action button to postpone
                if (localEntries.isNotEmpty && onPostpone != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onPostpone,
                      icon: const Icon(Icons.swap_calls_outlined, size: 16),
                      label: Text(l10n.localeName == 'ar' ? 'تأجيل الدرس' : 'Postpone Lesson'),
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

                // Online sync indicator
                if (fromOnline) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.cloud_done_outlined,
                          size: 13, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        l10n.timeSyncedOnline,
                        style: const TextStyle(fontSize: 11, color: AppColors.success),
                      ),
                    ],
                  ),
                ],
              ],
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
