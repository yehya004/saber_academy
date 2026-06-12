import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../l10n/app_localizations.dart';
import '../../models/chat_message_model.dart';
import '../../models/profile_model.dart';
import '../../services/chat_service.dart';
import '../../services/profile_service.dart';
import '../../services/telegram_storage_service.dart';
import '../../widgets/chat_bubble.dart';
import 'image_editor_screen.dart';

class ChatScreen extends StatefulWidget {
  final String partnerId;
  final String partnerName;

  const ChatScreen({
    super.key,
    required this.partnerId,
    required this.partnerName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatService = ChatService();
  final _telegramService = TelegramStorageService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();

  StreamSubscription<List<ChatMessageModel>>? _msgSub;
  List<ChatMessageModel> _messages = [];
  bool _loading = true;
  bool _hasError = false;
  bool _sendingImage = false;
  bool _sendingFile = false;
  late String _myId;
  ProfileModel? _partnerProfile;

  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isRecordingLocked = false;
  int _recordDuration = 0;
  Timer? _recordTimer;
  List<double> _amplitudes = [];
  Timer? _amplitudeTimer;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _myId = Supabase.instance.client.auth.currentUser?.id ?? '';
    _loadCachedMessages();
    _subscribeToMessages();
    _startPolling();
    _markInitialRead();
    _loadPartnerProfile();
    _messageController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadPartnerProfile() async {
    try {
      final profile = await ProfileService().fetchStudentById(widget.partnerId);
      if (mounted) {
        setState(() {
          _partnerProfile = profile;
        });
      }
    } catch (e) {
      debugPrint('Error loading partner profile: $e');
    }
  }

  Future<void> _markInitialRead() async {
    try {
      if (_myId.isNotEmpty) {
        await _chatService.markMessagesAsRead(
          receiverId: _myId,
          senderId: widget.partnerId,
        );
      }
    } catch (e) {
      debugPrint('Error marking initial messages as read: $e');
    }
  }

  void _subscribeToMessages() {
    _msgSub?.cancel();
    _msgSub = _chatService
        .messageStream(userId: _myId, partnerId: widget.partnerId)
        .listen(
      (msgs) {
        final newMessages = msgs.length > _messages.length;
        if (mounted) {
          setState(() {
            _messages = msgs;
            _loading = false;
            _hasError = false;
          });
          if (newMessages) _scrollToBottom();
        }
        _chatService.markMessagesAsRead(
          receiverId: _myId,
          senderId: widget.partnerId,
        ).catchError((e) {
          debugPrint('Error marking messages as read in stream: $e');
        });
      },
      onError: (Object error, StackTrace st) {
        debugPrint('ChatScreen stream error: $error\n$st');
        if (mounted) {
          setState(() {
            _loading = false;
            _hasError = _messages.isEmpty;
          });
        }
      },
    );
  }

  Future<void> _loadCachedMessages() async {
    try {
      final cached = await _chatService.getCachedMessages(
        userId: _myId,
        partnerId: widget.partnerId,
      );
      if (cached.isNotEmpty && _messages.isEmpty && mounted) {
        setState(() {
          _messages = cached;
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error loading cached messages: $e');
    }
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _recordTimer?.cancel();
    _amplitudeTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      await _fetchMessagesSilently();
    });
  }

  Future<void> _fetchMessagesSilently() async {
    try {
      final msgs = await _chatService.fetchMessages(
        userId: _myId,
        partnerId: widget.partnerId,
      );
      if (mounted) {
        // Only update state if there is a difference to prevent unnecessary re-builds/flicker
        bool isChanged = msgs.length != _messages.length;
        if (!isChanged && msgs.isNotEmpty && _messages.isNotEmpty) {
          isChanged = msgs.last.id != _messages.last.id;
        }
        if (isChanged) {
          setState(() {
            _messages = msgs;
            _loading = false;
            _hasError = false;
          });
          _scrollToBottom();
          // Mark as read when new messages are loaded via poll
          _chatService.markMessagesAsRead(
            receiverId: _myId,
            senderId: widget.partnerId,
          ).catchError((e) {
            debugPrint('Error marking messages as read in poll: $e');
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching messages silently: $e');
    }
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    try {
      await _chatService.sendMessage(
        senderId: _myId,
        receiverId: widget.partnerId,
        messageText: text,
      );
      await _fetchMessagesSilently();
    } catch (e) {
      debugPrint("Error sending message: $e");
    }
  }

  Future<void> _sendImage() async {
    final l10n = AppLocalizations.of(context);
    
    String? path;
    try {
      if (!kIsWeb && Platform.isWindows) {
        final result = await FilePicker.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );
        if (result != null && result.files.isNotEmpty) {
          path = result.files.single.path;
        }
      } else {
        final picked = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 70,
        );
        if (picked != null) {
          path = picked.path;
        }
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
    
    if (path == null) return;

    if (!mounted) return;
    final File? editedFile = await Navigator.of(context).push<File?>(
      MaterialPageRoute(
        builder: (_) => ImageEditorScreen(imageFile: File(path!)),
      ),
    );
    if (editedFile == null) return;

    setState(() => _sendingImage = true);
    try {
      final file = editedFile;
      // Upload to Telegram only (bypass Supabase Storage)
      final telegramFileId = await _telegramService.uploadFile(
        file,
        caption: 'صورة في المحادثة من $_myId إلى ${widget.partnerId} — ${DateTime.now().toIso8601String()}',
      );

      await _chatService.sendMessage(
        senderId: _myId,
        receiverId: widget.partnerId,
        messageText: '',
        fileName: file.path.split(kIsWeb ? '/' : Platform.pathSeparator).last,
        telegramFileId: telegramFileId,
      );
      await _fetchMessagesSilently();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.sendImageFailed(e.toString())),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingImage = false);
    }
  }

  Future<void> _sendFile() async {
    final l10n = AppLocalizations.of(context);
    final result = await FilePicker.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;

    final fileInfo = result.files.single;
    final path = fileInfo.path;
    if (path == null) return;

    // Enforce 10 MB size limit
    if (fileInfo.size > 10 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.fileSizeLimitError),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _sendingFile = true);
    try {
      final file = File(path);
      // Upload to Telegram only (bypass Supabase Storage)
      final telegramFileId = await _telegramService.uploadFile(
        file,
        caption: 'ملف في المحادثة (${fileInfo.name}) من $_myId إلى ${widget.partnerId} — ${DateTime.now().toIso8601String()}',
      );

      await _chatService.sendMessage(
        senderId: _myId,
        receiverId: widget.partnerId,
        messageText: '',
        fileName: fileInfo.name,
        telegramFileId: telegramFileId,
      );
      await _fetchMessagesSilently();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.fileUploadFailed(e.toString())),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingFile = false);
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/audio_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
        
        setState(() {
          _isRecording = true;
          _isRecordingLocked = false;
          _recordDuration = 0;
          _amplitudes = [];
        });
        
        _recordTimer?.cancel();
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _recordDuration++;
            });
          }
        });

        _amplitudeTimer?.cancel();
        _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
          try {
            final amp = await _audioRecorder.getAmplitude();
            final double db = amp.current;
            // map db (typically -60 to 0) to 0.0 to 1.0
            double normalized = (db + 60.0) / 60.0;
            if (normalized < 0.0) normalized = 0.0;
            if (normalized > 1.0) normalized = 1.0;
            if (mounted) {
              setState(() {
                _amplitudes.add(normalized);
                if (_amplitudes.length > 25) {
                  _amplitudes.removeAt(0);
                }
              });
            }
          } catch (_) {}
        });
      }
    } catch (e) {
      debugPrint("Error starting voice recording: $e");
    }
  }

  Future<void> _cancelRecording() async {
    try {
      _recordTimer?.cancel();
      _amplitudeTimer?.cancel();
      _amplitudes.clear();
      await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _isRecordingLocked = false;
        _recordDuration = 0;
      });
    } catch (e) {
      debugPrint("Error cancelling voice recording: $e");
    }
  }

  Future<void> _stopAndSendRecording() async {
    final l10n = AppLocalizations.of(context);
    try {
      _recordTimer?.cancel();
      _amplitudeTimer?.cancel();
      _amplitudes.clear();
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _isRecordingLocked = false;
      });

      if (path == null) return;
      final file = File(path);
      if (!file.existsSync()) return;

      final size = file.lengthSync();
      if (size > 10 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.fileSizeLimitError),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      setState(() => _sendingFile = true);
      // Upload to Telegram only (bypass Supabase Storage)
      final telegramFileId = await _telegramService.uploadFile(
        file,
        caption: 'ريكورد صوتي في المحادثة من $_myId إلى ${widget.partnerId} — ${DateTime.now().toIso8601String()}',
      );

      await _chatService.sendMessage(
        senderId: _myId,
        receiverId: widget.partnerId,
        messageText: '',
        fileName: 'Voice Note.m4a',
        telegramFileId: telegramFileId,
      );
      await _fetchMessagesSilently();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.fileUploadFailed(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _sendingFile = false;
          _isRecordingLocked = false;
          _recordDuration = 0;
        });
      }
    }
  }

  void _confirmDeleteMessage(ChatMessageModel msg) {
    if (msg.isDeleted || msg.senderId != _myId) return;

    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isTr = Localizations.localeOf(context).languageCode == 'tr';

    final title = isAr ? 'حذف الرسالة' : (isTr ? 'Mesajı Sil' : 'Delete Message');
    final content = isAr
        ? 'هل أنت متأكد من رغبتك في حذف هذه الرسالة؟ سيظهر للجميع أنه تم إزالتها.'
        : (isTr
            ? 'Bu mesajı silmek istediğinizden emin misiniz? Herkes için kaldırıldığı gösterilecek.'
            : 'Are you sure you want to delete this message? It will show as removed for everyone.');
    final deleteTxt = isAr ? 'حذف' : (isTr ? 'Sil' : 'Delete');
    final cancelTxt = isAr ? 'إلغاء' : (isTr ? 'İptal' : 'Cancel');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(cancelTxt, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await _chatService.deleteMessage(msg.id);
                await _fetchMessagesSilently();
              } catch (e) {
                debugPrint('Error deleting message: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(deleteTxt),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(ChatMessageModel msg) {
    if (msg.isDeleted) return;
    final isMine = msg.senderId == _myId;

    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isTr = Localizations.localeOf(context).languageCode == 'tr';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              if (msg.messageText.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.copy_rounded, color: AppColors.primary),
                  title: Text(isAr ? 'نسخ النص' : (isTr ? 'Metni Kopyala' : 'Copy Text')),
                  onTap: () {
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(text: msg.messageText));
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text(isAr ? 'تم نسخ النص' : (isTr ? 'Metin kopyalandı' : 'Text copied')),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              if (isMine)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  title: Text(
                    msg.telegramFileId != null || msg.imageUrl != null || msg.fileUrl != null
                        ? (isAr ? 'حذف الملف' : (isTr ? 'Dosyayı Sil' : 'Delete File'))
                        : (isAr ? 'حذف الرسالة' : (isTr ? 'Mesajı Sil' : 'Delete Message')),
                    style: const TextStyle(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteMessage(msg);
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              backgroundImage: _partnerProfile?.avatarUrl != null && _partnerProfile!.avatarUrl!.isNotEmpty
                  ? NetworkImage(_partnerProfile!.avatarUrl!)
                  : null,
              child: _partnerProfile?.avatarUrl == null || _partnerProfile!.avatarUrl!.isEmpty
                  ? const Icon(Icons.person, color: AppColors.surface, size: 20)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.partnerName,
                style: AppTextStyles.heading1.copyWith(color: AppColors.surface),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.surface),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _hasError
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wifi_off_rounded,
                                size: 48, color: AppColors.textSecondary),
                            const SizedBox(height: 12),
                            Text(
                              l10n.failedToLoadMessages,
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _loading = true;
                                  _hasError = false;
                                });
                                _subscribeToMessages();
                              },
                              icon: const Icon(Icons.refresh),
                              label: Text(l10n.retryButton),
                            ),
                          ],
                        ),
                      )
                    : _messages.isEmpty
                        ? Center(
                            child: Text(
                              l10n.startChatConversation,
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.small),
                            itemCount: _messages.length,
                            itemBuilder: (_, i) {
                              final message = _messages[i];
                              return GestureDetector(
                                onLongPress: () => _showMessageOptions(message),
                                child: ChatBubble(
                                  message: message,
                                  isMine: message.senderId == _myId,
                                ),
                              );
                            },
                          ),
          ),
          _MessageInputBar(
            controller: _messageController,
            sendingImage: _sendingImage,
            sendingFile: _sendingFile,
            isRecording: _isRecording,
            isRecordingLocked: _isRecordingLocked,
            recordDuration: _recordDuration,
            amplitudes: _amplitudes,
            onSend: _send,
            onPickImage: _sendImage,
            onPickFile: _sendFile,
            onStartRecord: _startRecording,
            onCancelRecord: _cancelRecording,
            onStopAndSendRecord: _stopAndSendRecording,
            onLockChanged: (val) {
              setState(() {
                _isRecordingLocked = val;
              });
            },
          ),
        ],
      ),
    );
  }
}

class _MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sendingImage;
  final bool sendingFile;
  final bool isRecording;
  final bool isRecordingLocked;
  final int recordDuration;
  final List<double> amplitudes;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final VoidCallback onPickFile;
  final VoidCallback onStartRecord;
  final VoidCallback onCancelRecord;
  final VoidCallback onStopAndSendRecord;
  final ValueSetter<bool> onLockChanged;

  const _MessageInputBar({
    required this.controller,
    required this.sendingImage,
    required this.sendingFile,
    required this.isRecording,
    required this.isRecordingLocked,
    required this.recordDuration,
    required this.amplitudes,
    required this.onSend,
    required this.onPickImage,
    required this.onPickFile,
    required this.onStartRecord,
    required this.onCancelRecord,
    required this.onStopAndSendRecord,
    required this.onLockChanged,
  });

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: AppSpacing.small,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.progressTrack)),
      ),
      child: isRecording
          ? Row(
              children: [
                const SizedBox(width: 8),
                const _PulsingRecordIcon(),
                const SizedBox(width: 8),
                Text(
                  '${l10n.localeName == 'ar' ? 'تسجيل' : (l10n.localeName == 'tr' ? 'Kaydediliyor' : 'Recording')} ${_formatDuration(recordDuration)}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: isRecordingLocked
                        ? _AudioWaveVisualizer(amplitudes: amplitudes)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.arrow_upward, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                l10n.localeName == 'ar'
                                    ? 'اسحب للأعلى للقفل'
                                    : (l10n.localeName == 'tr'
                                        ? 'Kilitlemek için yukarı kaydırın'
                                        : 'Slide up to lock'),
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                  ),
                ),
                if (isRecordingLocked) ...[
                  IconButton(
                    onPressed: onCancelRecord,
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                    tooltip: l10n.cancel,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onStopAndSendRecord,
                    icon: const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 28),
                    tooltip: l10n.localeName == 'ar' ? 'إرسال' : (l10n.localeName == 'tr' ? 'Gönder' : 'Send'),
                  ),
                ] else ...[
                  const SizedBox(width: 12),
                  Text(
                    l10n.localeName == 'ar' ? 'أفلت للإرسال' : (l10n.localeName == 'tr' ? 'Bırak gönder' : 'Release to send'),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                ],
              ],
            )
          : Row(
              children: [
                // File picker button
                if (sendingFile)
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else
                  IconButton(
                    onPressed: onPickFile,
                    icon: const Icon(Icons.attach_file_rounded),
                    color: AppColors.primary,
                    tooltip: l10n.sendFileTooltip,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                const SizedBox(width: 4),
                // Image picker button
                if (sendingImage)
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else
                  IconButton(
                    onPressed: onPickImage,
                    icon: const Icon(Icons.image_outlined),
                    color: AppColors.primary,
                    tooltip: l10n.sendImageTooltip,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: l10n.typeMessage,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.medium,
                        vertical: 10,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                const SizedBox(width: 8),
                controller.text.trim().isEmpty
                    ? _RecordingButton(
                        onStart: onStartRecord,
                        onCancel: onCancelRecord,
                        onStopAndSend: onStopAndSendRecord,
                        onLockChanged: onLockChanged,
                      )
                    : GestureDetector(
                        onTap: onSend,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.send_rounded,
                              color: AppColors.surface, size: 20),
                        ),
                      ),
              ],
            ),
    );
  }
}

class _AudioWaveVisualizer extends StatelessWidget {
  final List<double> amplitudes;

  const _AudioWaveVisualizer({required this.amplitudes});

  @override
  Widget build(BuildContext context) {
    // Show 15 bars
    final displayAmps = List<double>.from(amplitudes);
    while (displayAmps.length < 15) {
      displayAmps.insert(0, 0.05); // fill with default small values
    }
    // Take the last 15
    final finalAmps = displayAmps.sublist(displayAmps.length - 15);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: finalAmps.map((amp) {
        // Height between 4 and 32
        final height = 4.0 + (amp * 28.0);
        return Container(
          width: 3,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }).toList(),
    );
  }
}

class _PulsingRecordIcon extends StatefulWidget {
  const _PulsingRecordIcon();

  @override
  State<_PulsingRecordIcon> createState() => _PulsingRecordIconState();
}

class _PulsingRecordIconState extends State<_PulsingRecordIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: const Icon(Icons.fiber_manual_record, color: AppColors.error, size: 16),
    );
  }
}

class _RecordingButton extends StatefulWidget {
  final VoidCallback onStart;
  final VoidCallback onCancel;
  final VoidCallback onStopAndSend;
  final ValueSetter<bool> onLockChanged;

  const _RecordingButton({
    required this.onStart,
    required this.onCancel,
    required this.onStopAndSend,
    required this.onLockChanged,
  });

  @override
  State<_RecordingButton> createState() => _RecordingButtonState();
}

class _RecordingButtonState extends State<_RecordingButton> {
  double _dyStart = 0.0;
  bool _isLocked = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (details) {
        _dyStart = details.globalPosition.dy;
        setState(() {
          _isLocked = false;
        });
        widget.onStart();
      },
      onLongPressMoveUpdate: (details) {
        if (_isLocked) return;
        final dyCurrent = details.globalPosition.dy;
        final dragDistance = _dyStart - dyCurrent; // positive when dragging up
        if (dragDistance > 60) {
          setState(() {
            _isLocked = true;
          });
          widget.onLockChanged(true);
        }
      },
      onLongPressEnd: (details) {
        if (!_isLocked) {
          widget.onStopAndSend();
        }
      },
      onTap: () {
        // Fallback tap: start immediately locked
        widget.onStart();
        widget.onLockChanged(true);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.mic_rounded, color: AppColors.surface, size: 20),
      ),
    );
  }
}
