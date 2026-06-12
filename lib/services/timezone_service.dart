import 'package:timezone/timezone.dart' as tz;

import '../models/lesson_schedule_model.dart';

/// Maps country names (Arabic & English) to IANA timezone identifiers and
/// converts times using the bundled IANA timezone database (via the `timezone`
/// package).  No network calls — DST is handled automatically.
///
/// Call [TimezoneService.initialize] once at app startup (after
/// initializeTimeZones()) before using any instance methods.
class TimezoneService {
  // ── Singleton ────────────────────────────────────────────────────────────
  static final TimezoneService _instance = TimezoneService._internal();
  factory TimezoneService() => _instance;
  TimezoneService._internal();

  // ── Country → IANA timezone ───────────────────────────────────────────────
  static const Map<String, String> countryTimezones = {
    // ── Arabic / Muslim-majority countries ────────────────────────────────
    'مصر':                         'Africa/Cairo',
    'السعودية':                    'Asia/Riyadh',
    'المملكة العربية السعودية':    'Asia/Riyadh',
    'الإمارات':                    'Asia/Dubai',
    'الإمارات العربية المتحدة':    'Asia/Dubai',
    'الكويت':                      'Asia/Kuwait',
    'قطر':                         'Asia/Qatar',
    'البحرين':                     'Asia/Bahrain',
    'عُمان':                       'Asia/Muscat',
    'عمان':                        'Asia/Muscat',
    'اليمن':                       'Asia/Aden',
    'الأردن':                      'Asia/Amman',
    'سوريا':                       'Asia/Damascus',
    'لبنان':                       'Asia/Beirut',
    'العراق':                      'Asia/Baghdad',
    'إيران':                       'Asia/Tehran',
    'تركيا':                       'Europe/Istanbul',
    'ليبيا':                       'Africa/Tripoli',
    'تونس':                        'Africa/Tunis',
    'المغرب':                      'Africa/Casablanca',
    'الجزائر':                     'Africa/Algiers',
    'السودان':                     'Africa/Khartoum',
    'الصومال':                     'Africa/Mogadishu',
    'إثيوبيا':                     'Africa/Addis_Ababa',
    'باكستان':                     'Asia/Karachi',
    'أفغانستان':                   'Asia/Kabul',
    'بنغلاديش':                    'Asia/Dhaka',
    'إندونيسيا':                   'Asia/Jakarta',
    'ماليزيا':                     'Asia/Kuala_Lumpur',
    'نيجيريا':                     'Africa/Lagos',
    'الهند':                       'Asia/Kolkata',
    // ── European / Western countries ──────────────────────────────────────
    'فرنسا':                       'Europe/Paris',
    'ألمانيا':                     'Europe/Berlin',
    'المملكة المتحدة':             'Europe/London',
    'بريطانيا':                    'Europe/London',
    'أمريكا':                      'America/New_York',
    'الولايات المتحدة':            'America/New_York',
    'الولايات المتحدة الأمريكية':  'America/New_York',
    'كندا':                        'America/Toronto',
    'أستراليا':                    'Australia/Sydney',
    'روسيا':                       'Europe/Moscow',
    'الصين':                       'Asia/Shanghai',
    'اليابان':                     'Asia/Tokyo',
    // ── English names ─────────────────────────────────────────────────────
    'Egypt':                       'Africa/Cairo',
    'Saudi Arabia':                'Asia/Riyadh',
    'UAE':                         'Asia/Dubai',
    'United Arab Emirates':        'Asia/Dubai',
    'Kuwait':                      'Asia/Kuwait',
    'Qatar':                       'Asia/Qatar',
    'Bahrain':                     'Asia/Bahrain',
    'Oman':                        'Asia/Muscat',
    'Yemen':                       'Asia/Aden',
    'Jordan':                      'Asia/Amman',
    'Syria':                       'Asia/Damascus',
    'Lebanon':                     'Asia/Beirut',
    'Iraq':                        'Asia/Baghdad',
    'Iran':                        'Asia/Tehran',
    'Turkey':                      'Europe/Istanbul',
    'Libya':                       'Africa/Tripoli',
    'Tunisia':                     'Africa/Tunis',
    'Morocco':                     'Africa/Casablanca',
    'Algeria':                     'Africa/Algiers',
    'Sudan':                       'Africa/Khartoum',
    'Somalia':                     'Africa/Mogadishu',
    'Pakistan':                    'Asia/Karachi',
    'Afghanistan':                 'Asia/Kabul',
    'Bangladesh':                  'Asia/Dhaka',
    'Indonesia':                   'Asia/Jakarta',
    'Malaysia':                    'Asia/Kuala_Lumpur',
    'Nigeria':                     'Africa/Lagos',
    'France':                      'Europe/Paris',
    'Germany':                     'Europe/Berlin',
    'UK':                          'Europe/London',
    'United Kingdom':              'Europe/London',
    'USA':                         'America/New_York',
    'United States':               'America/New_York',
    'Canada':                      'America/Toronto',
    'Australia':                   'Australia/Sydney',
    'Russia':                      'Europe/Moscow',
    'India':                       'Asia/Kolkata',
    'China':                       'Asia/Shanghai',
    'Japan':                       'Asia/Tokyo',
  };

  // ── Public API ────────────────────────────────────────────────────────────

  /// Returns the IANA timezone string for a country name (Arabic or English).
  /// Returns `null` if the country is unknown.
  String? getTimezone(String? countryName) {
    if (countryName == null || countryName.trim().isEmpty) return null;
    final key = countryName.trim();
    // 1. Exact match
    if (countryTimezones.containsKey(key)) return countryTimezones[key];
    // 2. Partial match: stored key is contained in input, or input is contained in stored key
    for (final entry in countryTimezones.entries) {
      if (key.contains(entry.key) || entry.key.contains(key)) {
        return entry.value;
      }
    }
    return null;
  }

  /// Human-readable timezone city name, e.g. "Africa/Cairo" → "Cairo".
  String timezoneCity(String? countryName) {
    final tzId = getTimezone(countryName) ?? 'UTC';
    return tzId.split('/').last.replaceAll('_', ' ');
  }

  /// Returns the **current** UTC offset in minutes for [ianaTimezone],
  /// using the bundled IANA database (handles DST automatically).
  int getUtcOffsetMinutes(String ianaTimezone) {
    try {
      final location = tz.getLocation(ianaTimezone);
      final now      = tz.TZDateTime.now(location);
      return now.timeZoneOffset.inMinutes;
    } catch (_) {
      return 0;
    }
  }

  /// Converts a list of UTC [DayScheduleEntry] items to their local equivalents
  /// for [ianaTimezone].  Each entry keeps its own weekday + time conversion.
  Future<List<DayScheduleEntry>> entriesToLocal(
    List<DayScheduleEntry> utcEntries,
    String ianaTimezone,
  ) async {
    if (utcEntries.isEmpty) return [];
    final offset = getUtcOffsetMinutes(ianaTimezone);
    return utcEntries.map((e) {
      final result = _shift(e.hourUtc, e.minuteUtc, [e.dayOfWeek], offset);
      return DayScheduleEntry(
        dayOfWeek: result.days.first,
        hourUtc:   result.hour,
        minuteUtc: result.minute,
      );
    }).toList()
      ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
  }

  /// Converts local per-day entries to their UTC equivalents for [ianaTimezone].
  Future<List<DayScheduleEntry>> entriesToUtc(
    List<DayScheduleEntry> localEntries,
    String ianaTimezone,
  ) async {
    if (localEntries.isEmpty) return [];
    final offset = getUtcOffsetMinutes(ianaTimezone);
    return localEntries.map((e) {
      final result = _shift(e.hourUtc, e.minuteUtc, [e.dayOfWeek], -offset);
      return DayScheduleEntry(
        dayOfWeek: result.days.first,
        hourUtc:   result.hour,
        minuteUtc: result.minute,
      );
    }).toList()
      ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
  }

  /// Finds the next upcoming lesson [DateTime] (UTC) from per-day entries.
  DateTime nextLessonUtcFromEntries(List<DayScheduleEntry> utcEntries) {
    if (utcEntries.isEmpty) return DateTime.now().toUtc();

    final now       = DateTime.now().toUtc();
    final todayWday = now.weekday;
    final nowMins   = now.hour * 60 + now.minute;

    DateTime? best;

    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final wday = ((todayWday - 1 + dayOffset) % 7) + 1;
      for (final e in utcEntries) {
        if (e.dayOfWeek != wday) continue;
        final lessonMins = e.hourUtc * 60 + e.minuteUtc;
        if (dayOffset == 0 && lessonMins <= nowMins) continue;
        final d         = now.add(Duration(days: dayOffset));
        final candidate = DateTime.utc(d.year, d.month, d.day, e.hourUtc, e.minuteUtc);
        if (best == null || candidate.isBefore(best)) best = candidate;
      }
      if (best != null) break;
    }

    return best ?? now;
  }

  // ── Conversion helpers ────────────────────────────────────────────────────

  /// Converts UTC time + days list to local time for [ianaTimezone].
  Future<({int hour, int minute, List<int> days})> utcToLocal({
    required int       hourUtc,
    required int       minuteUtc,
    required List<int> daysUtc,
    required String    ianaTimezone,
  }) async {
    final offset = getUtcOffsetMinutes(ianaTimezone);
    return _shift(hourUtc, minuteUtc, daysUtc, offset);
  }

  /// Converts local time + days list to UTC for [ianaTimezone].
  Future<({int hour, int minute, List<int> days})> localToUtc({
    required int       localHour,
    required int       localMinute,
    required List<int> localDays,
    required String    ianaTimezone,
  }) async {
    final offset = getUtcOffsetMinutes(ianaTimezone);
    return _shift(localHour, localMinute, localDays, -offset);
  }

  // ── Private ───────────────────────────────────────────────────────────────

  ({int hour, int minute, List<int> days}) _shift(
    int h, int m, List<int> days, int offsetMinutes,
  ) {
    int total    = h * 60 + m + offsetMinutes;
    int dayShift = 0;

    if (total < 0) {
      dayShift = -1;
      total   += 24 * 60;
    } else if (total >= 24 * 60) {
      dayShift = 1;
      total   -= 24 * 60;
    }

    final newDays = days.map((d) {
      int nd = d + dayShift;
      if (nd < 1) nd += 7;
      if (nd > 7) nd -= 7;
      return nd;
    }).toList()..sort();

    return (hour: total ~/ 60, minute: total % 60, days: newDays);
  }
}
