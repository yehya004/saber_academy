import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/web_image/web_image.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../utils/blob_helper.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import '../../utils/drag_drop_helper.dart';

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
import 'chat_media_screen.dart';



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
  final List<ChatMessageModel> _uploadingMessages = [];
  bool _loading = true;
  bool _hasError = false;
  bool _sendingImage = false;
  bool _sendingFile = false;
  bool _isDragging = false;
  bool _isDraggingWeb = false;
  bool _isSearching = false;
  bool _initialScrollDone = false;
  String? _highlightedMessageId;
  final _searchController = TextEditingController();
  DropzoneViewController? _dropzoneController;
  late String _myId;
  ProfileModel? _partnerProfile;
  ChatMessageModel? _replyingTo;

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
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
    if (kIsWeb) {
      DragDropHelper.initialize(
        onDragStateChanged: (isDragging) {
          if (mounted) {
            setState(() {
              _isDraggingWeb = isDragging;
            });
          }
        },
      );
    }
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
          final shouldScroll = !_initialScrollDone && msgs.isNotEmpty;
          setState(() {
            _messages = msgs;
            _loading = false;
            _hasError = false;
            if (shouldScroll) {
              _initialScrollDone = true;
            }
          });
          if (shouldScroll || newMessages) {
            _scrollToBottom();
          }
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
          _initialScrollDone = true;
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
    _searchController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _recordTimer?.cancel();
    _amplitudeTimer?.cancel();
    if (kIsWeb) {
      DragDropHelper.dispose();
    }
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  double _estimateMessageHeight(ChatMessageModel msg) {
    if (msg.isDeleted) return 50.0;
    
    double height = 45.0; // margins, time label, general padding
    
    if (msg.replyToId != null) {
      height += 60.0; // reply container
    }
    
    if (msg.isImage) {
      height += 200.0;
    } else if (msg.isAudio) {
      height += 80.0;
    } else if (msg.isFile) {
      height += 75.0;
    } else {
      // Text estimation: count lines
      final length = msg.messageText.length;
      final lines = (length / 45.0).ceil();
      height += lines * 22.0 + 12.0;
    }
    
    return height.clamp(50.0, 450.0);
  }

  void _scrollToMessage(String messageId) {
    final allMessages = [..._messages, ..._uploadingMessages];
    final allIdx = allMessages.indexWhere((m) => m.id == messageId);
    if (allIdx == -1) return;
    
    final targetIndex = allMessages.length - 1 - allIdx;
    
    double targetOffset = 0.0;
    for (int j = 0; j < targetIndex; j++) {
      targetOffset += _estimateMessageHeight(allMessages[allMessages.length - 1 - j]);
    }
    
    // Adjust target offset to center the message
    final adjustedOffset = (targetOffset - 150.0).clamp(0.0, _scrollController.position.maxScrollExtent);
    
    _scrollController.animateTo(
      adjustedOffset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    
    setState(() {
      _highlightedMessageId = messageId;
    });
    
    Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _highlightedMessageId = null;
        });
      }
    });
  }

  String _timeLabel(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
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
    
    final ChatMessageModel? replyMsg = _replyingTo;
    
    if (mounted && _replyingTo != null) {
      setState(() {
        _replyingTo = null;
      });
    }

    try {
      String? replyToId;
      String? replyToText;
      String? replyToSenderName;
      
      if (replyMsg != null) {
        replyToId = replyMsg.id;
        replyToText = replyMsg.messageText.isNotEmpty
            ? replyMsg.messageText
            : (replyMsg.imageUrl != null ? '📷 صورة' : '📁 ملف');
        
        final isAr = Localizations.localeOf(context).languageCode == 'ar';
        final isSenderMine = replyMsg.senderId == _myId;
        replyToSenderName = isSenderMine 
            ? (isAr ? 'أنت' : 'You') 
            : widget.partnerName;
      }

      await _chatService.sendMessage(
        senderId: _myId,
        receiverId: widget.partnerId,
        messageText: text,
        replyToId: replyToId,
        replyToText: replyToText,
        replyToSenderName: replyToSenderName,
      );
      await _fetchMessagesSilently();
    } catch (e) {
      debugPrint("Error sending message: $e");
    }
  }

  Future<void> _sendImage() async {
    final l10n = AppLocalizations.of(context);
    
    Uint8List? imageBytes;
    String? imageName;
    
    try {
      if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        final result = await FilePicker.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );
        if (result != null && result.files.isNotEmpty) {
          final fileInfo = result.files.single;
          if (fileInfo.path != null) {
            imageBytes = await File(fileInfo.path!).readAsBytes();
            imageName = fileInfo.name;
          }
        }
      } else {
        final picked = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 70,
        );
        if (picked != null) {
          imageBytes = await picked.readAsBytes();
          imageName = picked.name;
        }
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
    
    if (imageBytes == null) return;

    if (!mounted) return;
    final dynamic result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (_) => ImageEditorScreen(
          imageBytes: imageBytes!,
          imageName: imageName ?? 'image.png',
        ),
      ),
    );
    if (result == null) return;

    final tempMsg = ChatMessageModel(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      senderId: _myId,
      receiverId: widget.partnerId,
      messageText: '',
      isRead: false,
      createdAt: DateTime.now(),
      imageUrl: 'local_temp',
      fileName: imageName ?? 'image.png',
    );
    setState(() {
      _uploadingMessages.add(tempMsg);
      _sendingImage = true;
    });
    _scrollToBottom();

    try {
      // result can be File (on Native) or Uint8List (on Web)
      final telegramFileId = await _telegramService.uploadFile(
        result,
        caption: 'صورة في المحادثة من $_myId إلى ${widget.partnerId} — ${DateTime.now().toIso8601String()}',
        fileName: imageName,
      );

      final String name = imageName ?? (result is File ? result.path.split(Platform.pathSeparator).last : 'image.png');

      await _chatService.sendMessage(
        senderId: _myId,
        receiverId: widget.partnerId,
        messageText: '',
        fileName: name,
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
      if (mounted) {
        setState(() {
          _sendingImage = false;
          _uploadingMessages.removeWhere((m) => m.id == tempMsg.id);
        });
      }
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

    dynamic uploadSource;
    if (kIsWeb) {
      if (fileInfo.bytes == null) return;
      uploadSource = fileInfo.bytes;
    } else {
      if (fileInfo.path == null) return;
      uploadSource = File(fileInfo.path!);
    }

    final tempMsg = ChatMessageModel(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      senderId: _myId,
      receiverId: widget.partnerId,
      messageText: '',
      isRead: false,
      createdAt: DateTime.now(),
      fileUrl: 'local_temp',
      fileName: fileInfo.name,
    );
    setState(() {
      _uploadingMessages.add(tempMsg);
      _sendingFile = true;
    });
    _scrollToBottom();

    try {
      // Upload to Telegram only (bypass Supabase Storage)
      final telegramFileId = await _telegramService.uploadFile(
        uploadSource,
        caption: 'ملف في المحادثة (${fileInfo.name}) من $_myId إلى ${widget.partnerId} — ${DateTime.now().toIso8601String()}',
        fileName: fileInfo.name,
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
      if (mounted) {
        setState(() {
          _sendingFile = false;
          _uploadingMessages.removeWhere((m) => m.id == tempMsg.id);
        });
      }
    }
  }

  Future<void> _handleDroppedFile(XFile file) async {
    final l10n = AppLocalizations.of(context);
    final size = await file.length();
    final name = file.name;

    // Enforce 10 MB size limit
    if (size > 10 * 1024 * 1024) {
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

    final ext = name.split('.').last.toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);

    if (isImage) {
      final imageBytes = await file.readAsBytes();
      if (!mounted) return;

      final dynamic result = await Navigator.of(context).push<dynamic>(
        MaterialPageRoute(
          builder: (_) => ImageEditorScreen(
            imageBytes: imageBytes,
            imageName: name,
          ),
        ),
      );
      if (result == null) return;

      final tempMsg = ChatMessageModel(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        senderId: _myId,
        receiverId: widget.partnerId,
        messageText: '',
        isRead: false,
        createdAt: DateTime.now(),
        imageUrl: 'local_temp',
        fileName: name,
      );
      setState(() {
        _uploadingMessages.add(tempMsg);
        _sendingImage = true;
      });
      _scrollToBottom();

      try {
        final telegramFileId = await _telegramService.uploadFile(
          result,
          caption: 'صورة في المحادثة من $_myId إلى ${widget.partnerId} — ${DateTime.now().toIso8601String()}',
          fileName: name,
        );

        final String finalName;
        if (kIsWeb) {
          finalName = name;
        } else {
          finalName = result is File ? result.path.split(Platform.pathSeparator).last : name;
        }

        await _chatService.sendMessage(
          senderId: _myId,
          receiverId: widget.partnerId,
          messageText: '',
          fileName: finalName,
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
        if (mounted) {
          setState(() {
            _sendingImage = false;
            _uploadingMessages.removeWhere((m) => m.id == tempMsg.id);
          });
        }
      }
    } else {
      // Send as regular file
      final tempMsg = ChatMessageModel(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        senderId: _myId,
        receiverId: widget.partnerId,
        messageText: '',
        isRead: false,
        createdAt: DateTime.now(),
        fileUrl: 'local_temp',
        fileName: name,
      );
      setState(() {
        _uploadingMessages.add(tempMsg);
        _sendingFile = true;
      });
      _scrollToBottom();

      try {
        final bytes = await file.readAsBytes();
        final dynamic uploadSource;
        if (kIsWeb) {
          uploadSource = bytes;
        } else {
          uploadSource = File(file.path);
        }

        final telegramFileId = await _telegramService.uploadFile(
          uploadSource,
          caption: 'ملف في المحادثة ($name) من $_myId إلى ${widget.partnerId} — ${DateTime.now().toIso8601String()}',
          fileName: name,
        );

        await _chatService.sendMessage(
          senderId: _myId,
          receiverId: widget.partnerId,
          messageText: '',
          fileName: name,
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
        if (mounted) {
          setState(() {
            _sendingFile = false;
            _uploadingMessages.removeWhere((m) => m.id == tempMsg.id);
          });
        }
      }
    }
  }

  Future<void> _startRecording({bool startLocked = false}) async {
    try {
      debugPrint('[VoiceNote] Checking microphone permission...');
      final hasPermission = await _audioRecorder.hasPermission();
      debugPrint('[VoiceNote] hasPermission: $hasPermission');
      if (hasPermission) {
        String path;
        if (kIsWeb) {
          // On web, record package handles blob URLs automatically
          path = '';
        } else {
          final tempDir = await getTemporaryDirectory();
          final isWindows = !kIsWeb && Platform.isWindows;
          final ext = isWindows ? 'wav' : 'm4a';
          path = '${tempDir.path}/audio_note_${DateTime.now().millisecondsSinceEpoch}.$ext';
        }
        debugPrint('[VoiceNote] Starting recording at: $path');
        
        if (kIsWeb) {
          await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.opus), path: '');
        } else if (!kIsWeb && Platform.isWindows) {
          await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.wav), path: path);
        } else {
          await _audioRecorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
        }
        debugPrint('[VoiceNote] Recording started successfully!');
        
        final bool isDesktop = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
        final bool shouldLock = startLocked || kIsWeb || isDesktop;

        setState(() {
          _isRecording = true;
          _isRecordingLocked = shouldLock;
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
      } else {
        debugPrint('[VoiceNote] Microphone permission denied');
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.localeName == 'ar'
                  ? 'يجب السماح بإذن الميكروفون لتسجيل الصوت'
                  : (l10n.localeName == 'tr'
                      ? 'Ses kaydetmek için mikrofon izni gereklidir'
                      : 'Microphone permission is required to record voice')),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e, st) {
      debugPrint("[VoiceNote] Error starting voice recording: $e\n$st");
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.localeName == 'ar'
                ? 'فشل بدء التسجيل: ${e.toString()}'
                : 'Recording failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
      debugPrint('[VoiceNote] Stopping recording...');
      final path = await _audioRecorder.stop();
      debugPrint('[VoiceNote] Recorder returned path: $path');
      setState(() {
        _isRecording = false;
        _isRecordingLocked = false;
      });

      if (path == null || path.isEmpty) {
        debugPrint('[VoiceNote] ERROR: path is null or empty');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.localeName == 'ar'
                  ? 'فشل تسجيل الصوت. حاول مرة أخرى.'
                  : (l10n.localeName == 'tr'
                      ? 'Ses kaydı başarısız. Tekrar deneyin.'
                      : 'Voice recording failed. Please try again.')),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      dynamic uploadSource;
      if (kIsWeb) {
        debugPrint('[VoiceNote] Web: fetching blob bytes from $path');
        try {
          final bytes = await fetchBlobBytes(path);
          uploadSource = bytes;
          debugPrint('[VoiceNote] Web blob size: ${bytes.length} bytes');
        } catch (e) {
          debugPrint('[VoiceNote] ERROR: web blob read failed: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.localeName == 'ar'
                    ? 'فشل قراءة التسجيل الصوتي.'
                    : 'Failed to read audio recording.'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      } else {
        final file = File(path);
        if (!file.existsSync()) {
          debugPrint('[VoiceNote] ERROR: file does not exist at $path');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.localeName == 'ar'
                    ? 'ملف التسجيل غير موجود.'
                    : 'Recording file not found.'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }

        final size = file.lengthSync();
        debugPrint('[VoiceNote] File size: $size bytes');
        if (size == 0) {
          debugPrint('[VoiceNote] ERROR: file is empty');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.localeName == 'ar'
                    ? 'التسجيل فارغ. حاول مرة أخرى.'
                    : 'Recording is empty. Please try again.'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
        if (size > 10 * 1024 * 1024) {
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
        uploadSource = file;
      }

      setState(() => _sendingFile = true);
      debugPrint('[VoiceNote] Uploading to Telegram...');
      // Upload to Telegram only (bypass Supabase Storage)
      final telegramFileId = await _telegramService.uploadFile(
        uploadSource,
        caption: 'ريكورد صوتي في المحادثة من $_myId إلى ${widget.partnerId} — ${DateTime.now().toIso8601String()}',
        fileName: 'Voice Note.m4a',
      );
      debugPrint('[VoiceNote] Telegram upload success: $telegramFileId');

      await _chatService.sendMessage(
        senderId: _myId,
        receiverId: widget.partnerId,
        messageText: '',
        fileName: 'Voice Note.m4a',
        telegramFileId: telegramFileId,
      );
      debugPrint('[VoiceNote] Message sent to chat!');
      await _fetchMessagesSilently();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.localeName == 'ar'
                ? '✅ تم إرسال الرسالة الصوتية'
                : (l10n.localeName == 'tr'
                    ? '✅ Sesli mesaj gönderildi'
                    : '✅ Voice message sent')),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('[VoiceNote] ERROR: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.localeName == 'ar'
                ? 'فشل إرسال التسجيل: ${e.toString()}'
                : 'Voice send failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
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
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isTeacher = auth.profile?.role == 'teacher';
    final canDelete = msg.senderId == _myId || isTeacher;
    if (msg.isDeleted || !canDelete) return;

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
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isTeacher = auth.profile?.role == 'teacher';
    final canDelete = isMine || isTeacher;

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
              ListTile(
                leading: const Icon(Icons.reply_rounded, color: AppColors.primary),
                title: Text(isAr ? 'الرد على الرسالة' : (isTr ? 'Cevapla' : 'Reply')),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _replyingTo = msg;
                  });
                },
              ),
              if (isTeacher)
                ListTile(
                  leading: const Icon(Icons.forward_rounded, color: AppColors.primary),
                  title: Text(isAr ? 'تحويل الرسالة' : (isTr ? 'Mesajı İlet' : 'Forward Message')),
                  onTap: () {
                    Navigator.pop(context);
                    _showForwardDialog(msg);
                  },
                ),
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
              if (canDelete)
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

  void _showForwardDialog(ChatMessageModel msg) async {
    final l10n = AppLocalizations.of(context);
    final isAr = l10n.localeName == 'ar';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppColors.secondary),
      ),
    );

    List<ProfileModel> students = [];
    try {
      students = await ProfileService().fetchStudents();
    } catch (e) {
      debugPrint("Error fetching students for forward: $e");
    }

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    if (students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'لا يوجد طلاب لتحويل الرسالة إليهم' : 'No students found to forward to'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    String searchQuery = '';
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = students.where((s) =>
                s.fullName.toLowerCase().contains(searchQuery.toLowerCase())).toList();

            return AlertDialog(
              title: Text(
                isAr ? 'تحويل الرسالة إلى...' : 'Forward message to...',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: isAr ? 'بحث عن طالب...' : 'Search student...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          searchQuery = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final student = filtered[index];
                          return ListTile(
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundImage: student.avatarUrl != null && student.avatarUrl!.isNotEmpty
                                  ? NetworkImage(student.avatarUrl!)
                                  : null,
                              child: student.avatarUrl == null || student.avatarUrl!.isEmpty
                                  ? Text(student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : '؟')
                                  : null,
                            ),
                            title: Text(student.fullName, style: const TextStyle(fontSize: 14)),
                            onTap: () async {
                              Navigator.pop(ctx);
                              _forwardMessageTo(msg, student);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(isAr ? 'إلغاء' : 'Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _forwardMessageTo(ChatMessageModel msg, ProfileModel student) async {
    final l10n = AppLocalizations.of(context);
    final isAr = l10n.localeName == 'ar';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppColors.secondary),
      ),
    );

    try {
      await _chatService.sendMessage(
        senderId: _myId,
        receiverId: student.id,
        messageText: msg.messageText,
        imageUrl: msg.imageUrl,
        fileUrl: msg.fileUrl,
        fileName: msg.fileName,
        telegramFileId: msg.telegramFileId,
      );
      
      if (mounted) {
        Navigator.pop(context); // Close loading overlay
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'تم تحويل الرسالة بنجاح إلى ${student.fullName}' : 'Message forwarded to ${student.fullName}'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading overlay
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'فشل تحويل الرسالة: $e' : 'Failed to forward message: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildReplyPreview() {
    if (_replyingTo == null) return const SizedBox.shrink();
    
    final l10n = AppLocalizations.of(context);
    final isAr = l10n.localeName == 'ar';
    final isMine = _replyingTo!.senderId == _myId;
    final senderName = isMine 
        ? (isAr ? 'أنت' : 'You') 
        : (widget.partnerName);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 0.8),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isAr ? 'الرد على $senderName' : 'Replying to $senderName',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _replyingTo!.messageText.isNotEmpty
                      ? _replyingTo!.messageText
                      : (_replyingTo!.imageUrl != null 
                          ? (isAr ? '📷 صورة' : '📷 Photo') 
                          : (isAr ? '📁 ملف' : '📁 File')),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20, color: Colors.black54),
            onPressed: () {
              setState(() {
                _replyingTo = null;
              });
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _viewOrEditImage(ChatMessageModel message) {
    final imageUrl = message.imageUrl;
    if (imageUrl == null || imageUrl.isEmpty) return;

    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isTr = Localizations.localeOf(context).languageCode == 'tr';
    
    final mainNavigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (ctx) {
        bool fetchingBytes = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: buildWebFriendlyImage(
                          imageUrl: imageUrl,
                          width: MediaQuery.of(context).size.width * 0.9,
                          height: MediaQuery.of(context).size.height * 0.7,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  
                  Positioned(
                    top: 16,
                    left: 16,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (fetchingBytes)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: CircularProgressIndicator(color: AppColors.secondary),
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: fetchingBytes ? null : () async {
                                final dialogNavigator = Navigator.of(ctx);
                                setDialogState(() => fetchingBytes = true);
                                try {
                                  List<int>? responseBytes;
                                  if (kIsWeb) {
                                    final List<String> proxyUrls = [
                                      'https://cors.zme.ink/$imageUrl',
                                      'https://corsproxy.org/?url=${Uri.encodeComponent(imageUrl)}',
                                      'https://api.allorigins.win/raw?url=${Uri.encodeComponent(imageUrl)}',
                                    ];
                                    for (final proxyUrl in proxyUrls) {
                                      try {
                                        final response = await Dio().get<List<int>>(
                                          proxyUrl,
                                          options: Options(
                                            responseType: ResponseType.bytes,
                                            connectTimeout: const Duration(seconds: 6),
                                            receiveTimeout: const Duration(seconds: 6),
                                          ),
                                        );
                                        final contentType = response.headers.value('content-type') ?? '';
                                        if (response.data != null && 
                                            !contentType.contains('text/html') && 
                                            !contentType.contains('application/json')) {
                                          responseBytes = response.data;
                                          break;
                                        }
                                      } catch (e) {
                                        debugPrint("Failed to fetch via proxy $proxyUrl: $e");
                                      }
                                    }
                                  } else {
                                    final response = await Dio().get<List<int>>(
                                      imageUrl,
                                      options: Options(responseType: ResponseType.bytes),
                                    );
                                    responseBytes = response.data;
                                  }
                                  
                                  if (responseBytes != null) {
                                    final bytes = Uint8List.fromList(responseBytes);
                                    dialogNavigator.pop();
                                    
                                    if (mounted) {
                                      final dynamic editedResult = await mainNavigator.push<dynamic>(
                                        MaterialPageRoute(
                                          builder: (_) => ImageEditorScreen(
                                            imageBytes: bytes,
                                            imageName: message.fileName ?? 'edited_image.png',
                                          ),
                                        ),
                                      );
                                      if (editedResult != null) {
                                        final tempMsg = ChatMessageModel(
                                          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
                                          senderId: _myId,
                                          receiverId: widget.partnerId,
                                          messageText: '',
                                          isRead: false,
                                          createdAt: DateTime.now(),
                                          imageUrl: 'local_temp',
                                          fileName: 'edited_${message.fileName ?? "image.png"}',
                                        );
                                        if (mounted) {
                                          setState(() {
                                            _uploadingMessages.add(tempMsg);
                                            _sendingImage = true;
                                          });
                                          _scrollToBottom();
                                        }
                                        try {
                                          final telegramFileId = await _telegramService.uploadFile(
                                            editedResult,
                                            caption: 'صورة معدلة في المحادثة من $_myId إلى ${widget.partnerId} — ${DateTime.now().toIso8601String()}',
                                            fileName: 'edited_${message.fileName ?? "image.png"}',
                                          );

                                          await _chatService.sendMessage(
                                            senderId: _myId,
                                            receiverId: widget.partnerId,
                                            messageText: '',
                                            fileName: 'edited_${message.fileName ?? "image.png"}',
                                            telegramFileId: telegramFileId,
                                          );
                                          await _fetchMessagesSilently();
                                        } finally {
                                          if (mounted) {
                                            setState(() {
                                              _sendingImage = false;
                                              _uploadingMessages.removeWhere((m) => m.id == tempMsg.id);
                                            });
                                          }
                                        }
                                      }
                                    }
                                  }
                                } catch (e) {
                                  debugPrint("Error fetching bytes for edit: $e");
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text(isAr ? 'فشل تحميل الصورة للتعديل' : 'Failed to download image for editing'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                } finally {
                                  setDialogState(() => fetchingBytes = false);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              icon: const Icon(Icons.edit, size: 18),
                              label: Text(
                                isAr ? 'تعديل وإعادة إرسال' : (isTr ? 'Düzenle ve Yeniden Gönder' : 'Edit & Resend'),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final uri = Uri.parse(imageUrl);
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white24,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: const BorderSide(color: Colors.white38, width: 0.8),
                                ),
                              ),
                              icon: const Icon(Icons.download, size: 18),
                              label: Text(
                                isAr ? 'فتح للتحميل' : (isTr ? 'İndirmek için Aç' : 'Open to Download'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    final allMessages = [..._messages, ..._uploadingMessages];
    final searchQuery = _searchController.text.trim().toLowerCase();
    
    // Filter messages for the search overlay list
    final displayedMessages = searchQuery.isEmpty
        ? allMessages
        : _messages.where((m) {
            final textMatch = m.messageText.toLowerCase().contains(searchQuery);
            final fileMatch = m.fileName != null && m.fileName!.toLowerCase().contains(searchQuery);
            return textMatch || fileMatch;
          }).toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: _isSearching ? Colors.white : AppColors.primary,
        foregroundColor: _isSearching ? AppColors.primary : Colors.white,
        iconTheme: IconThemeData(
          color: _isSearching ? AppColors.primary : AppColors.surface,
        ),
        title: _isSearching
            ? Container(
                height: 40,
                margin: const EdgeInsets.only(right: 16, left: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                        cursorColor: AppColors.primary,
                        decoration: InputDecoration(
                          hintText: Localizations.localeOf(context).languageCode == 'ar'
                              ? 'بحث في المحادثة...'
                              : 'Search chat...',
                          hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        autofocus: true,
                      ),
                    ),
                  ],
                ),
              )
            : GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  final ChatMessageModel? selectedMsg = await Navigator.push<ChatMessageModel?>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatMediaScreen(
                        messages: _messages,
                        partnerName: widget.partnerName,
                      ),
                    ),
                  );
                  if (selectedMsg != null && mounted) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        _scrollToMessage(selectedMsg.id);
                      }
                    });
                  }
                },
                child: Row(
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
              ),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
        ],
      ),
      body: DropTarget(
        onDragEntered: (details) {
          setState(() {
            _isDragging = true;
          });
        },
        onDragExited: (details) {
          setState(() {
            _isDragging = false;
          });
        },
        onDragDone: (details) async {
          setState(() {
            _isDragging = false;
          });
          if (kIsWeb) return;
          if (details.files.isNotEmpty) {
            for (final file in details.files) {
              await _handleDroppedFile(file);
            }
          }
        },
        child: Stack(
          children: [
            Column(
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
                          : allMessages.isEmpty
                              ? Center(
                                  child: Text(
                                    l10n.startChatConversation,
                                    style: const TextStyle(color: AppColors.textSecondary),
                                  ),
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  reverse: true,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.small),
                                  itemCount: allMessages.length,
                                  itemBuilder: (_, i) {
                                    // In reverse mode, index i goes from 0 (newest/bottom) to length-1 (oldest/top)
                                    final message = allMessages[allMessages.length - 1 - i];
                                    final isTemp = message.id.startsWith('temp_');
                                    final isHighlighted = message.id == _highlightedMessageId;
                                    
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 500),
                                      color: isHighlighted
                                          ? AppColors.secondary.withValues(alpha: 0.3)
                                          : Colors.transparent,
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: GestureDetector(
                                        onLongPress: isTemp ? null : () => _showMessageOptions(message),
                                        onSecondaryTap: isTemp ? null : () => _showMessageOptions(message),
                                        child: ChatBubble(
                                          message: message,
                                          isMine: message.senderId == _myId,
                                          onImageTapped: isTemp ? null : _viewOrEditImage,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                ),
                if (_replyingTo != null) _buildReplyPreview(),
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
                  onStartRecord: (locked) => _startRecording(startLocked: locked),
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
            // Search Results Overlay
            if (_isSearching && searchQuery.isNotEmpty)
              Positioned.fill(
                child: Container(
                  color: AppColors.background,
                  child: displayedMessages.isEmpty
                      ? Center(
                          child: Text(
                            Localizations.localeOf(context).languageCode == 'ar'
                                ? 'لم يتم العثور على نتائج'
                                : 'No results found',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          itemCount: displayedMessages.length,
                          itemBuilder: (ctx, i) {
                            final msg = displayedMessages[i];
                            final isMine = msg.senderId == _myId;
                            final dateStr = _timeLabel(msg.createdAt);
                            final senderName = isMine
                                ? (Localizations.localeOf(context).languageCode == 'ar' ? 'أنت' : 'You')
                                : widget.partnerName;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                child: Icon(
                                  msg.isImage
                                      ? Icons.image_outlined
                                      : (msg.isFile ? Icons.insert_drive_file_outlined : Icons.chat_bubble_outline_rounded),
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                msg.messageText.isNotEmpty
                                    ? msg.messageText
                                    : (msg.fileName ?? ''),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.textPrimary),
                              ),
                              subtitle: Text(
                                '$senderName • $dateStr',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                              onTap: () {
                                setState(() {
                                  _isSearching = false;
                                  _searchController.clear();
                                });
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (_scrollController.hasClients) {
                                    _scrollToMessage(msg.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                ),
              ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !(_isDraggingWeb && kIsWeb),
                child: kIsWeb
                    ? DropzoneView(
                        operation: DragOperation.copy,
                        cursor: CursorType.Default,
                        onCreated: (ctrl) => _dropzoneController = ctrl,
                        onHover: () {},
                        onLeave: () {},
                        onDropFile: (_) {},
                        onDropFiles: (htmlFiles) async {
                          if (_dropzoneController != null && htmlFiles != null) {
                            try {
                              final List<XFile> xFiles = [];
                              for (final htmlFile in htmlFiles) {
                                final name = await _dropzoneController!.getFilename(htmlFile);
                                final size = await _dropzoneController!.getFileSize(htmlFile);
                                final bytes = await _dropzoneController!.getFileData(htmlFile);
                                xFiles.add(XFile.fromData(bytes, name: name, length: size));
                              }
                              
                              if (mounted) {
                                setState(() {
                                  _isDraggingWeb = false;
                                });
                              }
                              
                              for (final xFile in xFiles) {
                                await _handleDroppedFile(xFile);
                              }
                            } catch (e) {
                              debugPrint("Error handling web drop files list: $e");
                              if (mounted) {
                                setState(() {
                                  _isDraggingWeb = false;
                                });
                              }
                            }
                          } else {
                            if (mounted) {
                              setState(() {
                                _isDraggingWeb = false;
                              });
                            }
                          }
                        },
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            if (_isDragging || _isDraggingWeb)
              IgnorePointer(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.55),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cloud_upload_outlined,
                            size: 48,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            Localizations.localeOf(context).languageCode == 'ar'
                                ? 'أفلت الملفات هنا لإرسالها'
                                : 'Drop files here to send them',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
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
  final ValueSetter<bool> onStartRecord;
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
  final ValueSetter<bool> onStart;
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
        widget.onStart(false);
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
        widget.onStart(true);
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
