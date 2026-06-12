import 'dart:io';

import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';

class StorageService {
  final _client = Supabase.instance.client;

  static const _homeworkBucket = 'homework-images';
  static const _chatBucket = 'chat-images';

  /// Validates [file] size and MIME type before upload.
  /// Throws [ArgumentError] if validation fails.
  void _validateImage(File file) {
    final bytes = file.lengthSync();
    if (bytes > AppConstants.maxUploadBytes) {
      throw ArgumentError(
        'حجم الملف (${(bytes / (1024 * 1024)).toStringAsFixed(1)} ميجابايت) يتجاوز الحد المسموح به (5 ميجابايت).',
      );
    }

    final mime = lookupMimeType(file.path);
    if (mime == null || !AppConstants.allowedImageMimeTypes.contains(mime)) {
      throw ArgumentError(
        'نوع الملف غير مدعوم. المسموح به: JPEG، PNG، WebP فقط.',
      );
    }
  }

  /// Returns the content-type string for [file], defaulting to image/jpeg.
  String _contentType(File file) => lookupMimeType(file.path) ?? 'image/jpeg';

  /// Uploads a student's homework image and returns its public URL.
  /// Path structure: {studentId}/{homeworkId}/{timestamp}.jpg
  Future<String> uploadHomeworkImage({
    required File imageFile,
    required String studentId,
    required String homeworkId,
  }) async {
    _validateImage(imageFile);
    final ext = imageFile.path.split('.').last.toLowerCase();
    final path =
        '$studentId/$homeworkId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage.from(_homeworkBucket).upload(
          path,
          imageFile,
          fileOptions: FileOptions(
            contentType: _contentType(imageFile),
            upsert: false,
          ),
        );

    return _client.storage.from(_homeworkBucket).getPublicUrl(path);
  }

  /// Uploads a teacher's correction image and returns its public URL.
  /// Path structure: corrections/{homeworkId}/{timestamp}.jpg
  Future<String> uploadCorrectionImage({
    required File imageFile,
    required String homeworkId,
  }) async {
    _validateImage(imageFile);
    final ext = imageFile.path.split('.').last.toLowerCase();
    final path =
        'corrections/$homeworkId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage.from(_homeworkBucket).upload(
          path,
          imageFile,
          fileOptions: FileOptions(
            contentType: _contentType(imageFile),
            upsert: false,
          ),
        );

    return _client.storage.from(_homeworkBucket).getPublicUrl(path);
  }

  /// Uploads a chat image and returns its public URL.
  /// Path structure: {senderId}/{timestamp}.jpg
  Future<String> uploadChatImage({
    required File imageFile,
    required String senderId,
  }) async {
    _validateImage(imageFile);
    final ext = imageFile.path.split('.').last.toLowerCase();
    final path = '$senderId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage.from(_chatBucket).upload(
          path,
          imageFile,
          fileOptions: FileOptions(
            contentType: _contentType(imageFile),
            upsert: false,
          ),
        );

    return _client.storage.from(_chatBucket).getPublicUrl(path);
  }

  /// Uploads a generic chat file (pdf, doc, audio, zip, etc.) and returns its public URL.
  /// Strictly checks file size limit is under 10 MB.
  Future<String> uploadChatFile({
    required File file,
    required String senderId,
  }) async {
    final bytes = file.lengthSync();
    if (bytes > 10 * 1024 * 1024) {
      throw ArgumentError('حجم الملف يتجاوز الحد المسموح به (10 ميجابايت).');
    }

    final ext = file.path.split('.').last.toLowerCase();
    final path = '$senderId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

    await _client.storage.from('chat-files').upload(
          path,
          file,
          fileOptions: FileOptions(
            contentType: mimeType,
            upsert: false,
          ),
        );

    return _client.storage.from('chat-files').getPublicUrl(path);
  }
}
