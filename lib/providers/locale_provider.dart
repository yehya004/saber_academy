import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controls the active locale, detects the device locale on startup,
/// and supports Arabic (AR), English (EN), and Turkish (TR).
class LocaleProvider extends ChangeNotifier {
  LocaleProvider({String? initialLanguageCode}) {
    _initLocale(initialLanguageCode);
  }

  Locale _locale = const Locale('ar'); // Fallback placeholder
  bool _hasSavedLocale = false;
  static const String _prefKey = 'app_language_pref';

  Locale get locale => _locale;
  bool   get isArabic => _locale.languageCode == 'ar';
  bool   get hasSavedLocale => _hasSavedLocale;

  void _initLocale(String? initialLanguageCode) {
    if (initialLanguageCode != null &&
        (initialLanguageCode == 'en' || initialLanguageCode == 'tr' || initialLanguageCode == 'ar')) {
      _locale = Locale(initialLanguageCode);
      _hasSavedLocale = true;
      return;
    }

    try {
      final deviceLocale = PlatformDispatcher.instance.locale;
      final langCode = deviceLocale.languageCode;
      if (langCode == 'en' || langCode == 'tr' || langCode == 'ar') {
        _locale = Locale(langCode);
      } else {
        _locale = const Locale('en'); // Default fallback if not AR, EN, or TR
      }
    } catch (_) {
      _locale = const Locale('ar'); // Fallback on error
    }
  }

  Future<void> setLocale(Locale locale) async {
    _hasSavedLocale = true;
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, locale.languageCode);
    } catch (_) {}
  }

  Future<void> toggleLocale() async {
    Locale next;
    if (_locale.languageCode == 'ar') {
      next = const Locale('en');
    } else if (_locale.languageCode == 'en') {
      next = const Locale('tr');
    } else {
      next = const Locale('ar');
    }
    await setLocale(next);
  }
}
