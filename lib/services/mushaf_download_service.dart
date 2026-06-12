import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'mushaf_coordinate_service.dart';

class MushafDownloadService {
  static final MushafDownloadService _instance = MushafDownloadService._internal();
  factory MushafDownloadService() => _instance;
  MushafDownloadService._internal();

  final _dio = Dio();
  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;

  /// Returns the base directory for local mushaf pages
  Future<Directory> _getMushafDir(String type) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/mushaf/$type');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Checks if pages are essentially fully downloaded (≥99%) for a given type
  Future<bool> isDownloaded(String type) async {
    try {
      final dir = await _getMushafDir(type);
      final total = type == 'diyanet' ? 605 : 604;
      int count = 0;
      for (int i = 1; i <= total; i++) {
        final file = File('${dir.path}/$i.png');
        if (await file.exists() && file.lengthSync() > 0) {
          count++;
        }
      }
      // Consider downloaded if ≥99% of pages are present (allows 1-6 failed pages)
      return count >= (total * 0.99).ceil();
    } catch (_) {
      return false;
    }
  }

  /// Returns the total size of downloaded files for a type in MB (0.0 if not downloaded)
  Future<double> getDirSizeInMB(String type) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDir.path}/mushaf/$type');
      if (!await dir.exists()) return 0.0;
      int totalBytes = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          totalBytes += await entity.length();
        }
      }
      return totalBytes / (1024 * 1024);
    } catch (_) {
      return 0.0;
    }
  }

  /// Returns the number of downloaded pages for a given type
  Future<int> getDownloadedPagesCount(String type) async {
    try {
      final dir = await _getMushafDir(type);
      if (!await dir.exists()) return 0;
      final total = type == 'diyanet' ? 605 : 604;
      int count = 0;
      for (int i = 1; i <= total; i++) {
        final file = File('${dir.path}/$i.png');
        if (await file.exists() && file.lengthSync() > 0) {
          count++;
        }
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  /// Deletes all downloaded pages for a given type
  Future<void> deleteMushaf(String type) async {
    try {
      final dir = await _getMushafDir(type);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint("Failed to delete mushaf directory for $type: $e");
    }
  }

  /// Returns the local file path for a page if it exists, otherwise null
  Future<String?> getLocalFilePath(String type, int pageNum) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final file = File('${appDir.path}/mushaf/$type/$pageNum.png');
      if (await file.exists()) {
        return file.path;
      }
    } catch (_) {}
    return null;
  }

  /// Starts downloading all pages for a given type (madina, tajweed, or diyanet)
  Future<void> startDownload({
    required String type,
    required void Function(double progress) onProgress,
    required VoidCallback onCompleted,
    required void Function(String error) onError,
  }) async {
    if (_isDownloading) {
      onError('هناك عملية تحميل قيد التشغيل بالفعل.');
      return;
    }

    _isDownloading = true;
    try {
      final dir = await _getMushafDir(type);
      int downloaded = 0;
      final total = type == 'diyanet' ? 605 : 604;

      // We will download in parallel chunks of 10 pages to speed up the process
      const batchSize = 10;
      for (int i = 1; i <= total; i += batchSize) {
        if (!_isDownloading) break; // User cancelled or stopped

        final end = (i + batchSize - 1).clamp(1, total);
        final downloadFutures = <Future<void>>[];

        for (int page = i; page <= end; page++) {
          final file = File('${dir.path}/$page.png');
          
          // Skip if already exists
          if (await file.exists() && file.lengthSync() > 0) {
            downloaded++;
            continue;
          }

          final url = _getUrlForPage(type, page);
          downloadFutures.add(
            _dio.download(url, file.path).then((_) {
              downloaded++;
              onProgress(downloaded / total.toDouble());
              // Pre-fetch and cache the coordinates of this page in the background
              if (type == 'madina' || type == 'tajweed') {
                MushafCoordinateService().getPageCoordinates(page).catchError((e) {
                  debugPrint("Background coordinates download failed for page $page: $e");
                  return null;
                });
              }
            }).catchError((e) {
              debugPrint("Failed to download page $page: $e");
              // Try to clean up broken file
              if (file.existsSync()) file.deleteSync();
            }),
          );
        }

        // Wait for this batch to complete
        await Future.wait(downloadFutures);
      }

      final success = await isDownloaded(type);
      _isDownloading = false;

      if (success) {
        onCompleted();
      } else {
        onError('فشل تحميل بعض الصفحات. يرجى إعادة المحاولة.');
      }
    } catch (e) {
      _isDownloading = false;
      onError('حدث خطأ أثناء الاتصال بالخادم: $e');
    }
  }

  /// Cancel running download
  void cancelDownload() {
    _isDownloading = false;
  }

  String _getUrlForPage(String type, int pageNum) {
    if (type == 'tajweed') {
      return 'https://raw.githubusercontent.com/QuranHub/quran-pages-images/main/ayat/tajweed/$pageNum.png';
    }
    if (type == 'diyanet') {
      final padded = (pageNum + 1).toString().padLeft(3, '0');
      return 'https://raw.githubusercontent.com/yehya004/diyanet-mushaf-images/main/$padded.png';
    }
    // Madina
    final padded = pageNum.toString().padLeft(3, '0');
    return 'https://raw.githubusercontent.com/GovarJabbar/Quran-PNG/master/$padded.png';
  }
}
