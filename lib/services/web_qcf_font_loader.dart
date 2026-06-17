import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:archive/archive.dart';

class WebQcfFontLoader {
  static final Set<int> _loadedPages = {};
  static final Map<int, Future<void>> _loadingTasks = {};

  static Future<void> preloadPages(int currentPage, {int radius = 5}) async {
    List<int> pages = [];
    for (int i = 0; i <= radius; i++) {
      if (i == 0) {
        pages.add(currentPage);
      } else {
        int next = currentPage + i;
        int prev = currentPage - i;
        if (next <= 604) pages.add(next);
        if (prev >= 1) pages.add(prev);
      }
    }

    for (int page in pages) {
      if (_loadedPages.contains(page) || _loadingTasks.containsKey(page)) {
        continue;
      }
      await ensureFontLoaded(page);
    }
  }

  static Future<void> ensureFontLoaded(int pageNumber) {
    if (_loadedPages.contains(pageNumber)) return Future.value();
    if (_loadingTasks.containsKey(pageNumber)) {
      return _loadingTasks[pageNumber]!;
    }

    final task = _loadFontInternal(pageNumber);
    _loadingTasks[pageNumber] = task;

    task.then((_) {
      _loadedPages.add(pageNumber);
    }).whenComplete(() {
      _loadingTasks.remove(pageNumber);
    });

    return task;
  }

  static Future<void> _loadFontInternal(int pageNumber) async {
    final fontName = 'QCF4_tajweed_${pageNumber.toString().padLeft(3, '0')}';
    try {
      // Load zip bytes from assets
      final data = await rootBundle.load(
        'packages/qcf_quran_plus/assets/fonts/qcf_tajweed/$fontName.zip',
      );
      final zipBytes = data.buffer.asUint8List();

      // Extract TTF from zip (directly on Web main thread to bypass Isolate.run)
      final archive = ZipDecoder().decodeBytes(zipBytes);
      Uint8List? fontBytes;
      for (final file in archive) {
        if (file.name.endsWith('.ttf')) {
          fontBytes = Uint8List.fromList(file.content as List<int>);
          break;
        }
      }

      if (fontBytes == null) {
        throw Exception("Font not found in archive");
      }

      // Register font dynamically in Flutter engine
      final loader = FontLoader(fontName);
      loader.addFont(Future.value(ByteData.view(fontBytes.buffer)));
      await loader.load();
    } catch (e) {
      // Silence or print non-blocking error
      debugPrint("WebQcfFontLoader error loading page $pageNumber: $e");
    }
  }
}
