/// Mirrors the `chat_messages` table in Supabase.
class ChatMessageModel {
  final String  id;
  final String  senderId;
  final String  receiverId;
  final String  messageText;
  final bool    isRead;
  final DateTime createdAt;
  final String? imageUrl;   // optional image attachment
  final String? fileUrl;    // optional general file attachment
  final String? fileName;   // optional general file name
  final String? telegramFileId; // optional Telegram file ID
  final bool    isDeleted;

  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.messageText,
    required this.isRead,
    required this.createdAt,
    this.imageUrl,
    this.fileUrl,
    this.fileName,
    this.telegramFileId,
    this.isDeleted = false,
  });

  bool get wasAttachment =>
      (imageUrl != null && imageUrl!.isNotEmpty) ||
      (fileUrl != null && fileUrl!.isNotEmpty) ||
      (telegramFileId != null && telegramFileId!.isNotEmpty);

  bool get isImage {
    if (imageUrl != null && imageUrl!.isNotEmpty) return true;
    if (telegramFileId != null && fileName != null) {
      final nameLower = fileName!.toLowerCase();
      return nameLower.endsWith('.jpg') ||
          nameLower.endsWith('.jpeg') ||
          nameLower.endsWith('.png') ||
          nameLower.endsWith('.gif') ||
          nameLower.endsWith('.webp') ||
          nameLower.endsWith('.bmp');
    }
    return false;
  }
  bool get isAudio {
    final url = fileUrl ?? fileName;
    if (url == null || url.isEmpty) return false;
    final urlLower = url.toLowerCase();
    return urlLower.endsWith('.m4a') ||
        urlLower.endsWith('.mp3') ||
        urlLower.endsWith('.wav') ||
        urlLower.endsWith('.aac') ||
        urlLower.endsWith('.ogg');
  }
  bool get isFile {
    if (telegramFileId != null && !isImage && !isAudio) return true;
    return fileUrl != null && fileUrl!.isNotEmpty && !isAudio;
  }

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) => ChatMessageModel(
        id:          map['id']           as String,
        senderId:    map['sender_id']    as String,
        receiverId:  map['receiver_id']  as String,
        messageText: map['message_text'] as String? ?? '',
        isRead:      map['is_read']      as bool,
        createdAt:   DateTime.parse(map['created_at'] as String),
        imageUrl:    map['image_url']    as String?,
        fileUrl:     map['file_url']     as String?,
        fileName:    map['file_name']    as String?,
        telegramFileId: map['telegram_file_id'] as String?,
        isDeleted:   map['is_deleted']   as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'id':           id,
        'sender_id':    senderId,
        'receiver_id':  receiverId,
        'message_text': messageText,
        'is_read':      isRead,
        'created_at':   createdAt.toIso8601String(),
        'is_deleted':   isDeleted,
        if (imageUrl != null) 'image_url': imageUrl,
        if (fileUrl != null) 'file_url': fileUrl,
        if (fileName != null) 'file_name': fileName,
        if (telegramFileId != null) 'telegram_file_id': telegramFileId,
      };
}

