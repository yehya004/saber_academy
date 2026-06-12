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

  List<_ConvThread> _threads = [];
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

    final students = await _profileService.fetchStudents();

    // For each student, fetch last message and unread count in parallel
    final threadFutures = students.map((s) => _buildThread(s, teacherId));
    final threads       = await Future.wait(threadFutures);

    // Sort: threads with messages first (newest → oldest), then no-message students
    threads.sort((a, b) {
      if (a.lastMessageAt == null && b.lastMessageAt == null) return 0;
      if (a.lastMessageAt == null) return 1;
      if (b.lastMessageAt == null) return -1;
      return b.lastMessageAt!.compareTo(a.lastMessageAt!);
    });

    if (!mounted) return;
    setState(() {
      _threads = threads;
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
    final totalUnread =
        _threads.fold<int>(0, (s, t) => s + t.unreadCount);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _threads.isEmpty
              ? _buildEmpty(l10n)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _threads.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      indent: 72,
                      color: Color(0xFFEEEEEE),
                    ),
                    itemBuilder: (ctx, i) {
                      final t = _threads[i];
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
                ),
    );
  }

  Widget _buildEmpty(AppLocalizations l10n) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.forum_outlined,
                size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              l10n.noStudentsRegistered,
              style: const TextStyle(
                  fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
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
