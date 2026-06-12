import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/chat_message_model.dart';

class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'offline_cache.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cached_chat_messages (
            id TEXT PRIMARY KEY,
            sender_id TEXT NOT NULL,
            receiver_id TEXT NOT NULL,
            message_text TEXT NOT NULL,
            is_read INTEGER NOT NULL,
            created_at TEXT NOT NULL,
            image_url TEXT,
            file_url TEXT,
            file_name TEXT,
            telegram_file_id TEXT,
            is_deleted INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute('ALTER TABLE cached_chat_messages ADD COLUMN telegram_file_id TEXT;');
          } catch (e) {
            // Already exists or other SQLite error
          }
        }
        if (oldVersion < 3) {
          try {
            await db.execute('ALTER TABLE cached_chat_messages ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0;');
          } catch (e) {
            // Already exists or other SQLite error
          }
        }
      },
    );
  }

  /// Bulk insert or update chat messages in local SQLite database
  Future<void> saveMessages(List<ChatMessageModel> messages) async {
    final db = await database;
    final batch = db.batch();
    for (final msg in messages) {
      batch.insert(
        'cached_chat_messages',
        {
          'id': msg.id,
          'sender_id': msg.senderId,
          'receiver_id': msg.receiverId,
          'message_text': msg.messageText,
          'is_read': msg.isRead ? 1 : 0,
          'created_at': msg.createdAt.toIso8601String(),
          'image_url': msg.imageUrl,
          'file_url': msg.fileUrl,
          'file_name': msg.fileName,
          'telegram_file_id': msg.telegramFileId,
          'is_deleted': msg.isDeleted ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Fetch cached messages between user and partner
  Future<List<ChatMessageModel>> getMessages({
    required String userId,
    required String partnerId,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cached_chat_messages',
      where: '(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)',
      whereArgs: [userId, partnerId, partnerId, userId],
      orderBy: 'created_at ASC',
    );

    return List.generate(maps.length, (i) {
      final map = maps[i];
      return ChatMessageModel(
        id: map['id'] as String,
        senderId: map['sender_id'] as String,
        receiverId: map['receiver_id'] as String,
        messageText: map['message_text'] as String,
        isRead: (map['is_read'] as int) == 1,
        createdAt: DateTime.parse(map['created_at'] as String),
        imageUrl: map['image_url'] as String?,
        fileUrl: map['file_url'] as String?,
        fileName: map['file_name'] as String?,
        telegramFileId: map['telegram_file_id'] as String?,
        isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
      );
    });
  }

}
