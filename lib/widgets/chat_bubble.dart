import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_spacing.dart';
import '../l10n/app_localizations.dart';
import '../models/chat_message_model.dart';
import '../services/telegram_storage_service.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMine;

  const ChatBubble({super.key, required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    // In RTL layout the sender's bubble is on the left; in LTR it is on the right.
    final alignment = isMine
        ? (isRtl ? Alignment.centerLeft  : Alignment.centerRight)
        : (isRtl ? Alignment.centerRight : Alignment.centerLeft);

    if (message.isDeleted) {
      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      final isTr = Localizations.localeOf(context).languageCode == 'tr';
      final String text = message.wasAttachment
          ? (isAr ? 'تم إزالة الملف' : (isTr ? 'Dosya kaldırıldı' : 'File has been removed'))
          : (isAr ? 'تم إزالة الرسالة' : (isTr ? 'Mesaj kaldırıldı' : 'Message has been removed'));

      return Align(
        alignment: alignment,
        child: Container(
          margin: const EdgeInsets.symmetric(
            vertical:   4,
            horizontal: AppSpacing.medium,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.medium,
            vertical:   AppSpacing.small,
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          decoration: BoxDecoration(
            color: isMine ? AppColors.primary.withValues(alpha: 0.4) : AppColors.studentBubble.withValues(alpha: 0.4),
            borderRadius: BorderRadius.only(
              topLeft:     const Radius.circular(AppSpacing.chatBubbleRadius),
              topRight:    const Radius.circular(AppSpacing.chatBubbleRadius),
              bottomLeft:  Radius.circular(isMine ? AppSpacing.chatBubbleRadius : 4),
              bottomRight: Radius.circular(isMine ? 4 : AppSpacing.chatBubbleRadius),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.block,
                    size: 14,
                    color: isMine ? Colors.white60 : Colors.black45,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    text,
                    style: TextStyle(
                      color: isMine ? Colors.white70 : Colors.black54,
                      fontStyle: FontStyle.italic,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _timeLabel(message.createdAt),
                style: TextStyle(
                  color: isMine
                      ? Colors.white38
                      : Colors.black38,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical:   4,
          horizontal: AppSpacing.medium,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : AppColors.studentBubble,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(AppSpacing.chatBubbleRadius),
            topRight:    const Radius.circular(AppSpacing.chatBubbleRadius),
            bottomLeft:  Radius.circular(isMine ? AppSpacing.chatBubbleRadius : 4),
            bottomRight: Radius.circular(isMine ? 4 : AppSpacing.chatBubbleRadius),
          ),
        ),
        child: message.telegramFileId != null
            ? TelegramMediaWidget(
                telegramFileId: message.telegramFileId!,
                builder: (context, url, isImage, fileName) {
                  final tempMsg = ChatMessageModel(
                    id: message.id,
                    senderId: message.senderId,
                    receiverId: message.receiverId,
                    messageText: message.messageText,
                    isRead: message.isRead,
                    createdAt: message.createdAt,
                    imageUrl: isImage ? url : null,
                    fileUrl: !isImage ? url : null,
                    fileName: fileName,
                    telegramFileId: message.telegramFileId,
                  );
                  return tempMsg.isImage
                      ? _ImageContent(message: tempMsg, isMine: isMine)
                      : tempMsg.isAudio
                          ? _AudioContent(message: tempMsg, isMine: isMine)
                          : _FileContent(message: tempMsg, isMine: isMine);
                },
              )
            : message.isImage
                ? _ImageContent(message: message, isMine: isMine)
                : message.isAudio
                    ? _AudioContent(message: message, isMine: isMine)
                    : message.isFile
                        ? _FileContent(message: message, isMine: isMine)
                        : _TextContent(message: message, isMine: isMine),
      ),
    );
  }
}

class _TextContent extends StatelessWidget {
  const _TextContent({required this.message, required this.isMine});
  final ChatMessageModel message;
  final bool isMine;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical:   AppSpacing.small,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize:       MainAxisSize.min,
          children: [
            Text(
              message.messageText,
              style: TextStyle(
                color:    isMine ? AppColors.surface : AppColors.textPrimary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _timeLabel(message.createdAt),
                  style: TextStyle(
                    color:    isMine
                        ? AppColors.surface.withValues(alpha: 0.65)
                        : AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all,
                    size: 14,
                    color: message.isRead
                        ? const Color(0xFF34B7F1) // WhatsApp blue read color
                        : Colors.white60,
                  ),
                ],
              ],
            ),
          ],
        ),
      );
}

class _ImageContent extends StatelessWidget {
  const _ImageContent({required this.message, required this.isMine});
  final ChatMessageModel message;
  final bool isMine;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft:     const Radius.circular(AppSpacing.chatBubbleRadius),
              topRight:    const Radius.circular(AppSpacing.chatBubbleRadius),
              bottomLeft:  Radius.circular(isMine ? AppSpacing.chatBubbleRadius : 4),
              bottomRight: Radius.circular(isMine ? 4 : AppSpacing.chatBubbleRadius),
            ),
            child: Image.network(
              message.imageUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : const SizedBox(
                      width: 200, height: 150,
                      child: Center(child: CircularProgressIndicator()),
                    ),
              errorBuilder: (_, __, ___) => const SizedBox(
                width: 200, height: 100,
                child: Center(child: Icon(Icons.broken_image, color: Colors.grey)),
              ),
            ),
          ),
          Positioned(
            bottom: 4, right: 6,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _timeLabel(message.createdAt),
                  style: const TextStyle(
                    color:    Colors.white,
                    fontSize: 10,
                    shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all,
                    size: 14,
                    color: message.isRead
                        ? const Color(0xFF34B7F1) // WhatsApp blue read color
                        : Colors.white60,
                    shadows: const [Shadow(blurRadius: 2, color: Colors.black54)],
                  ),
                ],
              ],
            ),
          ),
        ],
      );
}

class _FileContent extends StatelessWidget {
  const _FileContent({required this.message, required this.isMine});
  final ChatMessageModel message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: () async {
        final url = message.fileUrl;
        if (url != null && url.isNotEmpty) {
          final uri = Uri.parse(url);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(AppSpacing.chatBubbleRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical:   AppSpacing.small,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize:       MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.insert_drive_file_rounded,
                  color: isMine ? AppColors.surface : AppColors.primary,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize:       MainAxisSize.min,
                    children: [
                      Text(
                        message.fileName ?? l10n.downloadFile,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color:      isMine ? AppColors.surface : AppColors.textPrimary,
                          fontSize:   14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.downloadFile,
                        style: TextStyle(
                          color: isMine
                              ? AppColors.surface.withValues(alpha: 0.70)
                              : AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _timeLabel(message.createdAt),
                  style: TextStyle(
                    color:    isMine
                        ? AppColors.surface.withValues(alpha: 0.65)
                        : AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all,
                    size: 14,
                    color: message.isRead
                        ? const Color(0xFF34B7F1) // WhatsApp blue read color
                        : Colors.white60,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _timeLabel(DateTime dt) {
  final local = dt.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

class _AudioContent extends StatefulWidget {
  final ChatMessageModel message;
  final bool isMine;

  const _AudioContent({required this.message, required this.isMine});

  @override
  State<_AudioContent> createState() => _AudioContentState();
}

class _AudioContentState extends State<_AudioContent> {
  late final AudioPlayer _audioPlayer;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isInit = false;
  double _playbackRate = 1.0;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });
    
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _position = Duration.zero;
          _playerState = PlayerState.completed;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    final url = widget.message.fileUrl;
    if (url == null || url.isEmpty) return;

    if (_playerState == PlayerState.playing) {
      await _audioPlayer.pause();
    } else {
      if (!_isInit) {
        await _audioPlayer.setSourceUrl(url);
        _isInit = true;
      }
      await _audioPlayer.resume();
      await _audioPlayer.setPlaybackRate(_playbackRate);
    }
  }

  void _changePlaybackRate() {
    setState(() {
      if (_playbackRate == 1.0) {
        _playbackRate = 1.5;
      } else if (_playbackRate == 1.5) {
        _playbackRate = 2.0;
      } else {
        _playbackRate = 1.0;
      }
    });
    if (_playerState == PlayerState.playing) {
      _audioPlayer.setPlaybackRate(_playbackRate);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isMine ? AppColors.surface : AppColors.textPrimary;
    final iconColor = widget.isMine ? AppColors.surface : AppColors.primary;
    final activeColor = widget.isMine ? AppColors.secondary : AppColors.primary;
    final inactiveColor = widget.isMine ? Colors.white30 : Colors.black12;

    final isPlaying = _playerState == PlayerState.playing;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: AppSpacing.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _togglePlay,
                icon: Icon(
                  isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                  size: 36,
                  color: iconColor,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              // Waveform-like slider
              SizedBox(
                width: 108,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3.0,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10.0),
                    activeTrackColor: activeColor,
                    inactiveTrackColor: inactiveColor,
                    thumbColor: activeColor,
                  ),
                  child: Slider(
                    value: _position.inMilliseconds.toDouble(),
                    max: _duration.inMilliseconds > 0 
                        ? _duration.inMilliseconds.toDouble() 
                        : 100.0,
                    onChanged: (val) async {
                      final pos = Duration(milliseconds: val.toInt());
                      await _audioPlayer.seek(pos);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _formatDuration(isPlaying ? _position : _duration),
                style: TextStyle(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              // Speed control button
              GestureDetector(
                onTap: _changePlaybackRate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: activeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: activeColor.withValues(alpha: 0.3), width: 0.8),
                  ),
                  child: Text(
                    '${_playbackRate.toStringAsFixed(1).replaceAll('.0', '')}x',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.mic_rounded,
                color: widget.isMine ? AppColors.surface.withValues(alpha: 0.6) : AppColors.textSecondary,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(right: 8, left: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _timeLabel(widget.message.createdAt),
                  style: TextStyle(
                    color: widget.isMine
                        ? AppColors.surface.withValues(alpha: 0.65)
                        : AppColors.textSecondary,
                    fontSize: 9,
                  ),
                ),
                if (widget.isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all,
                    size: 12,
                    color: widget.message.isRead
                        ? const Color(0xFF34B7F1)
                        : Colors.white60,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TelegramMediaWidget extends StatefulWidget {
  final String telegramFileId;
  final Widget Function(BuildContext context, String url, bool isImage, String fileName) builder;

  const TelegramMediaWidget({
    super.key,
    required this.telegramFileId,
    required this.builder,
  });

  @override
  State<TelegramMediaWidget> createState() => _TelegramMediaWidgetState();
}

class _TelegramMediaWidgetState extends State<TelegramMediaWidget> {
  static final Map<String, ({String url, bool isImage, String fileName, DateTime resolvedAt})> _urlCache = {};

  bool _loading = true;
  String? _error;
  String? _url;
  bool _isImage = false;
  String _fileName = '';

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant TelegramMediaWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.telegramFileId != widget.telegramFileId) {
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final cached = _urlCache[widget.telegramFileId];
    if (cached != null && DateTime.now().difference(cached.resolvedAt).inMinutes < 45) {
      if (mounted) {
        setState(() {
          _url = cached.url;
          _isImage = cached.isImage;
          _fileName = cached.fileName;
          _loading = false;
        });
      }
      return;
    }

    if (mounted) setState(() => _loading = true);

    try {
      final info = await TelegramStorageService().getFileInfo(widget.telegramFileId);
      _urlCache[widget.telegramFileId] = (
        url: info.url,
        isImage: info.isImage,
        fileName: info.fileName,
        resolvedAt: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _url = info.url;
          _isImage = info.isImage;
          _fileName = info.fileName;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.medium),
        child: SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_error != null || _url == null) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.medium),
        child: Icon(Icons.broken_image_rounded, color: AppColors.error),
      );
    }
    return widget.builder(context, _url!, _isImage, _fileName);
  }
}

