import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MushafCoordinateService {
  static final MushafCoordinateService _instance = MushafCoordinateService._internal();
  factory MushafCoordinateService() => _instance;

  MushafCoordinateService._internal();

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  static const String _coordinateBaseUrl = 'https://raw.githubusercontent.com/rayed/Quran/master/json/';

  Map<String, dynamic>? _diyanetCache;

  /// Loads and parses Diyanet coordinates from assets.
  Future<List<dynamic>?> getDiyanetPageCoordinates(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > 605) return null;

    if (_diyanetCache == null) {
      try {
        final jsonStr = await rootBundle.loadString('assets/mushaf/diyanet/diyanet_coordinates.json');
        _diyanetCache = jsonDecode(jsonStr) as Map<String, dynamic>;
      } catch (e) {
        debugPrint("Error loading Diyanet coordinates from assets: $e");
        return null;
      }
    }

    final pageStr = pageNumber.toString();
    if (_diyanetCache != null && _diyanetCache!.containsKey(pageStr)) {
      return _diyanetCache![pageStr] as List<dynamic>;
    }
    return null;
  }

  /// Fetches and caches coordinates for the given Medina/Diyanet [pageNumber].
  /// Returns a list of ayah segments, or null if loading fails.
  Future<List<dynamic>?> getPageCoordinates(int pageNumber, {String mushafType = 'madina'}) async {
    if (mushafType == 'diyanet') {
      return getDiyanetPageCoordinates(pageNumber);
    }

    // Only Medina pages 1-604 are supported for coordinates in this dataset
    if (pageNumber < 1 || pageNumber > 604) return null;

    final cacheKey = 'mushaf_page_coords_$pageNumber';
    SharedPreferences? prefs;
    
    try {
      prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        return jsonDecode(cached) as List<dynamic>;
      }
    } catch (e) {
      debugPrint("Error reading SharedPreferences for coordinates cache: $e");
    }

    try {
      final response = await _dio.get('$_coordinateBaseUrl/page_$pageNumber.json');
      if (response.statusCode == 200 && response.data != null) {
        String rawJson;
        if (response.data is String) {
          rawJson = response.data as String;
        } else {
          rawJson = jsonEncode(response.data);
        }

        // Cache the raw JSON
        if (prefs != null) {
          await prefs.setString(cacheKey, rawJson);
        }

        return jsonDecode(rawJson) as List<dynamic>;
      }
    } catch (e) {
      debugPrint("Failed to fetch coordinates for page $pageNumber: $e");
    }

    return null;
  }
}
