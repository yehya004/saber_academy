import 'package:flutter/foundation.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';
import 'web_qcf_font_loader.dart';

class AppQcfFontLoader {
  static Future<void> setupFontsAtStartup({
    required Function(double progress) onProgress,
  }) async {
    if (kIsWeb) {
      // On Web, we do not preload all 604 fonts on startup to avoid making 604 HTTP requests.
      // We only load them on demand.
      onProgress(1.0);
      return;
    } else {
      try {
        await QcfFontLoader.setupFontsAtStartup(
          onProgress: onProgress,
        );
      } catch (e) {
        debugPrint("QcfFontLoader setup error: $e");
      }
    }
  }

  static Future<void> preloadPages(int page, {int radius = 5}) async {
    if (kIsWeb) {
      await WebQcfFontLoader.preloadPages(page, radius: radius);
    } else {
      try {
        await QcfFontLoader.preloadPages(page, radius: radius);
      } catch (e) {
        debugPrint("QcfFontLoader preload error: $e");
      }
    }
  }
}
