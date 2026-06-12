import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class QuranDatabaseHelper {
  static final QuranDatabaseHelper _instance = QuranDatabaseHelper._internal();
  factory QuranDatabaseHelper() => _instance;
  QuranDatabaseHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (kIsWeb) throw UnsupportedError('SQLite is not supported on Web');
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'quran_text_v3.db');

    // Check if database exists in documents/databases, if not copy it from assets
    final exists = await databaseExists(path);
    if (!exists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      // Copy from assets
      final data = await rootBundle.load('assets/quran/database.sqlite');
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
    }

    return await openDatabase(path, readOnly: true);
  }

  /// Fetches lines for a given Medina page (1-604) from the page_lines table.
  Future<List<Map<String, dynamic>>> getLinesForPage(int page) async {
    if (kIsWeb) return [];
    try {
      final db = await database;
      return await db.rawQuery('''
        SELECT page, line_number, line_type, sura, ayah, text_ar, tokens_json
        FROM page_lines
        WHERE page = ?
        ORDER BY line_number ASC
      ''', [page]);
    } catch (e) {
      return [];
    }
  }

  /// Fetches verses for a given Medina page (1-604).
  /// Joins with the surahs table to get surah name.
  Future<List<Map<String, dynamic>>> getVersesForPage(int page) async {
    if (kIsWeb) return [];
    try {
      final db = await database;
      return await db.rawQuery('''
        SELECT 
          v.surah_number, 
          v.number AS number_in_surah, 
          v.text_ar, 
          v.text_en, 
          v.juz, 
          v.page,
          s.name_ar AS surah_name_ar,
          s.name_en AS surah_name_en,
          s.name_transliteration AS surah_name_trans
        FROM verses v
        JOIN surahs s ON v.surah_number = s.number
        WHERE v.page = ?
        ORDER BY v.surah_number ASC, v.number ASC
      ''', [page]);
    } catch (e) {
      // Return empty list on failure
      return [];
    }
  }

  // Cache all verses for quick offline search
  static List<Map<String, dynamic>>? _cachedSearchVerses;

  static String removeDiacritics(String input) {
    // Regex pattern for all Arabic tashkeel / diacritics
    final diacritics = RegExp(
      r'[\u064B-\u0652\u0653-\u065F\u0670\u06D6-\u06ED]'
    );
    String normalized = input.replaceAll(diacritics, '');
    
    // Normalize Alifs: أ, إ, آ to plain Alif (ا)
    normalized = normalized.replaceAll(RegExp(r'[أإآ]'), 'ا');
    
    // Normalize Teh Marbuta ة to ه
    normalized = normalized.replaceAll('ة', 'ه');
    
    // Normalize Yeh ى to ي
    normalized = normalized.replaceAll('ى', 'ي');
    
    return normalized;
  }

  /// Searches for verses matching the query (without diacritics).
  Future<List<Map<String, dynamic>>> searchVerses(String query) async {
    if (query.trim().isEmpty) return [];
    if (kIsWeb) return [];
    try {
      if (_cachedSearchVerses == null) {
        final db = await database;
        _cachedSearchVerses = await db.rawQuery('''
          SELECT 
            v.surah_number, 
            v.number AS number_in_surah, 
            v.text_ar, 
            v.page,
            s.name_ar AS surah_name_ar,
            s.name_en AS surah_name_en
          FROM verses v
          JOIN surahs s ON v.surah_number = s.number
          ORDER BY v.surah_number ASC, v.number ASC
        ''');
      }

      final normalizedQuery = removeDiacritics(query.trim());
      final results = <Map<String, dynamic>>[];
      
      for (final row in _cachedSearchVerses!) {
        final textAr = row['text_ar'] as String? ?? '';
        final normalizedText = removeDiacritics(textAr);
        if (normalizedText.contains(normalizedQuery)) {
          results.add(row);
        }
      }
      return results;
    } catch (e) {
      debugPrint("Search verses failed: $e");
      return [];
    }
  }
}
