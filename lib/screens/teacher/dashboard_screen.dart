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

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final _profileService = ProfileService();
  final _searchCtrl     = TextEditingController();

  List<ProfileModel> _students = [];
  List<ProfileModel> _filtered = [];
  bool _loading = true;

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
      _filtered = q.isEmpty
          ? _students
          : _students
              .where((s) => s.fullName.toLowerCase().contains(q.toLowerCase()))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth      = context.watch<AuthProvider>();
    final l10n      = AppLocalizations.of(context);
    final name      = auth.profile?.fullName ?? '';
    final teacherId = auth.profile?.id ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push(AppRoutes.createStudent);
          _load(); // refresh list after returning
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
        icon:  const Icon(Icons.person_add_outlined),
        label: Text(
          l10n.newStudent,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex:           0,
        backgroundColor:         AppColors.surface,
        indicatorColor:          AppColors.primary.withValues(alpha: 0.12),
        labelBehavior:           NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected:   (i) {
          if (i == 1) context.push(AppRoutes.teacherQuizzes);
          if (i == 2) context.push(AppRoutes.settings);
        },
        destinations: [
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
            icon:         const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings, color: AppColors.primary),
            label:        l10n.teacherSettings,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // ── Header banner ──────────────────────────────────────
            SliverAppBar(
              expandedHeight: 160,
              pinned:         true,
              backgroundColor: AppColors.primary,
              actions: [
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
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Avatar initials
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color:        AppColors.secondary.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '؟',
                                style: const TextStyle(
                                  color:      AppColors.secondary,
                                  fontSize:   22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.medium),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.welcomeTeacherPrefix,
                                  style: TextStyle(
                                    color:    AppColors.surface.withValues(alpha: 0.70),
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  name.isNotEmpty ? name : l10n.dashboard,
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
                          // Student count badge
                          if (!_loading)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color:  AppColors.secondary.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.secondary.withValues(alpha: 0.40),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.people, color: AppColors.secondary, size: 14),
                                  const SizedBox(width: 5),
                                  Text(
                                    l10n.studentCount(_students.length),
                                    style: const TextStyle(
                                      color:      AppColors.secondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize:   12,
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

            // ── Search bar ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged:  _onSearch,
                  decoration: InputDecoration(
                    hintText:  l10n.searchForStudent,
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    filled:    true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:  BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:  BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 0,
                    ),
                  ),
                ),
              ),
            ),

            // ── Quick action: Quiz bank ─────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: GestureDetector(
                  onTap: () => context.push(AppRoutes.teacherQuizzes),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color:        AppColors.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.18)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.quiz_outlined,
                            color: AppColors.primary, size: 22),
                        const SizedBox(width: 12),
                        Text(
                          l10n.quizBankTitle,
                          style: const TextStyle(
                              color:      AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize:   14),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            size: 14, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Section label ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
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
                      l10n.studentListTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize:   16,
                        color:      AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Student list ────────────────────────────────────────
            if (_loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              )
            else if (_filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: AppColors.textSecondary.withValues(alpha: 0.30),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _students.isEmpty
                            ? l10n.noStudentsRegistered
                            : l10n.noResults,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final s = _filtered[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.small),
                        child: _StudentCard(
                          student: s,
                          onViewDetail: () => context.push(
                            AppRoutes.studentDetail,
                            extra: s,
                          ),
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
                        ),
                      );
                    },
                    childCount: _filtered.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.large)),
          ],
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final ProfileModel student;
  final VoidCallback onViewDetail;
  final VoidCallback onAttendance;
  final VoidCallback onHomework;
  final VoidCallback onChat;

  const _StudentCard({
    required this.student,
    required this.onViewDetail,
    required this.onAttendance,
    required this.onHomework,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final words    = student.fullName.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final initials = words.isNotEmpty ? words.take(2).map((w) => w[0]).join() : '؟';
    final l10n      = AppLocalizations.of(context);

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
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.medium, vertical: 12,
            ),
            child: Row(
              children: [
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
                const SizedBox(width: AppSpacing.medium),
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
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color:        AppColors.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              l10n.studentLevelAbbr(student.level),
                              style: const TextStyle(
                                fontSize:   10,
                                color:      AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color:        AppColors.secondary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              student.studySystem == 'hours'
                                  ? (Localizations.localeOf(context).languageCode == 'ar'
                                      ? 'س ${student.lessonInLevel}'
                                      : 'H ${student.lessonInLevel}')
                                  : l10n.studentLessonAbbr(student.lessonInLevel.toInt()),
                              style: const TextStyle(
                                fontSize:   10,
                                color:      AppColors.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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

class _ActionIcon extends StatelessWidget {
  final IconData     icon;
  final Color        color;
  final String       tooltip;
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
