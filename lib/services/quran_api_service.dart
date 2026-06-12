import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';

/// A single Ayah returned from api.alquran.cloud.
class QuranAyah {
  final int number; // global sequential (1–6236)
  final int numberInSurah;
  final String surahNameAr;
  final int surahNumber;
  final String text;

  const QuranAyah({
    required this.number,
    required this.numberInSurah,
    required this.surahNameAr,
    required this.surahNumber,
    required this.text,
  });

  factory QuranAyah.fromJson(Map<String, dynamic> j) => QuranAyah(
        number: (j['number'] as num).toInt(),
        numberInSurah: (j['numberInSurah'] as num).toInt(),
        surahNameAr: j['surah']['name'] as String,
        surahNumber: (j['surah']['number'] as num).toInt(),
        text: j['text'] as String,
      );

  /// Mishary Al-Afasy CDN audio URL.
  String get audioUrl =>
      'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$number.mp3';
}

/// All editions for a single Mushaf page.
class QuranPageBundle {
  final List<QuranAyah> arabic; // quran-uthmani
  final List<QuranAyah> english; // en.sahih
  final List<QuranAyah> turkish; // tr.diyanet
  final List<QuranAyah> tafsir; // ar.muyassar

  const QuranPageBundle({
    required this.arabic,
    required this.english,
    required this.turkish,
    required this.tafsir,
  });

  bool get isEmpty => arabic.isEmpty;
}

class QuranApiService {
  static const _base = 'https://api.alquran.cloud/v1';

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 20),
  ));

  // Simple in-memory page cache keyed by "page/edition".
  static final _cache = <String, List<QuranAyah>>{};

  static Future<File> _getLocalTafsirFile(String edition, int page) async {
    if (kIsWeb) throw UnsupportedError("File system not supported on web");
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/tafsir/$edition');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File('${dir.path}/$page.json');
  }

  static Future<bool> isTafsirDownloaded(String edition) async {
    if (kIsWeb) return false;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDir.path}/tafsir/$edition');
      if (!await dir.exists()) return false;
      int count = 0;
      for (int i = 1; i <= 604; i++) {
        final file = File('${dir.path}/$i.json');
        if (await file.exists() && file.lengthSync() > 0) {
          count++;
        }
      }
      return count == 604;
    } catch (_) {
      return false;
    }
  }

  static Future<void> deleteTafsir(String edition) async {
    if (kIsWeb) return;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDir.path}/tafsir/$edition');
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }

  static Future<void> downloadFullTafsir(
      String edition, void Function(double progress) onProgress) async {
    int downloaded = 0;
    // Download in parallel batches of 10
    const batchSize = 10;
    for (int i = 1; i <= 604; i += batchSize) {
      final end = (i + batchSize - 1).clamp(1, 604);
      final downloadFutures = <Future<void>>[];

      for (int page = i; page <= end; page++) {
        final localFile = await _getLocalTafsirFile(edition, page);
        if (await localFile.exists() && localFile.lengthSync() > 0) {
          downloaded++;
          continue;
        }

        downloadFutures.add(
          _fetchPage(page, edition).then((list) {
            if (list.isNotEmpty) {
              downloaded++;
              onProgress(downloaded / 604.0);
            }
          }).catchError((e) {
            debugPrint("Failed to download tafsir page $page: $e");
          }),
        );
      }

      await Future.wait(downloadFutures);
    }
    onProgress(1.0);
  }

  static Future<List<QuranAyah>> _fetchPage(int page, String edition) async {
    final key = '$page/$edition';
    if (_cache.containsKey(key)) return _cache[key]!;

    // 1. Try local cache
    if (!kIsWeb) {
      try {
        final localFile = await _getLocalTafsirFile(edition, page);
        if (await localFile.exists()) {
          final content = await localFile.readAsString();
          final list = (jsonDecode(content) as List)
              .map((a) => QuranAyah.fromJson(a as Map<String, dynamic>))
              .toList();
          _cache[key] = list;
          return list;
        }
      } catch (e) {
        debugPrint("Offline cache read failed for $edition page $page: $e");
      }
    }

    try {
      final res = await _dio.get('$_base/page/$page/$edition');
      if (res.statusCode == 200) {
        final list = (res.data['data']['ayahs'] as List)
            .map((a) => QuranAyah.fromJson(a as Map<String, dynamic>))
            .toList();
        _cache[key] = list;

        // 2. Save to local cache
        if (!kIsWeb) {
          try {
            final localFile = await _getLocalTafsirFile(edition, page);
            await localFile.writeAsString(jsonEncode(res.data['data']['ayahs']),
                flush: true);
          } catch (e) {
            debugPrint("Offline cache save failed for $edition page $page: $e");
          }
        }

        return list;
      }
    } catch (_) {}
    return [];
  }

  static Future<List<QuranAyah>> _safeFetch(int page, String edition) async {
    try {
      return await _fetchPage(page, edition);
    } catch (_) {
      return [];
    }
  }

  // Overlapping Medina pages for Diyanet pages 583 to 605
  static const Map<int, List<int>> _diyanetOverlappingPages = {
    583: [583],
    584: [583, 584],
    585: [584, 585],
    586: [585, 586],
    587: [586, 587],
    588: [587, 588],
    589: [588, 589],
    590: [589, 590],
    591: [590, 591],
    592: [591, 592],
    593: [592, 593],
    594: [593, 594],
    595: [594, 595],
    596: [595, 596],
    597: [596, 597],
    598: [597],
    599: [598, 599],
    600: [599, 600],
    601: [600],
    602: [601],
    603: [602],
    604: [603],
    605: [604],
  };

  // Global verse ranges (1-based index) for Diyanet pages 583 to 605
  static const Map<int, List<int>> _diyanetPageRanges = {
    583: [5703, 5726],
    584: [5727, 5758],
    585: [5759, 5791],
    586: [5792, 5820],
    587: [5821, 5848],
    588: [5849, 5874],
    589: [5875, 5897],
    590: [5898, 5920],
    591: [5921, 5948],
    592: [5949, 5978],
    593: [5979, 6007],
    594: [6008, 6030],
    595: [6031, 6058],
    596: [6059, 6082],
    597: [6083, 6103],
    598: [6104, 6125],
    599: [6126, 6138],
    600: [6139, 6157],
    601: [6158, 6176],
    602: [6177, 6193],
    603: [6194, 6207],
    604: [6208, 6221],
    605: [6222, 6236],
  };

  static Future<QuranPageBundle> fetchPage(int mushafPage,
      {bool isDiyanet = false}) async {
    // 1. Fetch from Diyanet API if API key is present
    final token = dotenv.env['DIB_KURAN_API_TOKEN'];
    final baseUrl =
        dotenv.env['DIB_KURAN_API_BASE_URL'] ?? 'https://api.diyanet.gov.tr';
    final Map<String, Map<String, String>> dibMap = {};

    if (token != null && token.trim().isNotEmpty) {
      try {
        final res = await _dio.get(
          '$baseUrl/api/v1/verses/page/$mushafPage',
          options: Options(
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          ),
        );
        if (res.statusCode == 200 &&
            res.data != null &&
            res.data['data'] != null) {
          final list = res.data['data'] as List;
          for (final item in list) {
            final int surahId = (item['surah_id'] as num).toInt();
            final int verseId = (item['verse_id_in_surah'] as num).toInt();
            final arabicText = item['arabic_script']?['text'] as String?;
            final turkishText = item['translation']?['text'] as String?;
            if (arabicText != null || turkishText != null) {
              dibMap['$surahId:$verseId'] = {
                if (arabicText != null) 'arabic': arabicText,
                if (turkishText != null) 'turkish': turkishText,
              };
            }
          }
        }
      } catch (e) {
        // Fail silently and log error (safe for release)
        debugPrint('Diyanet API error: $e');
      }
    }

    // 2. Fetch standard page bundle from api.alquran.cloud
    List<QuranAyah> arabicList = [];
    List<QuranAyah> englishList = [];
    List<QuranAyah> turkishList = [];
    List<QuranAyah> tafsirList = [];

    if (isDiyanet && mushafPage >= 583) {
      final pagesToFetch = _diyanetOverlappingPages[mushafPage] ?? [mushafPage];
      final List<List<QuranAyah>> mergedArabic = [];
      final List<List<QuranAyah>> mergedEnglish = [];
      final List<List<QuranAyah>> mergedTurkish = [];
      final List<List<QuranAyah>> mergedTafsir = [];

      for (final p in pagesToFetch) {
        final results = await Future.wait([
          _fetchPage(p, 'quran-uthmani'),
          _safeFetch(p, 'en.sahih'),
          _safeFetch(p, 'tr.diyanet'),
          _safeFetch(p, 'ar.muyassar'),
        ]);
        mergedArabic.add(results[0]);
        mergedEnglish.add(results[1]);
        mergedTurkish.add(results[2]);
        mergedTafsir.add(results[3]);
      }

      final range = _diyanetPageRanges[mushafPage]!;
      final startIdx = range[0];
      final endIdx = range[1];

      final flatArabic = mergedArabic.expand((x) => x).toList();
      final flatEnglish = mergedEnglish.expand((x) => x).toList();
      final flatTurkish = mergedTurkish.expand((x) => x).toList();
      final flatTafsir = mergedTafsir.expand((x) => x).toList();

      final seenArabic = <int>{};
      final seenEnglish = <int>{};
      final seenTurkish = <int>{};
      final seenTafsir = <int>{};

      for (final verse in flatArabic) {
        if (verse.number >= startIdx &&
            verse.number <= endIdx &&
            !seenArabic.contains(verse.number)) {
          arabicList.add(verse);
          seenArabic.add(verse.number);
        }
      }
      for (final verse in flatEnglish) {
        if (verse.number >= startIdx &&
            verse.number <= endIdx &&
            !seenEnglish.contains(verse.number)) {
          englishList.add(verse);
          seenEnglish.add(verse.number);
        }
      }
      for (final verse in flatTurkish) {
        if (verse.number >= startIdx &&
            verse.number <= endIdx &&
            !seenTurkish.contains(verse.number)) {
          turkishList.add(verse);
          seenTurkish.add(verse.number);
        }
      }
      for (final verse in flatTafsir) {
        if (verse.number >= startIdx &&
            verse.number <= endIdx &&
            !seenTafsir.contains(verse.number)) {
          tafsirList.add(verse);
          seenTafsir.add(verse.number);
        }
      }
    } else {
      final results = await Future.wait([
        _fetchPage(mushafPage, 'quran-uthmani'),
        _safeFetch(mushafPage, 'en.sahih'),
        _safeFetch(mushafPage, 'tr.diyanet'),
        _safeFetch(mushafPage, 'ar.muyassar'),
      ]);
      arabicList = results[0];
      englishList = results[1];
      turkishList = results[2];
      tafsirList = results[3];
    }

    // 3. Merge Diyanet data if successfully fetched
    if (dibMap.isNotEmpty) {
      if (arabicList.isNotEmpty) {
        arabicList = arabicList.map((verse) {
          final key = '${verse.surahNumber}:${verse.numberInSurah}';
          if (dibMap.containsKey(key) && dibMap[key]!.containsKey('arabic')) {
            return QuranAyah(
              number: verse.number,
              numberInSurah: verse.numberInSurah,
              surahNameAr: verse.surahNameAr,
              surahNumber: verse.surahNumber,
              text: dibMap[key]!['arabic']!,
            );
          }
          return verse;
        }).toList();
      }

      if (turkishList.isNotEmpty) {
        turkishList = turkishList.map((verse) {
          final key = '${verse.surahNumber}:${verse.numberInSurah}';
          if (dibMap.containsKey(key) && dibMap[key]!.containsKey('turkish')) {
            return QuranAyah(
              number: verse.number,
              numberInSurah: verse.numberInSurah,
              surahNameAr: verse.surahNameAr,
              surahNumber: verse.surahNumber,
              text: dibMap[key]!['turkish']!,
            );
          }
          return verse;
        }).toList();
      }
    }

    return QuranPageBundle(
      arabic: arabicList,
      english: englishList,
      turkish: turkishList,
      tafsir: tafsirList,
    );
  }
}
