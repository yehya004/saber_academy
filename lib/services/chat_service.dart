import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';
import '../models/chat_message_model.dart';
import 'local_db_service.dart';

class ChatService {
  final _client = Supabase.instance.client;

  /// Real-time stream of messages between [userId] and [partnerId].
  /// Uses Supabase Realtime — ensure the table is added to supabase_realtime
  /// publication (see schema.sql comment at the bottom).
  Stream<List<ChatMessageModel>> messageStream({
    required String userId,
    required String partnerId,
  }) {
    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map(
          (rows) {
            final list = rows
                .where(
                  (m) =>
                      (m['sender_id'] == userId &&
                          m['receiver_id'] == partnerId) ||
                      (m['sender_id'] == partnerId && m['receiver_id'] == userId),
                )
                .map(ChatMessageModel.fromMap)
                .toList();

            // Cache messages locally in SQLite
            LocalDatabaseService().saveMessages(list).catchError((e) {
              debugPrint("Failed to save chat cache: $e");
            });

            return list;
          },
        );
  }

  /// Get locally cached messages
  Future<List<ChatMessageModel>> getCachedMessages({
    required String userId,
    required String partnerId,
  }) async {
    return LocalDatabaseService().getMessages(userId: userId, partnerId: partnerId);
  }

  /// Fetch messages directly from Supabase via HTTP (fallback for polling).
  Future<List<ChatMessageModel>> fetchMessages({
    required String userId,
    required String partnerId,
  }) async {
    final response = await _client
        .from('chat_messages')
        .select()
        .or('and(sender_id.eq.$userId,receiver_id.eq.$partnerId),and(sender_id.eq.$partnerId,receiver_id.eq.$userId)')
        .order('created_at', ascending: true);

    final list = (response as List)
        .map((row) => ChatMessageModel.fromMap(row as Map<String, dynamic>))
        .toList();

    // Cache messages locally in SQLite
    LocalDatabaseService().saveMessages(list).catchError((e) {
      debugPrint("Failed to save chat cache during HTTP fetch: $e");
    });

    return list;
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String messageText,
    String? imageUrl,
    String? fileUrl,
    String? fileName,
    String? telegramFileId,
    String? replyToId,
    String? replyToText,
    String? replyToSenderName,
  }) {
    final trimmed = messageText.trim();
    if (trimmed.isEmpty && imageUrl == null && fileUrl == null && telegramFileId == null) {
      throw ArgumentError('لا يمكن إرسال رسالة فارغة.');
    }
    if (trimmed.length > AppConstants.maxMessageLength) {
      throw ArgumentError(
        'الرسالة تتجاوز الحد الأقصى (${AppConstants.maxMessageLength} حرف).',
      );
    }

    String defaultText = trimmed;
    if (defaultText.isEmpty) {
      if (imageUrl != null) {
        defaultText = '📷';
      } else if (fileName != null) {
        defaultText = fileName;
      } else {
        defaultText = '📁';
      }
    }

    return _client.from('chat_messages').insert({
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message_text': defaultText,
      if (imageUrl != null) 'image_url': imageUrl,
      if (fileUrl != null) 'file_url': fileUrl,
      if (fileName != null) 'file_name': fileName,
      if (telegramFileId != null) 'telegram_file_id': telegramFileId,
      if (replyToId != null) 'reply_to_id': replyToId,
      if (replyToText != null) 'reply_to_text': replyToText,
      if (replyToSenderName != null) 'reply_to_sender_name': replyToSenderName,
    });
  }

  /// Marks all unread messages sent by [senderId] to [receiverId] as read.
  Future<void> markMessagesAsRead({
    required String receiverId,
    required String senderId,
  }) =>
      _client
          .from('chat_messages')
          .update({'is_read': true})
          .eq('receiver_id', receiverId)
          .eq('sender_id', senderId)
          .eq('is_read', false);

  /// Returns the count of unread messages for [userId] (as receiver).
  Future<int> getUnreadCount(String userId) async {
    final res = await _client
        .from('chat_messages')
        .select('id')
        .eq('receiver_id', userId)
        .eq('is_read', false);
    return res.length;
  }

  /// Soft deletes a message by updating is_deleted to true.
  Future<void> deleteMessage(String id) =>
      _client.from('chat_messages').update({'is_deleted': true}).eq('id', id);
}
