import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../models/profile_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/profile_service.dart';

/// Shows all students as conversation threads sorted by last message time.
/// Each row shows unread message count as a badge.
class TeacherMessagesScreen extends StatefulWidget {
  const TeacherMessagesScreen({super.key});

  @override
  State<TeacherMessagesScreen> createState() =>
      _TeacherMessagesScreenState();
}

class _TeacherMessagesScreenState extends State<TeacherMessagesScreen> {
  final _profileService = ProfileService();
  final _client         = Supabase.instance.client;

  List<_ConvThread> _studentThreads = [];
  List<_ConvThread> _guestThreads = [];
  bool              _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final auth      = context.read<AuthProvider>();
    final teacherId = auth.profile?.id ?? '';

    // Fetch both regular students and guest users in parallel
    final results = await Future.wait([
      _profileService.fetchStudents(),
      _profileService.fetchGuests(),
    ]);

    final students = results[0];
    final guests   = results[1];

    // For each profile, fetch last message and unread count in parallel
    final studentThreadFutures = students.map((s) => _buildThread(s, teacherId));
    final guestThreadFutures   = guests.map((s) => _buildThread(s, teacherId));

    final studentThreads = await Future.wait(studentThreadFutures);
    final guestThreads   = await Future.wait(guestThreadFutures);

    // Helper function to sort threads: newest message first
    void sortThreads(List<_ConvThread> list) {
      list.sort((a, b) {
        if (a.lastMessageAt == null && b.lastMessageAt == null) return 0;
        if (a.lastMessageAt == null) return 1;
        if (b.lastMessageAt == null) return -1;
        return b.lastMessageAt!.compareTo(a.lastMessageAt!);
      });
    }

    sortThreads(studentThreads);
    sortThreads(guestThreads);

    if (!mounted) return;
    setState(() {
      _studentThreads = studentThreads;
      _guestThreads   = guestThreads;
      _loading = false;
    });
  }

  Future<_ConvThread> _buildThread(
      ProfileModel student, String teacherId) async {
    // Last message in either direction
    final msgs = await _client
        .from('chat_messages')
        .select('message_text, created_at, sender_id, is_read')
        .or(
          'and(sender_id.eq.${student.id},receiver_id.eq.$teacherId),'
          'and(sender_id.eq.$teacherId,receiver_id.eq.${student.id})',
        )
        .order('created_at', ascending: false)
        .limit(1);

    // Unread count (messages from student to teacher that are unread)
    final unreadResp = await _client
        .from('chat_messages')
        .select('id')
        .eq('sender_id',   student.id)
        .eq('receiver_id', teacherId)
        .eq('is_read',     false);

    final lastMsg     = msgs.isNotEmpty
        ? msgs.first
        : null;
    final unreadCount = unreadResp.length;

    return _ConvThread(
      student:       student,
      lastMessage:   lastMsg?['message_text'] as String?,
      lastMessageAt: lastMsg != null
          ? DateTime.parse(lastMsg['created_at'] as String)
          : null,
      isMine: lastMsg != null && lastMsg['sender_id'] == teacherId,
      unreadCount: unreadCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentsUnread = _studentThreads.fold<int>(0, (s, t) => s + t.unreadCount);
    final guestsUnread   = _guestThreads.fold<int>(0, (s, t) => s + t.unreadCount);
    final totalUnread    = studentsUnread + guestsUnread;
    final l10n = AppLocalizations.of(context);

    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isTr = Localizations.localeOf(context).languageCode == 'tr';

    final studentsLabel = isAr ? 'الطلاب' : (isTr ? 'Öğrenciler' : 'Students');
    final guestsLabel   = isAr ? 'الزوار' : (isTr ? 'Ziyaretçiler' : 'Guests');

    Widget buildBadge(int count) {
      if (count <= 0) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    final appBar = AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.surface,
      title: Row(
        children: [
          Text(
            l10n.communication,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.surface),
          ),
          const SizedBox(width: 8),
          if (!_loading && totalUnread > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color:        AppColors.error,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$totalUnread',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      bottom: TabBar(
        indicatorColor: AppColors.secondary,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(studentsLabel),
                buildBadge(studentsUnread),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(guestsLabel),
                buildBadge(guestsUnread),
              ],
            ),
          ),
        ],
      ),
    );

    Widget buildThreadList(List<_ConvThread> threads, String emptyMsg) {
      if (threads.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.forum_outlined, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(
                emptyMsg,
                style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      }
      return RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: threads.length,
          separatorBuilder: (_, __) => const Divider(
            height: 1,
            indent: 72,
            color: Color(0xFFEEEEEE),
          ),
          itemBuilder: (ctx, i) {
            final t = threads[i];
            return _ThreadTile(
              thread: t,
              onTap: () async {
                await context.push(
                  AppRoutes.chat,
                  extra: {
                    'partnerId':   t.student.id,
                    'partnerName': t.student.fullName,
                  },
                );
                _load(); // refresh unread counts after returning
              },
            );
          },
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: appBar,
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : TabBarView(
                children: [
                  buildThreadList(
                    _studentThreads,
                    l10n.noStudentsRegistered,
                  ),
                  buildThreadList(
                    _guestThreads,
                    isAr ? 'لا يوجد زوار حالياً' : (isTr ? 'Henüz ziyaretçi yok' : 'No guest messages yet'),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _ConvThread {
  final ProfileModel student;
  final String?      lastMessage;
  final DateTime?    lastMessageAt;
  final bool         isMine;
  final int          unreadCount;

  const _ConvThread({
    required this.student,
    this.lastMessage,
    this.lastMessageAt,
    this.isMine = false,
    required this.unreadCount,
  });
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _ThreadTile extends StatelessWidget {
  final _ConvThread  thread;
  final VoidCallback onTap;

  const _ThreadTile({required this.thread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s       = thread.student;
    final l10n    = AppLocalizations.of(context);
    final words   = s.fullName.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final initials = words.isNotEmpty ? words.take(2).map((w) => w[0]).join() : '؟';

    // Time label
    String timeLabel = '';
    if (thread.lastMessageAt != null) {
      final diff = DateTime.now().difference(thread.lastMessageAt!);
      if (diff.inDays > 0) {
        timeLabel = l10n.daysAbbr(diff.inDays);
      } else if (diff.inHours > 0) {
        timeLabel = l10n.hoursAbbr(diff.inHours);
      } else {
        timeLabel = l10n.minutesAbbr(diff.inMinutes);
      }
    }

    final hasUnread = thread.unreadCount > 0;

    return Material(
      color: hasUnread
          ? AppColors.primary.withValues(alpha: 0.04)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar with online indicator placeholder
              Stack(
                children: [
                  CircleAvatar(
                    radius:          26,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color:      AppColors.surface,
                        fontWeight: FontWeight.bold,
                        fontSize:   15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.fullName,
                      style: TextStyle(
                        fontWeight: hasUnread
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 15,
                        color:    AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (thread.isMine)
                          const Padding(
                            padding: EdgeInsets.only(left: 3),
                            child: Icon(Icons.done_all,
                                size: 13, color: AppColors.primary),
                          ),
                        Expanded(
                          child: Text(
                            thread.lastMessage ?? l10n.startChatConversation,
                            maxLines:  1,
                            overflow:  TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: hasUnread
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontWeight: hasUnread
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (timeLabel.isNotEmpty)
                    Text(
                      timeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: hasUnread
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: hasUnread
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  const SizedBox(height: 5),
                  if (hasUnread)
                    Container(
                      width:  22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color:  AppColors.primary,
                        shape:  BoxShape.circle,
                      ),
                      child: Text(
                        thread.unreadCount > 99
                            ? '99+'
                            : '${thread.unreadCount}',
                        style: const TextStyle(
                          color:      Colors.white,
                          fontSize:   10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 22),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
