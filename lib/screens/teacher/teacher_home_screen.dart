import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/router/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/profile_service.dart';
import '../../services/notification_service.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  final _profileService = ProfileService();
  final _client         = Supabase.instance.client;

  List<ProfileModel> _students    = [];
  bool   _loading                 = true;

  // Stats
  int _todaySessionsCount  = 0;
  int _unreadMessagesCount = 0;
  int _pendingHomeworks    = 0;

  @override
  void initState() {
    super.initState();
    _load();
    NotificationService().requestPermissions();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final auth      = context.read<AuthProvider>();
    final teacherId = auth.profile?.id ?? '';

    List<ProfileModel> students = [];
    int todayCount = 0;
    int unreadCount = 0;
    int pendingCount = 0;

    try {
      students = await _profileService.fetchStudents();

      // Count students whose lesson_schedule includes today (UTC weekday)
      final scheduleRows = await _client
          .from('lesson_schedules')
          .select('day_times')
          .eq('teacher_id', teacherId);

      final todayWeekday = DateTime.now().toUtc().weekday; // 1=Mon … 7=Sun
      for (final row in scheduleRows as List) {
        final dayTimes = (row['day_times'] as List?) ?? [];
        for (final dt in dayTimes) {
          if ((dt['day'] as num?)?.toInt() == todayWeekday) {
            todayCount++;
            break; // Count each student once
          }
        }
      }

      final unreadRows = await _client
          .from('chat_messages')
          .select('id')
          .eq('receiver_id', teacherId)
          .eq('is_read', false);
      unreadCount = (unreadRows as List).length;

      final pendingRows = await _client
          .from('homeworks')
          .select('id')
          .eq('teacher_id', teacherId)
          .eq('status', 'submitted');
      pendingCount = (pendingRows as List).length;

      // Cache the loaded data for offline usage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_teacher_students_$teacherId', jsonEncode(students.map((s) => s.toMap()).toList()));
      await prefs.setInt('cached_teacher_today_count_$teacherId', todayCount);
      await prefs.setInt('cached_teacher_unread_count_$teacherId', unreadCount);
      await prefs.setInt('cached_teacher_pending_count_$teacherId', pendingCount);

    } catch (e) {
      debugPrint("TeacherHomeScreen._load offline/network error: $e");
      // Attempt to load from offline cache
      try {
        final prefs = await SharedPreferences.getInstance();
        final cachedStudentsStr = prefs.getString('cached_teacher_students_$teacherId');
        if (cachedStudentsStr != null) {
          final decoded = jsonDecode(cachedStudentsStr) as List<dynamic>;
          students = decoded.map((s) => ProfileModel.fromMap(s as Map<String, dynamic>)).toList();
        }
        todayCount = prefs.getInt('cached_teacher_today_count_$teacherId') ?? 0;
        unreadCount = prefs.getInt('cached_teacher_unread_count_$teacherId') ?? 0;
        pendingCount = prefs.getInt('cached_teacher_pending_count_$teacherId') ?? 0;
      } catch (cacheErr) {
        debugPrint("TeacherHomeScreen._load offline cache read error: $cacheErr");
      }
    }

    if (!mounted) return;
    setState(() {
      _students             = students;
      _todaySessionsCount   = todayCount;
      _unreadMessagesCount  = unreadCount;
      _pendingHomeworks     = pendingCount;
      _loading              = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth      = context.watch<AuthProvider>();
    final teacherId = auth.profile?.id ?? '';
    final name      = auth.profile?.fullName ?? '';
    final l10n      = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: NavigationBar(
        selectedIndex:           0,
        backgroundColor:         AppColors.surface,
        indicatorColor:          AppColors.primary.withValues(alpha: 0.12),
        labelBehavior:           NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected:   (i) {
          if (i == 1) context.push(AppRoutes.studentList);
          if (i == 2) context.push(AppRoutes.teacherQuizzes);
          if (i == 3) context.push(AppRoutes.mushaf);
          if (i == 4) context.push(AppRoutes.settings);
        },
        destinations: [
          NavigationDestination(
            icon:         const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home, color: AppColors.primary),
            label:        l10n.teacherHome,
          ),
          NavigationDestination(
            icon:         const Icon(Icons.people_outline),
            selectedIcon: const Icon(Icons.people, color: AppColors.primary),
            label:        l10n.teacherStudents,
          ),
          NavigationDestination(
            icon:         const Icon(Icons.quiz_outlined),
            selectedIcon: const Icon(Icons.quiz, color: AppColors.primary),
            label:        l10n.teacherQuizzes,
          ),
          NavigationDestination(
            icon:         const Icon(Icons.auto_stories_outlined),
            selectedIcon: const Icon(Icons.auto_stories, color: AppColors.primary),
            label:        l10n.teacherMushaf,
          ),
          NavigationDestination(
            icon:         const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings, color: AppColors.primary),
            label:        l10n.teacherSettings,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push(AppRoutes.createStudent);
          _load();
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        icon:  const Icon(Icons.person_add_outlined),
        label: Text(l10n.newStudent,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // ── Header ─────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 170,
              pinned: true,
              backgroundColor: AppColors.primary,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined,
                      color: AppColors.surface),
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
                        children: [
                          // Avatar
                          Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(14),
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
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.welcomeTeacherPrefix,
                                  style: TextStyle(
                                    color: AppColors.surface.withValues(alpha: 0.70),
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  name.isNotEmpty ? name : (l10n.localeName == 'ar' ? 'المعلم' : l10n.localeName == 'tr' ? 'Öğretmen' : 'Teacher'),
                                  style: const TextStyle(
                                    color:      AppColors.surface,
                                    fontSize:   20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.secondary
                                      .withValues(alpha: 0.40)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.people,
                                    color: AppColors.secondary, size: 13),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.studentCount(_students.length),
                                  style: const TextStyle(
                                    color:      AppColors.secondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize:   11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Stats row ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: _loading
                  ? const SizedBox(
                      height: 90,
                      child: Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        children: [
                          _StatCard(
                            icon:    Icons.today_outlined,
                            color:   AppColors.primary,
                            value:   '$_todaySessionsCount',
                            label:   l10n.todaySessions,
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            icon:    Icons.chat_bubble_outline,
                            color:   const Color(0xFF9B59B6),
                            value:   '$_unreadMessagesCount',
                            label:   l10n.newMessages,
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            icon:    Icons.assignment_late_outlined,
                            color:   AppColors.warning,
                            value:   '$_pendingHomeworks',
                            label:   l10n.needsCorrection,
                          ),
                        ],
                      ),
                    ),
            ),

            // ── Quick actions grid ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(text: l10n.mainSections),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount:      2,
                      shrinkWrap:          true,
                      physics:             const NeverScrollableScrollPhysics(),
                      crossAxisSpacing:    12,
                      mainAxisSpacing:     12,
                      childAspectRatio:    1.25,
                      children: [
                        _QuickCard(
                          icon:    Icons.people_alt_outlined,
                          label:   l10n.teacherStudents,
                          color:   AppColors.primary,
                          onTap:   () => context.push(AppRoutes.studentList),
                        ),
                        _QuickCard(
                          icon:    Icons.assignment_outlined,
                          label:   l10n.homeworkInbox,
                          color:   const Color(0xFFE67E22),
                          badge:   _pendingHomeworks > 0
                              ? '$_pendingHomeworks'
                              : null,
                          onTap:   () async {
                            await context.push(AppRoutes.teacherInbox);
                            _load();
                          },
                        ),
                        _QuickCard(
                          icon:    Icons.quiz_outlined,
                          label:   l10n.quizBankTitle,
                          color:   const Color(0xFF2980B9),
                          onTap:   () => context.push(AppRoutes.teacherQuizzes),
                        ),
                        _QuickCard(
                          icon:    Icons.forum_outlined,
                          label:   l10n.communication,
                          color:   const Color(0xFF9B59B6),
                          badge:   _unreadMessagesCount > 0
                              ? '$_unreadMessagesCount'
                              : null,
                          onTap:   () async {
                            await context.push(AppRoutes.teacherMessages);
                            _load();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // --- Edit Academy Info Banner ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0F3A2E), // deep forest green
                        Color(0xFF1E6147), // lighter emerald green
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => context.push(AppRoutes.editAcademyInfo),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.settings_accessibility_rounded,
                                color: AppColors.secondary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.localeName == 'ar'
                                        ? 'لوحة التحكم بصفحة الزوار والترويج'
                                        : 'Academy Visitor Page & Promotion Control',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.localeName == 'ar'
                                        ? 'تعديل السيرة الذاتية، شرح البرنامج، ومقاطع يوتيوب الترويجية المعروضة لغير المسجلين'
                                        : 'Update biography, program features, and YouTube promo videos for guests',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Recent students ─────────────────────────────────────
            if (!_loading) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Row(
                    children: [
                      _SectionTitle(text: l10n.teacherStudents),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.studentList),
                        child: Text(
                          l10n.viewAll,
                          style: const TextStyle(
                              color: AppColors.primary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_students.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Icon(Icons.people_outline,
                            size: 48,
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.30)),
                        const SizedBox(height: 8),
                        Text(l10n.noStudentsRegistered,
                            style:
                                const TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final s = _students[i];
                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.small),
                          child: _StudentRow(
                            student: s,
                            teacherId: teacherId,
                          ),
                        );
                      },
                      childCount: _students.length > 5 ? 5 : _students.length,
                    ),
                  ),
                ),
            ],

            const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.large * 3)),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 4, height: 18,
            decoration: BoxDecoration(
              color:        AppColors.secondary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize:   16,
              color:      AppColors.textPrimary,
            ),
          ),
        ],
      );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   value;
  final String   label;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color:        AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color:      Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset:     const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color:        color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 8),
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
                style: const TextStyle(
                  fontSize: 10,
                  color:    AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

class _QuickCard extends StatelessWidget {
  final IconData  icon;
  final String    label;
  final Color     color;
  final String?   badge;
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) => Material(
        color:        Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap:        onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color:        AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color:      Colors.black.withValues(alpha: 0.07),
                  blurRadius: 10,
                  offset:     const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color:        color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(icon, color: color, size: 26),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize:   13,
                          color:      AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                // Badge
                if (badge != null)
                  Positioned(
                    top:   10,
                    left:  10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color:        AppColors.error,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color:      Colors.white,
                          fontSize:   11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}

class _StudentRow extends StatelessWidget {
  final ProfileModel student;
  final String       teacherId;

  const _StudentRow({required this.student, required this.teacherId});

  @override
  Widget build(BuildContext context) {
    final words    = student.fullName.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final initials = words.isNotEmpty ? words.take(2).map((w) => w[0]).join() : '؟';
    final l10n      = AppLocalizations.of(context);

    return Material(
      color:        Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: InkWell(
        onTap: () => context.push(AppRoutes.studentDetail, extra: student),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color:      AppColors.surface,
                    fontWeight: FontWeight.bold,
                    fontSize:   13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize:   14,
                        color:      AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _LevelBadge(l10n.studentLevelAbbr(student.level),
                            AppColors.primary.withValues(alpha: 0.10),
                            AppColors.primary),
                        const SizedBox(width: 4),
                        _LevelBadge(
                            student.studySystem == 'hours'
                                ? (Localizations.localeOf(context).languageCode == 'ar'
                                    ? 'س ${student.lessonInLevel}'
                                    : 'H ${student.lessonInLevel}')
                                : l10n.studentLessonAbbr(student.lessonInLevel.toInt()),
                            AppColors.secondary.withValues(alpha: 0.15),
                            AppColors.secondary),
                      ],
                    ),
                  ],
                ),
              ),
              // Action icons
              _SmallIcon(
                icon:  Icons.check_circle_outline,
                color: AppColors.success,
                onTap: () => context.push(
                  AppRoutes.attendance,
                  extra: {
                    'studentId':   student.id,
                    'studentName': student.fullName,
                    'teacherId':   teacherId,
                  },
                ),
              ),
              _SmallIcon(
                icon:  Icons.assignment_outlined,
                color: AppColors.warning,
                onTap: () => context.push(
                  AppRoutes.teacherHomework,
                  extra: {
                    'studentId':   student.id,
                    'studentName': student.fullName,
                    'teacherId':   teacherId,
                  },
                ),
              ),
              _SmallIcon(
                icon:  Icons.chat_bubble_outline,
                color: const Color(0xFF9B59B6),
                onTap: () => context.push(
                  AppRoutes.chat,
                  extra: {
                    'partnerId':   student.id,
                    'partnerName': student.fullName,
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final String text;
  final Color  bg;
  final Color  fg;
  const _LevelBadge(this.text, this.bg, this.fg);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color:        bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: TextStyle(
              fontSize: 10, color: fg, fontWeight: FontWeight.bold),
        ),
      );
}

class _SmallIcon extends StatelessWidget {
  final IconData     icon;
  final Color        color;
  final VoidCallback onTap;
  const _SmallIcon(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap:        onTap,
        borderRadius: BorderRadius.circular(8),
        child:
            Padding(padding: const EdgeInsets.all(6), child: Icon(icon, color: color, size: 20)),
      );
}
