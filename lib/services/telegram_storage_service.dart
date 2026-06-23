import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

/// Handles file uploads/downloads via Telegram Bot API.
///
/// ⚠️ Security note: the bot token is embedded in the client.
/// Acceptable for a private academy app — not for a public app store release.
class TelegramStorageService {
  // ── Telegram credentials ──────────────────────────────────────────────────
  static const _botToken  = '8767281197:AAEQ0y2hussZGc_0CjM8dyI_w8bYX-4iNXE';
  static const _channelId = '-1003981828165';
  static String get _apiBase => kIsWeb
      ? 'https://cors.zme.ink/https://api.telegram.org/bot$_botToken'
      : 'https://api.telegram.org/bot$_botToken';
  static String get _fileBase => 'https://api.telegram.org/file/bot$_botToken';

  final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  // ── Upload ────────────────────────────────────────────────────────────────

  Future<String> uploadFile(
    dynamic file, {
    String? caption,
    String? fileName,
  }) async {
    final String name = fileName ?? (file is File ? file.path.split(kIsWeb ? '/' : Platform.pathSeparator).last : 'file.bin');
    
    MultipartFile multipartFile;
    if (file is Uint8List) {
      multipartFile = MultipartFile.fromBytes(file, filename: name);
    } else if (file is File) {
      if (kIsWeb) {
        throw UnsupportedError("Reading files from path is not supported on web. Use bytes.");
      }
      multipartFile = await MultipartFile.fromFile(file.path, filename: name);
    } else {
      throw ArgumentError("Invalid file type: expected File or Uint8List");
    }

    final formData = FormData.fromMap({
      'chat_id':  _channelId,
      'document': multipartFile,
      'caption':  caption ?? 'واجب طالب — ${DateTime.now().toIso8601String()}',
    });

    final res = await _dio.post(
      '$_apiBase/sendDocument',
      data: formData,
      options: Options(headers: {'Content-Type': 'multipart/form-data'}),
    );

    _assertOk(res);

    final result = res.data['result'] as Map<String, dynamic>;

    // Telegram returns 'document' for generic files
    if (result.containsKey('document')) {
      return result['document']['file_id'] as String;
    }
    // Small images are sometimes reclassified as 'photo'
    if (result.containsKey('photo')) {
      final photos = result['photo'] as List<dynamic>;
      return photos.last['file_id'] as String;
    }

    throw Exception('نوع ملف غير متوقع في استجابة تيليجرام');
  }

  // ── Download URL ──────────────────────────────────────────────────────────

  static const _imageExtensions = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'heif'};

  /// Resolves a stored [fileId] to a direct HTTPS download URL.
  /// Note: Telegram download links expire after ~1 hour — generate on demand.
  Future<String> getDownloadUrl(String fileId) async {
    final info = await getFileInfo(fileId);
    return info.url;
  }

  /// Returns the download [url] and whether the file [isImage].
  /// Use this to decide whether to open inline or trigger a download.
  Future<({String url, bool isImage, String fileName})> getFileInfo(String fileId) async {
    final res = await _dio.get(
      '$_apiBase/getFile',
      queryParameters: {'file_id': fileId},
    );

    _assertOk(res);

    final filePath = res.data['result']['file_path'] as String;
    final url      = '$_fileBase/$filePath';
    final ext      = filePath.split('.').last.toLowerCase();
    final fileName = filePath.split('/').last;
    return (url: url, isImage: _imageExtensions.contains(ext), fileName: fileName);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _assertOk(Response<dynamic> res) {
    if (res.statusCode != 200 || res.data['ok'] != true) {
      final desc = res.data['description'] ?? res.data.toString();
      throw Exception('Telegram API error: $desc');
    }
  }
}
