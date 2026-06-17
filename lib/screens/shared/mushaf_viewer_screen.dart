import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/mushaf_download_service.dart';
import '../../services/quran_audio_service.dart';
import '../../services/quran_api_service.dart';
import '../../services/mushaf_coordinate_service.dart';
import '../../services/quran_database_helper.dart';
import '../../services/app_qcf_font_loader.dart';
import 'package:qcf_quran_plus/qcf_quran_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/data/quran_data.dart';
import '../../l10n/app_localizations.dart';
import 'tafsir_panel.dart';

// ── Screen ────────────────────────────────────────────────────────
class MushafViewerScreen extends StatefulWidget {
  const MushafViewerScreen({super.key});

  @override
  State<MushafViewerScreen> createState() => _MushafViewerScreenState();
}

class _MushafViewerScreenState extends State<MushafViewerScreen> {
  late PageController _pageController;
  PageController? _textPageController;
  int _page = 1; // mushaf page 1–604
  List<int> _bookmarks = [];
  bool _isReady = false;
  SharedPreferences? _prefs;
  final bool _showUI = true;
  String _mushafType = 'madina'; // 'madina' or 'tajweed' or 'text'
  int? _selectedSurahId;
  int? _selectedAyahId;
  Timer? _searchHighlightTimer;

  /// Base URL for Madina Mushaf page images (zero-padded 3-digit page number).
  static const String _imageBaseUrl =
      'https://raw.githubusercontent.com/GovarJabbar/Quran-PNG/master/';

  /// Total mushaf pages (Medina = 604, Diyanet = 605).
  int get _totalPages => _mushafType == 'diyanet' ? 605 : 604;

  // ── Lifecycle ─────────────────────────────────────────────────
  final _audioService = QuranAudioService();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _textPageController = PageController();
    _initPrefs();
    _audioService.addListener(_onAudioStateChanged);
  }

  @override
  void dispose() {
    _audioService.removeListener(_onAudioStateChanged);
    _pageController.dispose();
    _textPageController?.dispose();
    _searchHighlightTimer?.cancel();
    super.dispose();
  }

  void _onAudioStateChanged() {
    if (mounted) {
      final audioPage = _audioService.playingPage;
      if (audioPage != -1 && audioPage != _page) {
        setState(() {
          _page = audioPage;
        });
        if (_mushafType == 'text') {
          AppQcfFontLoader.preloadPages(audioPage, radius: 5);
          if (_textPageController != null && _textPageController!.hasClients) {
            _textPageController!.animateToPage(
              audioPage - 1,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        } else {
          if (_pageController.hasClients) {
            _pageController.animateToPage(
              _totalPages - audioPage,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          }
        }
      } else {
        setState(() {});
      }
    }
  }

  List<HighlightVerse> _getTextHighlights() {
    final List<HighlightVerse> highlights = [];
    if (_audioService.isPlaying &&
        _audioService.playingPage != -1 &&
        _audioService.bundle != null &&
        _audioService.playingAyahIndex >= 0 &&
        _audioService.playingAyahIndex < _audioService.bundle!.arabic.length) {
      final playingAyah = _audioService.bundle!.arabic[_audioService.playingAyahIndex];
      highlights.add(
        HighlightVerse(
          surah: playingAyah.surahNumber,
          verseNumber: playingAyah.numberInSurah,
          page: _audioService.playingPage,
          color: const Color(0x3366BB6A),
        ),
      );
    }
    if (_selectedSurahId != null && _selectedAyahId != null) {
      highlights.add(
        HighlightVerse(
          surah: _selectedSurahId!,
          verseNumber: _selectedAyahId!,
          page: _page,
          color: const Color(0x55D4AF37),
        ),
      );
    }
    return highlights;
  }

  void _showVerseOptionsSheet({
    required int surahNum,
    required int ayahNum,
    required int pageNum,
  }) {
    setState(() {
      _selectedSurahId = surahNum;
      _selectedAyahId = ayahNum;
    });
    final l10n = AppLocalizations.of(context);
    final isAr = l10n.localeName == 'ar';
    final surahName = isAr ? _surahNames[surahNum - 1] : _surahNamesEn[surahNum - 1];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF152B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isAr 
                    ? 'خيارات الآية $ayahNum (سورة $surahName)' 
                    : 'Options for Ayah $ayahNum (Surah $surahName)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.play_arrow, color: AppColors.secondary),
                title: Text(
                  isAr ? 'استماع للآية' : 'Listen to Ayah',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  _audioService.unlockWeb();
                  final b = await QuranApiService.fetchPage(pageNum, isDiyanet: false);
                  final idx = b.arabic.indexWhere((a) => a.surahNumber == surahNum && a.numberInSurah == ayahNum);
                  if (idx != -1) {
                    await _audioService.playAyahDirectly(pageNum, b, idx);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.auto_stories, color: AppColors.secondary),
                title: Text(
                  isAr ? 'التفسير والترجمة' : 'Tafsir & Translation',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showTafsirPanel(pageNum);
                },
              ),
              ListTile(
                leading: Icon(
                  _bookmarks.contains(pageNum) ? Icons.bookmark : Icons.bookmark_border,
                  color: AppColors.secondary,
                ),
                title: Text(
                  isAr ? 'حفظ علامة مرجعية للصفحة' : 'Bookmark Page',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleBookmark(pageNum);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy, color: AppColors.secondary),
                title: Text(
                  isAr ? 'نسخ الآية' : 'Copy Ayah',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final b = await QuranApiService.fetchPage(pageNum, isDiyanet: false);
                  final idx = b.arabic.indexWhere((a) => a.surahNumber == surahNum && a.numberInSurah == ayahNum);
                  if (idx != -1) {
                    final txt = b.arabic[idx].text;
                    await Clipboard.setData(ClipboardData(text: '$txt\n[$surahName:$ayahNum]'));
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isAr ? 'تم نسخ الآية بنجاح' : 'Ayah copied to clipboard'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ── Image URL helper ──────────────────────────────────────────
  /// Returns the CDN URL for a given mushaf page (1–604).
  String _imageUrl(int mushafPage) {
    if (_mushafType == 'tajweed') {
      return 'https://raw.githubusercontent.com/QuranHub/quran-pages-images/main/ayat/tajweed/$mushafPage.png';
    }
    if (_mushafType == 'diyanet') {
      final padded = (mushafPage + 1).toString().padLeft(3, '0');
      return 'https://raw.githubusercontent.com/yehya004/diyanet-mushaf-images/main/$padded.png';
    }
    final padded = mushafPage.toString().padLeft(3, '0');
    return '$_imageBaseUrl$padded.png';
  }

  void _showMushafTypeDialog() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF152B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.mushafTypeLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(
                  _mushafType == 'madina' ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: Colors.white,
                ),
                title: Text(
                  l10n.mushafTypeStandard,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _changeMushafType('madina');
                },
              ),
              ListTile(
                leading: Icon(
                  _mushafType == 'diyanet' ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: Colors.white,
                ),
                title: Text(
                  l10n.mushafTypeDiyanet,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _changeMushafType('diyanet');
                },
              ),
              ListTile(
                leading: Icon(
                  _mushafType == 'text' ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: Colors.white,
                ),
                title: Text(
                  l10n.localeName == 'ar' ? 'المصحف الكتابي (أوفلاين)' : (l10n.localeName == 'tr' ? 'Yazılı Mushaf (Çevrimdışı)' : 'Written Mushaf (Offline)'),
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _changeMushafType('text');
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  int _medinaToDiyanet(int page) {
    if (page >= 595) {
      return page + 1;
    }
    return page;
  }

  int _diyanetToMedina(int page) {
    if (page >= 596) {
      return page - 1;
    }
    return page;
  }

  Future<void> _changeMushafType(String type) async {
    if (type == _mushafType) return;
    final oldPage = _page;
    
    int clampedPage;
    if (_mushafType == 'diyanet' && type != 'diyanet') {
      clampedPage = _diyanetToMedina(oldPage);
    } else if (_mushafType != 'diyanet' && type == 'diyanet') {
      clampedPage = _medinaToDiyanet(oldPage);
    } else {
      clampedPage = oldPage;
    }
    
    final newTotalPages = type == 'diyanet' ? 605 : 604;
    clampedPage = clampedPage.clamp(1, newTotalPages);
    
    // Dispose old controllers
    _pageController.dispose();
    _textPageController?.dispose();
    
    // Create new controllers with correct initialPage
    _pageController = PageController(initialPage: newTotalPages - clampedPage);
    _textPageController = PageController(initialPage: clampedPage - 1);
    
    if (type == 'text') {
      AppQcfFontLoader.preloadPages(clampedPage, radius: 5);
    }
    
    if (mounted) {
      setState(() {
        _mushafType = type;
        _page = clampedPage;
      });
    }
    await _prefs?.setString('mushaf_type', type);
  }

  // ── Preferences ───────────────────────────────────────────────
  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    final savedType = _prefs!.getString('mushaf_type');
    if (savedType != null) {
      final actualType = savedType == 'tajweed' ? 'madina' : savedType;
      if (mounted) setState(() => _mushafType = actualType);
    }
    final saved = _prefs!.getInt('madina_last_page');
    if (saved != null && saved >= 1 && saved <= _totalPages) {
      if (mounted) {
        setState(() {
          _page = saved;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _page = 1;
        });
      }
    }
    
    final savedBookmarks = _prefs!.getStringList('madina_bookmarks');
    if (savedBookmarks != null) {
      _bookmarks = savedBookmarks.map((s) => int.tryParse(s) ?? -1).where((p) => p >= 1 && p <= _totalPages).toList();
    } else {
      // Migrate old single bookmark if exists
      final oldBookmark = _prefs!.getInt('madina_bookmark');
      if (oldBookmark != null && oldBookmark >= 1 && oldBookmark <= _totalPages) {
        _bookmarks = [oldBookmark];
        await _prefs!.setStringList('madina_bookmarks', [oldBookmark.toString()]);
        await _prefs!.remove('madina_bookmark');
      }
    }

    // Initialize PageControllers with the correct initial page.
    _pageController = PageController(initialPage: _totalPages - _page);
    _textPageController = PageController(initialPage: _page - 1);
    AppQcfFontLoader.preloadPages(_page, radius: 5);
    if (mounted) setState(() => _isReady = true);
  }

  Future<void> _saveLastPage(int mushafPage) async {
    await _prefs?.setInt('madina_last_page', mushafPage);
  }

  Future<void> _handleBookmark(int mushafPage) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      if (_bookmarks.contains(mushafPage)) {
        _bookmarks.remove(mushafPage);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.bookmarkRemoved),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        _bookmarks.add(mushafPage);
        _bookmarks.sort();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.bookmarkPlaced(mushafPage)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
    await _prefs?.setStringList('madina_bookmarks', _bookmarks.map((p) => p.toString()).toList());
  }

  void _navigateToBookmark() {
    _showBookmarksListDialog();
  }

  void _showBookmarksListDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF152B22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.secondary, width: 1.5),
              ),
              title: Text(
                l10n.localeName == 'ar' ? 'الإشارات المرجعية المحفوظة' : 'Saved Bookmarks',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: _bookmarks.isEmpty
                  ? Text(
                      l10n.noBookmarkSaved,
                      style: const TextStyle(color: Colors.white70),
                    )
                  : SizedBox(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _bookmarks.length,
                        itemBuilder: (context, idx) {
                          final p = _bookmarks[idx];
                          final surahText = _surahInfoForPage(context, p);
                          return ListTile(
                            leading: const Icon(Icons.bookmark, color: AppColors.secondary),
                            title: Text(
                              l10n.localeName == 'ar' ? 'صفحة $p ($surahText)' : 'Page $p ($surahText)',
                              style: const TextStyle(color: Colors.white),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: AppColors.error),
                              onPressed: () async {
                                setState(() {
                                  _bookmarks.remove(p);
                                });
                                setDialogState(() {});
                                await _prefs?.setStringList('madina_bookmarks', _bookmarks.map((p) => p.toString()).toList());
                              },
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _jumpToPage(p);
                            },
                          );
                        },
                      ),
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel, style: const TextStyle(color: Colors.white70)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Jump to a mushaf page (1–604).
  void _jumpToPage(int mushafPage) {
    final capped = mushafPage.clamp(1, _totalPages);
    if (mounted) setState(() => _page = capped);
    _saveLastPage(capped);
    
    if (_mushafType == 'text') {
      AppQcfFontLoader.preloadPages(capped, radius: 5);
      if (_textPageController != null && _textPageController!.hasClients) {
        _textPageController!.jumpToPage(capped - 1);
      }
    } else {
      final pageIndex = _totalPages - capped;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(pageIndex);
      }
    }
  }

  void _showJumpDialog(int currentMushafPage) {
    final l10n = AppLocalizations.of(context);
    final ctrl = TextEditingController(text: '$currentMushafPage');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.goToPageTitle),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.goToPageHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final p = int.tryParse(ctrl.text);
              if (p != null && p >= 1 && p <= _totalPages) {
                _jumpToPage(p);
              }
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  void _showTafsirPanel(int mushafPage, {bool autoPlay = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TafsirPanel(
        mushafPage: mushafPage,
        mushafType: _mushafType,
        autoPlay: autoPlay,
      ),
    );
  }

  // ── Surah / Juz / Hizb helpers ────────────────────────────────
  List<int> _surahsOnMushafPage(int mushafPage) {
    final result = <int>[];
    final surahPages = _mushafType == 'diyanet' ? _diyanetSurahPages : _madinaSurahPages;
    for (int i = 0; i < surahPages.length; i++) {
      final start = surahPages[i].clamp(1, _totalPages);
      final rawEnd = i < surahPages.length - 1
          ? (surahPages[i + 1] - 1).clamp(1, _totalPages)
          : _totalPages;
      final effectiveEnd = rawEnd < start ? start : rawEnd;
      if (mushafPage >= start && mushafPage <= effectiveEnd) {
        result.add(i + 1);
      }
    }
    return result;
  }

  String _rubInfoForPage(BuildContext context, int mushafPage) {
    const rubs = QuranData.rubList;
    final l10n = AppLocalizations.of(context);
    for (int i = rubs.length - 1; i >= 0; i--) {
      final rubPage = _mushafType == 'diyanet'
          ? (rubs[i].number == 237 ? 588 : (rubs[i].number == 239 ? 592 : rubs[i].page))
          : rubs[i].page;
      if (mushafPage >= rubPage) {
        final r = rubs[i];
        switch (r.rub) {
          case 1:  return l10n.hizbLabel(r.hizb);
          case 2:  return l10n.hizbQuarter(r.hizb);
          case 3:  return l10n.hizbHalf(r.hizb);
          default: return l10n.hizbThreeQuarters(r.hizb);
        }
      }
    }
    return '';
  }

  int _juzForMushafPage(int mushafPage) {
    const juz = QuranData.juzList;
    for (int i = juz.length - 1; i >= 0; i--) {
      if (mushafPage >= juz[i].page) return juz[i].number;
    }
    return 1;
  }

  String _surahInfoForPage(BuildContext context, int mushafPage) {
    final l10n = AppLocalizations.of(context);
    final nums = _surahsOnMushafPage(mushafPage);
    if (nums.isEmpty) return '';
    final localeName = l10n.localeName;
    final List<String> names = localeName == 'tr'
        ? _surahNamesTr
        : localeName == 'en'
            ? _surahNamesEn
            : _surahNames;
    return nums.map((n) => l10n.surahLabel(names[n - 1])).join(' · ');
  }

  // ── Navigator sheet ───────────────────────────────────────────
  void _showSurahNavigator([int initialTab = 0]) {
    final currentMushaf = _page.clamp(1, _totalPages);
    final activeSurahs = _surahsOnMushafPage(currentMushaf);
    final currentJuz = _juzForMushafPage(currentMushaf);
    final surahPages = _mushafType == 'diyanet' ? _diyanetSurahPages : _madinaSurahPages;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SurahNavigatorSheet(
        currentPage: currentMushaf,
        mushafType: _mushafType,
        totalPages: _totalPages,
        surahPages: surahPages,
        activeSurahs: activeSurahs,
        currentJuz: currentJuz,
        initialTab: initialTab,
        onPageSelected: (mushafPage) {
          _jumpToPage(mushafPage);
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) => _buildImageViewer();

  Widget _buildImageViewer() {
    final l10n = AppLocalizations.of(context);
    final mushafPage = _page.clamp(1, _totalPages);
    final surahText = _surahInfoForPage(context, mushafPage);
    final rubText = _rubInfoForPage(context, mushafPage);
    final isBookmarked = _bookmarks.contains(mushafPage);

    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.mushafSepiaBg,
      body: Stack(
        children: [
          // ── Image/Text PageView ──────────────────────────────────
          if (_isReady)
            Positioned.fill(
              child: _mushafType == 'text'
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final height = constraints.maxHeight;
                        
                        // Limit width to maintain standard portrait aspect ratio of Mushaf pages
                        double targetW = width;
                        double targetH = height;
                        const double origRatio = 0.625; // Standard 10:16 Mushaf ratio
                        
                        if (width / height > origRatio) {
                          targetW = height * origRatio;
                        }
                        
                        final customMediaQuery = MediaQuery.of(context).copyWith(
                          size: Size(targetW, targetH),
                        );
                        
                        return Center(
                          child: SizedBox(
                            width: targetW,
                            height: targetH,
                            child: MediaQuery(
                              data: customMediaQuery,
                              child: QuranPageView(
                                pageController: _textPageController!,
                                onPageChanged: (page) {
                                  if (mounted) {
                                    setState(() {
                                      _page = page;
                                    });
                                  }
                                  _saveLastPage(page);
                                  AppQcfFontLoader.preloadPages(page, radius: 5);
                                },
                                highlights: _getTextHighlights(),
                                topBar: SizedBox(height: 48 + topPadding),
                                bottomBar: SizedBox(height: 72 + bottomPadding),
                                onLongPress: (surah, ayah, details) {
                                  _showVerseOptionsSheet(
                                    surahNum: surah,
                                    ayahNum: ayah,
                                    pageNum: _page,
                                  );
                                },
                                isTajweed: true,
                                isDarkMode: false,
                                pageBackgroundColor: AppColors.mushafSepiaBg,
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : Directionality(
                      textDirection: TextDirection.rtl,
                      child: PageView.builder(
                        key: ValueKey(_mushafType),
                        controller: _pageController,
                        reverse: true, // RTL: swipe right = next page
                        itemCount: _totalPages,
                        onPageChanged: (index) {
                          // index 0 = last page (604), index 603 = first page (1)
                          final newMushafPage = _totalPages - index;
                          if (mounted) setState(() => _page = newMushafPage);
                          _saveLastPage(newMushafPage);
                        },
                        itemBuilder: (context, index) {
                          final pageNum = _totalPages - index;

                          return InteractiveViewer(
                            minScale: 1.0,
                            maxScale: 4.0,
                            child: Center(
                              child: Container(
                                margin: const EdgeInsets.fromLTRB(16, 64, 16, 88),
                                decoration: BoxDecoration(
                                  color: AppColors.mushafSepiaBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.secondary.withValues(alpha: 0.12),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Stack(
                                      children: [
                                        _MushafPageImage(
                                          mushafType: _mushafType,
                                          pageNum: pageNum,
                                          fallbackUrl: _imageUrl(pageNum),
                                          l10n: l10n,
                                        ),
                                        if (_audioService.isPlaying &&
                                            _audioService.playingPage == pageNum &&
                                            _audioService.bundle != null &&
                                            _audioService.playingAyahIndex >= 0 &&
                                            _audioService.playingAyahIndex < _audioService.bundle!.arabic.length)
                                          _MushafPageHighlightOverlay(
                                            pageNum: pageNum,
                                            suraId: _audioService.bundle!.arabic[_audioService.playingAyahIndex].surahNumber,
                                            ayahId: _audioService.bundle!.arabic[_audioService.playingAyahIndex].numberInSurah,
                                            mushafType: _mushafType,
                                          ),
                                        if (_selectedSurahId != null && _selectedAyahId != null)
                                          _MushafPageHighlightOverlay(
                                            pageNum: pageNum,
                                            suraId: _selectedSurahId!,
                                            ayahId: _selectedAyahId!,
                                            mushafType: _mushafType,
                                          ),
                                        _MushafPageGestureOverlay(
                                          pageNum: pageNum,
                                          mushafType: _mushafType,
                                          onVerseTapped: (surahNum, ayahNum) {
                                            _showVerseOptionsSheet(
                                              surahNum: surahNum,
                                              ayahNum: ayahNum,
                                              pageNum: pageNum,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          // ── Loading indicator (initial) ─────────────────────────
          if (!_isReady)
            Positioned.fill(
              child: Container(
                color: AppColors.mushafSepiaBg,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.secondary,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          // ── Top AppBar ──────────────────────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            top: _showUI ? 0 : -80 - topPadding,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.only(top: topPadding),
                  height: 48 + topPadding,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.85),
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.secondary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 44,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new,
                              size: 18, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: InkWell(
                            onTap: () => _showSurahNavigator(0),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white24, width: 0.8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.format_list_bulleted_rounded,
                                    size: 16,
                                    color: AppColors.secondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    surahText.isNotEmpty ? surahText : (_mushafType == 'tajweed' ? l10n.mushafTypeTajweed : (_mushafType == 'diyanet' ? l10n.mushafTypeDiyanet : (_mushafType == 'text' ? (l10n.localeName == 'ar' ? 'المصحف الكتابي' : 'Written Mushaf') : l10n.mushafTypeStandard))),
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search, size: 20, color: Colors.white),
                        onPressed: _showSearchDialog,
                        tooltip: l10n.localeName == 'ar' ? 'البحث عن آية' : 'Search Quran',
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.menu_book, size: 20, color: Colors.white),
                        onPressed: _showMushafTypeDialog,
                        tooltip: l10n.mushafTypeLabel,
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 10, right: 16),
                        child: Text(
                          rubText.isNotEmpty ? rubText : l10n.pageAbbr(mushafPage),
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // ── Floating Audio Control Bar ──────────────────────────
          if (_audioService.playingPage != -1)
            Positioned(
              left: 16,
              right: 16,
              bottom: _showUI ? 70 : 16,
              child: _buildFloatingAudioBar(),
            ),
          // ── Bottom bar ──────────────────────────────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            bottom: _showUI ? 0 : -120 - bottomPadding,
            left: 0,
            right: 0,
            child: _buildBottomBar(mushafPage, isBookmarked),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(int mushafPage, bool isBookmarked) {
    final l10n = AppLocalizations.of(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color: AppColors.secondary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navBtn(
                    icon: Icons.tag,
                    label: l10n.pageLabel,
                    onTap: () => _showJumpDialog(mushafPage),
                  ),
                  _navBtn(
                    icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    label: l10n.bookmarkLabel,
                    onTap: () => _handleBookmark(mushafPage),
                    onLongPress: _navigateToBookmark,
                    highlighted: isBookmarked,
                  ),
                  _navBtn(
                    icon: Icons.auto_stories_outlined,
                    label: l10n.tafsirLabel,
                    onTap: () => _showTafsirPanel(mushafPage),
                  ),
                  _navBtn(
                    icon: Icons.headphones_outlined,
                    label: l10n.listenLabel,
                    onTap: () {
                      _audioService.unlockWeb();
                      _showTafsirPanel(mushafPage, autoPlay: true);
                    },
                  ),
                  _navBtn(
                    icon: Icons.list_alt_outlined,
                    label: l10n.indexLabel,
                    onTap: () => _showSurahNavigator(0),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    bool highlighted = false,
  }) {
    final color = highlighted ? AppColors.secondary : Colors.white70;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 9.5, color: color)),
          ],
        ),
      ),
    );
  }

  // ── Static data ───────────────────────────────────────────────
  static const List<String> _surahNames = [
    'الفاتحة',
    'البقرة',
    'آل عمران',
    'النساء',
    'المائدة',
    'الأنعام',
    'الأعراف',
    'الأنفال',
    'التوبة',
    'يونس',
    'هود',
    'يوسف',
    'الرعد',
    'إبراهيم',
    'الحجر',
    'النحل',
    'الإسراء',
    'الكهف',
    'مريم',
    'طه',
    'الأنبياء',
    'الحج',
    'المؤمنون',
    'النور',
    'الفرقان',
    'الشعراء',
    'النمل',
    'القصص',
    'العنكبوت',
    'الروم',
    'لقمان',
    'السجدة',
    'الأحزاب',
    'سبأ',
    'فاطر',
    'يس',
    'الصافات',
    'ص',
    'الزمر',
    'غافر',
    'فصلت',
    'الشورى',
    'الزخرف',
    'الدخان',
    'الجاثية',
    'الأحقاف',
    'محمد',
    'الفتح',
    'الحجرات',
    'ق',
    'الذاريات',
    'الطور',
    'النجم',
    'القمر',
    'الرحمن',
    'الواقعة',
    'الحديد',
    'المجادلة',
    'الحشر',
    'الممتحنة',
    'الصف',
    'الجمعة',
    'المنافقون',
    'التغابن',
    'الطلاق',
    'التحريم',
    'الملك',
    'القلم',
    'الحاقة',
    'المعارج',
    'نوح',
    'الجن',
    'المزمل',
    'المدثر',
    'القيامة',
    'الإنسان',
    'المرسلات',
    'النبأ',
    'النازعات',
    'عبس',
    'التكوير',
    'الانفطار',
    'المطففين',
    'الانشقاق',
    'البروج',
    'الطارق',
    'الأعلى',
    'الغاشية',
    'الفجر',
    'البلد',
    'الشمس',
    'الليل',
    'الضحى',
    'الشرح',
    'التين',
    'العلق',
    'القدر',
    'البينة',
    'الزلزلة',
    'العاديات',
    'القارعة',
    'التكاثر',
    'العصر',
    'الهمزة',
    'الفيل',
    'قريش',
    'الماعون',
    'الكوثر',
    'الكافرون',
    'النصر',
    'المسد',
    'الإخلاص',
    'الفلق',
    'الناس',
  ];

  static const List<String> _surahNamesEn = [
    'Al-Fatihah', 'Al-Baqarah', "Ali 'Imran", 'An-Nisa\'', 'Al-Ma\'idah', 'Al-An\'am',
    'Al-A\'raf', 'Al-Anfal', 'At-Tawbah', 'Yunus', 'Hud', 'Yusuf', 'Ar-Ra\'d', 'Ibrahim',
    'Al-Hijr', 'An-Nahl', 'Al-Isra\'', 'Al-Kahf', 'Maryam', 'Taha', 'Al-Anbiya\'', 'Al-Hajj',
    'Al-Mu\'minun', 'An-Nur', 'Al-Furqan', 'Ash-Shu\'ara\'', 'An-Naml', 'Al-Qasas',
    'Al-\'Ankabut', 'Ar-Rum', 'Luqman', 'As-Sajdah', 'Al-Ahzab', 'Saba\'', 'Fatir', 'Ya-Sin',
    'As-Saffat', 'Sad', 'Az-Zumar', 'Ghafir', 'Fussilat', 'Ash-Shura', 'Az-Zukhruf',
    'Ad-Dukhan', 'Al-Jathiyah', 'Al-Ahqaf', 'Muhammad', 'Al-Fath', 'Al-Hujurat', 'Qaf',
    'Adh-Dhariyat', 'At-Tur', 'An-Najm', 'Al-Qamar', 'Ar-Rahman', 'Al-Waqi\'ah', 'Al-Hadid',
    'Al-Mujadilah', 'Al-Hashr', 'Al-Mumtahanah', 'As-Saff', 'Al-Jumu\'ah', 'Al-Munafiqun',
    'At-Taghabun', 'At-Talaq', 'At-Tahrim', 'Al-Mulk', 'Al-Qalam', 'Al-Haqqah', 'Al-Ma\'arij',
    'Nuh', 'Al-Jinn', 'Al-Muzzammil', 'Al-Muddaththir', 'Al-Qiyamah', 'Al-Insan',
    'Al-Mursalat', 'An-Naba\'', 'An-Nazi\'at', '\'Abasa', 'At-Takwir', 'Al-Infitar',
    'Al-Mutaffifin', 'Al-Inshiqaq', 'Al-Buruj', 'At-Tariq', 'Al-A\'la', 'Al-Ghashiyah',
    'Al-Fajr', 'Al-Balad', 'Ash-Shams', 'Al-Layl', 'Ad-Duha', 'Ash-Sharh', 'At-Tin',
    'Al-\'Alaq', 'Al-Qadr', 'Al-Bayyinah', 'Az-Zalzalah', 'Al-\'Adiyat', 'Al-Qari\'ah',
    'At-Takathur', 'Al-\'Asr', 'Al-Humazah', 'Al-Fil', 'Quraysh', 'Al-Ma\'un', 'Al-Kawthar',
    'Al-Kafirun', 'An-Nasr', 'Al-Masad', 'Al-Ikhlas', 'Al-Falaq', 'An-Nas'
  ];

  static const List<String> _surahNamesTr = [
    'Fâtiha', 'Bakara', 'Âl-i İmrân', 'Nisâ', 'Mâide', 'En\'âm', 'A\'râf', 'Enfâl', 'Tevbe',
    'Yûnus', 'Hûd', 'Yûsuf', 'Ra\'d', 'İbrâhîm', 'Hicr', 'Nahl', 'İsrâ', 'Kehf', 'Meryem',
    'Tâhâ', 'Enbiyâ', 'Hac', 'Mü\'minûn', 'Nûr', 'Furkân', 'Şuarâ', 'Neml', 'Kasas', 'Ankebût',
    'Rûm', 'Lokmân', 'Secde', 'Ahzâb', 'Sebe\'', 'Fâtır', 'Yâsîn', 'Saffât', 'Sâd', 'Zümer',
    'Gâfir', 'Fussilet', 'Şûrâ', 'Zuhruf', 'Duhân', 'Câsiye', 'Ahkâf', 'Muhammed', 'Fetih',
    'Hucurât', 'Kâf', 'Zâriyât', 'Tûr', 'Necm', 'Kamer', 'Rahmân', 'Vâkıa', 'Hadîd', 'Mücâdele',
    'Haşr', 'Mümtehine', 'Saf', 'Cuma', 'Münâfikûn', 'Tegâbün', 'Talâk', 'Tahrîm', 'Mülk',
    'Kalem', 'Hâkka', 'Meâric', 'Nûh', 'Cin', 'Müzzemmil', 'Müddessir', 'Kıyâme', 'İnsân',
    'Mürselât', 'Nebe\'', 'Nâziât', 'Abese', 'Tekvîr', 'İnfitâr', 'Mutaffifîn', 'İnşikâk',
    'Bürûc', 'Târık', 'A\'lâ', 'Gâşiye', 'Fecr', 'Beled', 'Şems', 'Leyl', 'Duhâ', 'İnşirâh',
    'Tîn', 'Alak', 'Kadr', 'Beyyine', 'Zilzâl', 'Âdiyât', 'Kâria', 'Tekâsür', 'Asr', 'Hümeze',
    'Fîl', 'Kureyş', 'Mâûn', 'Kevser', 'Kâfirûn', 'Nasr', 'Tebbet', 'İhlâs', 'Felak', 'Nâs'
  ];

  /// Madina Mushaf standard page numbers for each surah (1–604).
  static const List<int> _madinaSurahPages = [
    1, //   1 الفاتحة
    2, //   2 البقرة
    50, //   3 آل عمران
    77, //   4 النساء
    106, //   5 المائدة
    128, //   6 الأنعام
    151, //   7 الأعراف
    177, //   8 الأنفال
    187, //   9 التوبة
    208, //  10 يونس
    221, //  11 هود
    235, //  12 يوسف
    249, //  13 الرعد
    255, //  14 إبراهيم
    262, //  15 الحجر
    267, //  16 النحل
    282, //  17 الإسراء
    293, //  18 الكهف
    305, //  19 مريم
    312, //  20 طه
    322, //  21 الأنبياء
    332, //  22 الحج
    342, //  23 المؤمنون
    350, //  24 النور
    359, //  25 الفرقان
    367, //  26 الشعراء
    377, //  27 النمل
    385, //  28 القصص
    396, //  29 العنكبوت
    404, //  30 الروم
    411, //  31 لقمان
    415, //  32 السجدة
    418, //  33 الأحزاب
    428, //  34 سبأ
    434, //  35 فاطر
    440, //  36 يس
    446, //  37 الصافات
    453, //  38 ص
    458, //  39 الزمر
    467, //  40 غافر
    477, //  41 فصلت
    483, //  42 الشورى
    489, //  43 الزخرف
    496, //  44 الدخان
    499, //  45 الجاثية
    502, //  46 الأحقاف
    507, //  47 محمد
    511, //  48 الفتح
    515, //  49 الحجرات
    518, //  50 ق
    520, //  51 الذاريات
    523, //  52 الطور
    526, //  53 النجم
    528, //  54 القمر
    531, //  55 الرحمن
    534, //  56 الواقعة
    537, //  57 الحديد
    542, //  58 المجادلة
    545, //  59 الحشر
    549, //  60 الممتحنة
    551, //  61 الصف
    553, //  62 الجمعة
    554, //  63 المنافقون
    556, //  64 التغابن
    558, //  65 الطلاق
    560, //  66 التحريم
    562, //  67 الملك
    564, //  68 القلم
    566, //  69 الحاقة
    568, //  70 المعارج
    570, //  71 نوح
    572, //  72 الجن
    574, //  73 المزمل
    575, //  74 المدثر
    577, //  75 القيامة
    578, //  76 الإنسان
    580, //  77 المرسلات
    582, //  78 النبأ
    583, //  79 النازعات
    585, //  80 عبس
    586, //  81 التكوير
    587, //  82 الانفطار
    587, //  83 المطففين
    589, //  84 الانشقاق
    590, //  85 البروج
    591, //  86 الطارق
    591, //  87 الأعلى
    592, //  88 الغاشية
    593, //  89 الفجر
    594, //  90 البلد
    595, //  91 الشمس
    595, //  92 الليل
    596, //  93 الضحى
    596, //  94 الشرح
    597, //  95 التين
    597, //  96 العلق
    598, //  97 القدر
    598, //  98 البينة
    599, //  99 الزلزلة
    599, // 100 العاديات
    600, // 101 القارعة
    600, // 102 التكاثر
    601, // 103 العصر
    601, // 104 الهمزة
    601, // 105 الفيل
    602, // 106 قريش
    602, // 107 الماعون
    602, // 108 الكوثر
    603, // 109 الكافرون
    603, // 110 النصر
    603, // 111 المسد
    604, // 112 الإخلاص
    604, // 113 الفلق
    604, // 114 الناس
  ];

  static const List<int> _diyanetSurahPages = [
    1, //   1 الفاتحة
    2, //   2 البقرة
    50, //   3 آل عمران
    77, //   4 النساء
    106, //   5 المائدة
    128, //   6 الأنعام
    151, //   7 الأعراف
    177, //   8 الأنفال
    187, //   9 التوبة
    208, //  10 يونس
    221, //  11 هود
    235, //  12 يوسف
    249, //  13 الرعد
    255, //  14 إبراهيم
    262, //  15 الحجر
    267, //  16 النحل
    282, //  17 الإسراء
    293, //  18 الكهف
    305, //  19 مريم
    312, //  20 طه
    322, //  21 الأنبياء
    332, //  22 الحج
    342, //  23 المؤمنون
    350, //  24 النور
    359, //  25 الفرقان
    367, //  26 الشعراء
    377, //  27 النمل
    385, //  28 القصص
    396, //  29 العنكبوت
    404, //  30 الروم
    411, //  31 لقمان
    415, //  32 السجدة
    418, //  33 الأحزاب
    428, //  34 سبأ
    434, //  35 فاطر
    440, //  36 يس
    446, //  37 الصافات
    453, //  38 ص
    458, //  39 الزمر
    467, //  40 غافر
    477, //  41 فصلت
    483, //  42 الشورى
    489, //  43 الزخرف
    496, //  44 الدخان
    499, //  45 الجاثية
    502, //  46 الأحقاف
    507, //  47 محمد
    511, //  48 الفتح
    515, //  49 الحجرات
    518, //  50 ق
    520, //  51 الذاريات
    523, //  52 الطور
    526, //  53 النجم
    528, //  54 القمر
    531, //  55 الرحمن
    534, //  56 الواقعة
    537, //  57 الحديد
    542, //  58 المجادلة
    545, //  59 الحشر
    549, //  60 الممتحنة
    551, //  61 الصف
    553, //  62 الجمعة
    554, //  63 المنافقون
    556, //  64 التغابن
    558, //  65 الطلاق
    560, //  66 التحريم
    562, //  67 الملك
    564, //  68 القلم
    566, //  69 الحاقة
    568, //  70 المعارج
    570, //  71 نوح
    572, //  72 الجن
    574, //  73 المزمل
    575, //  74 المدثر
    577, //  75 القيامة
    578, //  76 الإنسان
    580, //  77 المرسلات
    582, //  78 النبأ
    583, //  79 النازعات
    585, //  80 عبس
    586, //  81 التكوير
    587, //  82 الانفطار
    588, //  83 المطففين
    589, //  84 الانشقاق
    590, //  85 البروج
    591, //  86 الطارق
    592, //  87 الأعلى
    592, //  88 الغاشية
    593, //  89 الفجر
    594, //  90 البلد
    595, //  91 الشمس
    596, //  92 الليل
    596, //  93 الضحى
    597, //  94 الشرح
    597, //  95 التين
    598, //  96 العلق
    599, //  97 القدر
    599, //  98 البينة
    600, //  99 الزلزلة
    600, // 100 العاديات
    601, // 101 القارعة
    601, // 102 التكاثر
    602, // 103 العصر
    602, // 104 الهمزة
    602, // 105 الفيل
    603, // 106 قريش
    603, // 107 الماعون
    603, // 108 الكوثر
    604, // 109 الكافرون
    604, // 110 النصر
    604, // 111 المسد
    605, // 112 الإخلاص
    605, // 113 الفلق
    605, // 114 الناس
  ];

  Widget _buildFloatingAudioBar() {
    final l10n = AppLocalizations.of(context);
    final playingPage = _audioService.playingPage;
    if (playingPage == -1 || _audioService.bundle == null || _audioService.bundle!.arabic.isEmpty) {
      return const SizedBox.shrink();
    }

    final playingIdx = _audioService.playingAyahIndex;
    if (playingIdx < 0 || playingIdx >= _audioService.bundle!.arabic.length) {
      return const SizedBox.shrink();
    }

    final ayah = _audioService.bundle!.arabic[playingIdx];
    final isDownloading = _audioService.isAudioDownloading;
    final downloadProgress = _audioService.audioDownloadProgress;

    return FutureBuilder<bool>(
      future: _audioService.isPageAudioDownloaded(playingPage, _audioService.bundle),
      builder: (context, snapshot) {
        final isDownloaded = snapshot.data ?? false;

        return Card(
          color: const Color(0xFF152B22).withValues(alpha: 0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.3), width: 1.5),
          ),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Upper row: info, download progress, and close button
                Row(
                  children: [
                    const Icon(Icons.music_note, color: AppColors.secondary, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.ayahLabel(ayah.surahNameAr, '${ayah.numberInSurah}'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isDownloading)
                      Text(
                        "${(downloadProgress * 100).toStringAsFixed(0)}%",
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                      )
                    else if (isDownloaded)
                      const Icon(Icons.offline_pin_rounded, color: Colors.greenAccent, size: 18)
                    else
                      IconButton(
                        icon: const Icon(Icons.download_for_offline_outlined, color: Colors.white70, size: 18),
                        onPressed: () {
                          _audioService.downloadPageAudio(playingPage, _audioService.bundle!);
                        },
                        tooltip: l10n.localeName == 'ar' ? 'تحميل التلاوة أوفلاين' : 'Download recitation offline',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.white60, size: 18),
                      onPressed: () => _audioService.stop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                if (isDownloading) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: downloadProgress,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                      minHeight: 3,
                    ),
                  ),
                ],
                const Divider(color: Colors.white12, height: 12),
                // Lower row: controls (prev, play/pause, next, speed, repeat, repeat single)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Speed Control
                    PopupMenuButton<double>(
                      initialValue: _audioService.playbackSpeed,
                      icon: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "${_audioService.playbackSpeed}x",
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      color: const Color(0xFF1C1C1E),
                      onSelected: (speed) {
                        _audioService.setPlaybackSpeed(speed);
                      },
                      itemBuilder: (context) => [1.0, 1.25, 1.5, 2.0].map((s) {
                        return PopupMenuItem<double>(
                          value: s,
                          child: Text("${s}x", style: const TextStyle(color: Colors.white, fontSize: 12)),
                        );
                      }).toList(),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.skip_previous,
                              color: playingIdx > 0 ? Colors.white : Colors.white24,
                              size: 20),
                          onPressed: playingIdx > 0 ? () => _audioService.skipPrevious() : null,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            _audioService.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                            color: AppColors.secondary,
                            size: 34,
                          ),
                          onPressed: () => _audioService.togglePlay(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.skip_next,
                            color: playingIdx < (_audioService.bundle!.arabic.length - 1) ? Colors.white : Colors.white24,
                            size: 20,
                          ),
                          onPressed: playingIdx < (_audioService.bundle!.arabic.length - 1)
                              ? () => _audioService.skipNext()
                              : null,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ],
                    ),
                    // Repeat Controls
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Repeat single ayah toggle
                        IconButton(
                          icon: Icon(
                            Icons.repeat_one,
                            color: _audioService.repeatSingleAyah ? AppColors.secondary : Colors.white60,
                            size: 18,
                          ),
                          onPressed: () {
                            _audioService.toggleRepeatSingleAyah();
                          },
                          tooltip: l10n.localeName == 'ar' ? 'تكرار الآية الحالية' : 'Repeat current Ayah',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        ),
                        const SizedBox(width: 4),
                        // Page/Ayah general repeat counts
                        InkWell(
                          onTap: () => _audioService.cycleRepeatCount(),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: _audioService.repeatCount > 1 ? AppColors.secondary.withValues(alpha: 0.2) : Colors.white10,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.repeat, color: _audioService.repeatCount > 1 ? AppColors.secondary : Colors.white60, size: 14),
                                const SizedBox(width: 2),
                                Text(
                                  _audioService.repeatCount == 999 ? '∞' : '${_audioService.repeatCount}x',
                                  style: TextStyle(
                                    color: _audioService.repeatCount > 1 ? AppColors.secondary : Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSearchDialog() {
    final l10n = AppLocalizations.of(context);
    final isAr = l10n.localeName == 'ar';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF152B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return _QuranSearchSheet(
          isAr: isAr,
          onVerseSelected: (surahNum, ayahNum, pageNum) {
            _jumpToPage(pageNum);
            _highlightSearchVerse(surahNum, ayahNum);
          },
        );
      },
    );
  }

  void _highlightSearchVerse(int surahNum, int ayahNum) {
    _searchHighlightTimer?.cancel();
    setState(() {
      _selectedSurahId = surahNum;
      _selectedAyahId = ayahNum;
    });
    _searchHighlightTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _selectedSurahId = null;
          _selectedAyahId = null;
        });
      }
    });
  }
}

class _QuranSearchSheet extends StatefulWidget {
  final bool isAr;
  final Function(int surahNum, int ayahNum, int pageNum) onVerseSelected;

  const _QuranSearchSheet({
    required this.isAr,
    required this.onVerseSelected,
  });

  @override
  State<_QuranSearchSheet> createState() => _QuranSearchSheetState();
}

class _QuranSearchSheetState extends State<_QuranSearchSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  String _lastQuery = '';
  Timer? _debounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (query.trim() == _lastQuery) return;
      _lastQuery = query.trim();
      if (_lastQuery.isEmpty) {
        setState(() {
          _results = [];
          _searching = false;
        });
        return;
      }
      setState(() => _searching = true);
      final list = await QuranDatabaseHelper().searchVerses(_lastQuery);
      if (mounted) {
        setState(() {
          _results = list;
          _searching = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.viewInsets.bottom;

    return Container(
      height: mediaQuery.size.height * 0.75,
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              textDirection: TextDirection.rtl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: widget.isAr ? 'ابحث عن آية (مثال: الحمد لله)...' : 'Search verse (e.g. Alhamdulillah)...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _searching
                ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
                : _results.isEmpty
                    ? Center(
                        child: Text(
                          _searchCtrl.text.trim().isEmpty
                              ? (widget.isAr ? 'اكتب للبحث في المصحف' : 'Type to search the Quran')
                              : (widget.isAr ? 'لا توجد نتائج مطابقة' : 'No matching results found'),
                          style: const TextStyle(color: Colors.white38),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, idx) {
                          final row = _results[idx];
                          final textAr = row['text_ar'] as String;
                          final surahName = row['surah_name_ar'] as String;
                          final surahNum = row['surah_number'] as int;
                          final ayahNum = row['number_in_surah'] as int;
                          final pageNum = row['page'] as int;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text(
                              textAr,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Amiri',
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${widget.isAr ? "سورة" : "Surah"} $surahName (${widget.isAr ? "آية" : "Ayah"} $ayahNum)',
                                      style: const TextStyle(
                                        color: AppColors.secondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${widget.isAr ? "صفحة" : "Page"} $pageNum',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              widget.onVerseSelected(surahNum, ayahNum, pageNum);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ── SurahNavigatorSheet ───────────────────────────────────────────
class _SurahNavigatorSheet extends StatefulWidget {
  final int currentPage;
  final String mushafType;
  final int totalPages;
  final List<int> surahPages;
  final List<int> activeSurahs;
  final int currentJuz;
  final int initialTab;
  final ValueChanged<int> onPageSelected;

  const _SurahNavigatorSheet({
    required this.currentPage,
    required this.mushafType,
    required this.totalPages,
    required this.surahPages,
    required this.activeSurahs,
    required this.currentJuz,
    required this.initialTab,
    required this.onPageSelected,
  });

  @override
  State<_SurahNavigatorSheet> createState() => _SurahNavigatorSheetState();
}

class _SurahNavigatorSheetState extends State<_SurahNavigatorSheet> {
  late ScrollController _surahController;
  late ScrollController _juzController;
  late ScrollController _rubController;

  @override
  void initState() {
    super.initState();
    _surahController = ScrollController();
    _juzController = ScrollController();
    _rubController = ScrollController();
  }

  @override
  void dispose() {
    _surahController.dispose();
    _juzController.dispose();
    _rubController.dispose();
    super.dispose();
  }

  void _jumpAndPop(int mushafPage) {
    Navigator.pop(context);
    widget.onPageSelected(mushafPage);
  }

  @override
  Widget build(BuildContext context) {
    final activeSurahsSet = widget.activeSurahs.toSet();

    final activeSurahIdx = widget.activeSurahs.isNotEmpty ? (widget.activeSurahs.first - 1) : 0;
    final activeJuzIdx = widget.currentJuz - 1;

    int activeRubIdx = 0;
    const rubs = QuranData.rubList;
    for (int i = rubs.length - 1; i >= 0; i--) {
      final rubPage = widget.mushafType == 'diyanet'
          ? (rubs[i].number == 237 ? 588 : (rubs[i].number == 239 ? 592 : rubs[i].page))
          : rubs[i].page;
      if (widget.currentPage >= rubPage) {
        activeRubIdx = i;
        break;
      }
    }

    final l10n = AppLocalizations.of(context);

    return DefaultTabController(
      length: 3,
      initialIndex: widget.initialTab,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.menu_book_outlined,
                      color: AppColors.secondary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.mushafIndexTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            TabBar(
              tabs: [
                Tab(text: l10n.mushafIndexSurahs),
                Tab(text: l10n.mushafIndexJuzs),
                Tab(text: l10n.mushafIndexHazbs),
              ],
              indicatorColor: AppColors.secondary,
              labelColor: AppColors.secondary,
              unselectedLabelColor: Colors.white54,
              dividerColor: Colors.white12,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // ── Surahs
                  _ActiveScrollList(
                    controller: _surahController,
                    itemCount: 114,
                    itemHeight: 48.0,
                    activeIndex: activeSurahIdx,
                    itemBuilder: (_, i) {
                      final mushPage = widget.surahPages[i].clamp(1, widget.totalPages);
                      final isActive = activeSurahsSet.contains(i + 1);
                      final localeName = l10n.localeName;
                      final List<String> names = localeName == 'tr'
                          ? _MushafViewerScreenState._surahNamesTr
                          : localeName == 'en'
                              ? _MushafViewerScreenState._surahNamesEn
                              : _MushafViewerScreenState._surahNames;
                      return Material(
                        color: isActive
                            ? AppColors.secondary.withValues(alpha: 0.10)
                            : Colors.transparent,
                        child: ListTile(
                          dense: true,
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.secondary : Colors.white12,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: isActive ? AppColors.primary : Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            l10n.surahLabel(names[i]),
                            style: TextStyle(
                              color: isActive ? AppColors.secondary : Colors.white,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.secondary.withValues(alpha: 0.2)
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l10n.pageAbbr(mushPage),
                              style: TextStyle(
                                color: isActive ? AppColors.secondary : Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          onTap: () => _jumpAndPop(widget.surahPages[i]),
                        ),
                      );
                    },
                  ),

                  // ── Juz
                  _ActiveScrollList(
                    controller: _juzController,
                    itemCount: QuranData.juzList.length,
                    itemHeight: 72.0,
                    activeIndex: activeJuzIdx,
                    itemBuilder: (_, i) {
                      final j = QuranData.juzList[i];
                      final isActive = widget.currentJuz == j.number;
                      return Material(
                        color: isActive
                            ? AppColors.secondary.withValues(alpha: 0.10)
                            : Colors.transparent,
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.secondary : Colors.white12,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${j.number}',
                                style: TextStyle(
                                  color: isActive ? AppColors.primary : Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            l10n.juzLabel(j.number),
                            style: TextStyle(
                              color: isActive ? AppColors.secondary : Colors.white,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            j.openingAr,
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          trailing: Text(
                            l10n.pageAbbr(j.page),
                            style: TextStyle(
                              color: isActive ? AppColors.secondary : Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          onTap: () => _jumpAndPop(j.page),
                        ),
                      );
                    },
                  ),

                  // ── Hizb / Rub'
                  _ActiveScrollList(
                    controller: _rubController,
                    itemCount: QuranData.rubList.length,
                    itemHeight: 60.0,
                    activeIndex: activeRubIdx,
                    itemBuilder: (_, i) {
                      final r = QuranData.rubList[i];
                      final rubPage = widget.mushafType == 'diyanet'
                          ? (r.number == 237 ? 588 : (r.number == 239 ? 592 : r.page))
                          : r.page;
                      final isActive = widget.currentPage == rubPage;
                      final isHizbStart = r.rub == 1;
                      return Material(
                        color: isActive
                            ? AppColors.secondary.withValues(alpha: 0.10)
                            : Colors.transparent,
                        child: ListTile(
                          dense: true,
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.secondary
                                  : (isHizbStart ? Colors.white12 : Colors.transparent),
                              shape: BoxShape.circle,
                              border: isHizbStart
                                  ? null
                                  : Border.all(color: Colors.white12, width: 1),
                            ),
                            child: Center(
                              child: Text(
                                '${r.hizb}',
                                style: TextStyle(
                                  color: isActive ? AppColors.primary : Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            () {
                              switch (r.rub) {
                                case 1:  return l10n.hizbLabel(r.hizb);
                                case 2:  return l10n.hizbQuarter(r.hizb);
                                case 3:  return l10n.hizbHalf(r.hizb);
                                default: return l10n.hizbThreeQuarters(r.hizb);
                              }
                            }(),
                            style: TextStyle(
                              color: isActive ? AppColors.secondary : Colors.white,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            QuranData.rubOpeningTexts[i],
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.secondary.withValues(alpha: 0.2)
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l10n.pageAbbr(rubPage),
                              style: TextStyle(
                                color: isActive ? AppColors.secondary : Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          onTap: () => _jumpAndPop(rubPage),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── ActiveScrollList Wrapper ──────────────────────────────────────
class _ActiveScrollList extends StatefulWidget {
  final ScrollController controller;
  final int itemCount;
  final double itemHeight;
  final int activeIndex;
  final IndexedWidgetBuilder itemBuilder;

  const _ActiveScrollList({
    required this.controller,
    required this.itemCount,
    required this.itemHeight,
    required this.activeIndex,
    required this.itemBuilder,
  });

  @override
  State<_ActiveScrollList> createState() => _ActiveScrollListState();
}

class _ActiveScrollListState extends State<_ActiveScrollList> {
  @override
  void initState() {
    super.initState();
    _scrollToActive();
  }

  @override
  void didUpdateWidget(covariant _ActiveScrollList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeIndex != widget.activeIndex) {
      _scrollToActive();
    }
  }

  void _scrollToActive() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!widget.controller.hasClients) {
        // Retry in next frame if not attached yet
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) _scrollToActive();
        });
        return;
      }
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      final viewportHeight = renderBox?.size.height ?? 400.0;
      final target = widget.activeIndex * widget.itemHeight - (viewportHeight / 2) + (widget.itemHeight / 2);
      widget.controller.jumpTo(target.clamp(0.0, widget.controller.position.maxScrollExtent));
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: widget.controller,
      itemCount: widget.itemCount,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: widget.itemBuilder,
    );
  }
}

// ── Local Or Network Image Loader ───────────────────────────────────────────

class _MushafPageImage extends StatefulWidget {
  final String mushafType;
  final int pageNum;
  final String fallbackUrl;
  final AppLocalizations l10n;

  const _MushafPageImage({
    required this.mushafType,
    required this.pageNum,
    required this.fallbackUrl,
    required this.l10n,
  });

  @override
  State<_MushafPageImage> createState() => _MushafPageImageState();
}

class _MushafPageImageState extends State<_MushafPageImage> {
  String? _localPath;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkLocal();
  }

  @override
  void didUpdateWidget(_MushafPageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mushafType != widget.mushafType || oldWidget.pageNum != widget.pageNum) {
      _checkLocal();
    }
  }

  Future<void> _checkLocal() async {
    setState(() => _loading = true);
    final path = await MushafDownloadService().getLocalFilePath(widget.mushafType, widget.pageNum);
    if (mounted) {
      setState(() {
        _localPath = path;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.secondary, strokeWidth: 2),
      );
    }

    if (_localPath != null) {
      return Image.file(
        File(_localPath!),
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildNetworkFallback(),
      );
    }

    return _buildNetworkFallback();
  }

  Widget _buildNetworkFallback() {
    return CachedNetworkImage(
      imageUrl: widget.fallbackUrl,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(
          color: AppColors.secondary,
          strokeWidth: 2,
        ),
      ),
      errorWidget: (context, url, error) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: AppColors.secondary, size: 48),
            const SizedBox(height: 12),
            Text(
              widget.l10n.failedToLoadData,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}



class _MushafPageHighlightOverlay extends StatefulWidget {
  final int pageNum;
  final int suraId;
  final int ayahId;
  final String mushafType;

  const _MushafPageHighlightOverlay({
    required this.pageNum,
    required this.suraId,
    required this.ayahId,
    required this.mushafType,
  });

  @override
  State<_MushafPageHighlightOverlay> createState() => _MushafPageHighlightOverlayState();
}

class _MushafPageHighlightOverlayState extends State<_MushafPageHighlightOverlay> {
  List<dynamic>? _coordinates;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCoordinates();
  }

  @override
  void didUpdateWidget(_MushafPageHighlightOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNum != widget.pageNum || oldWidget.mushafType != widget.mushafType) {
      _loadCoordinates();
    }
  }

  Future<void> _loadCoordinates() async {
    setState(() => _loading = true);
    final coords = await MushafCoordinateService().getPageCoordinates(widget.pageNum, mushafType: widget.mushafType);
    if (mounted) {
      setState(() {
        _coordinates = coords;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _coordinates == null) {
      return const SizedBox.shrink();
    }

    Map<String, dynamic>? activeVerse;
    for (var verse in _coordinates!) {
      final verseAyahId = verse['ayah_id'] ?? verse['aya_id'];
      if (verse['sura_id'] == widget.suraId && verseAyahId == widget.ayahId) {
        activeVerse = verse as Map<String, dynamic>;
        break;
      }
    }

    if (activeVerse == null) return const SizedBox.shrink();
    final segs = activeVerse['segs'] as List<dynamic>;

    // Find page bounds
    double origWidth = 1.0;
    double origHeight = 1.0;
    double pageMinX = 9999.0;
    double pageMaxX = -9999.0;

    if (widget.mushafType == 'diyanet') {
      origWidth = 705.0;
      origHeight = 1147.0;
      for (var verse in _coordinates!) {
        for (var seg in verse['segs']) {
          final double xVal = (seg['x'] as num).toDouble();
          final double wVal = (seg['w'] as num).toDouble();
          if (xVal < pageMinX) pageMinX = xVal;
          if (xVal + wVal > pageMaxX) pageMaxX = xVal + wVal;
        }
      }
    } else if (widget.mushafType == 'tajweed') {
      origWidth = 456.0;
      origHeight = 707.0;
    } else { // madina
      origWidth = 2600.0;
      origHeight = 4206.0;
    }

    final pageCenterXml = (pageMinX < pageMaxX) ? (pageMinX + pageMaxX) / 2 : 463.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final parentW = constraints.maxWidth;
        final parentH = constraints.maxHeight;
        final double origRatio = origWidth / origHeight;

        double displayW;
        double displayH;
        double offsetX;
        double offsetY;

        if (parentW / parentH > origRatio) {
          displayH = parentH;
          displayW = parentH * origRatio;
          offsetX = (parentW - displayW) / 2;
          offsetY = 0;
        } else {
          displayW = parentW;
          displayH = parentW / origRatio;
          offsetX = 0;
          offsetY = (parentH - displayH) / 2;
        }

        final scaleX = displayW / origWidth;
        final scaleY = displayH / origHeight;

        return Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: segs.map((seg) {
              final double rawX = (seg['x'] as num).toDouble();
              final double rawY = (seg['y'] as num).toDouble();
              final double rawW = (seg['w'] as num).toDouble();
              final double rawH = (seg['h'] as num).toDouble();

              double mappedX;
              double mappedY;
              double mappedW;
              double mappedH;

              if (widget.mushafType == 'diyanet') {
                // Map to the cropped PNG boundaries
                mappedX = 352.5 + 0.957278 * (rawX - pageCenterXml);
                mappedW = 0.957278 * rawW;
                mappedY = 1.003 * rawY - 85.5;
                mappedH = 1.003 * rawH;
              } else if (widget.mushafType == 'tajweed') {
                mappedX = 1.534 * rawX + 3.0;
                mappedW = 1.534 * rawW;
                final firstVerse = _coordinates!.first;
                final firstAyahId = firstVerse['ayah_id'] ?? firstVerse['aya_id'];
                final startsSurah = firstAyahId == 1;
                final double tajweedOffsetY = startsSurah ? -7.0 : 33.0;
                mappedY = 1.525 * rawY + tajweedOffsetY;
                mappedH = 1.525 * rawH;
              } else { // madina
                mappedX = 7.907 * rawX + 160.0;
                mappedW = 7.907 * rawW;
                mappedY = 9.500 * rawY + 40.5;
                mappedH = 9.500 * rawH;
              }

              final x = mappedX * scaleX + offsetX;
              final y = mappedY * scaleY + offsetY;
              final w = mappedW * scaleX;
              final h = mappedH * scaleY;

              return Positioned(
                left: x,
                top: y,
                width: w,
                height: h,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.32),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _MushafPageGestureOverlay extends StatefulWidget {
  final int pageNum;
  final String mushafType;
  final Function(int surahNum, int ayahNum) onVerseTapped;

  const _MushafPageGestureOverlay({
    required this.pageNum,
    required this.mushafType,
    required this.onVerseTapped,
  });

  @override
  State<_MushafPageGestureOverlay> createState() => _MushafPageGestureOverlayState();
}

class _MushafPageGestureOverlayState extends State<_MushafPageGestureOverlay> {
  List<dynamic>? _coordinates;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCoordinates();
  }

  @override
  void didUpdateWidget(_MushafPageGestureOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNum != widget.pageNum || oldWidget.mushafType != widget.mushafType) {
      _loadCoordinates();
    }
  }

  Future<void> _loadCoordinates() async {
    setState(() => _loading = true);
    final coords = await MushafCoordinateService().getPageCoordinates(widget.pageNum, mushafType: widget.mushafType);
    if (mounted) {
      setState(() {
        _coordinates = coords;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _coordinates == null) {
      return const SizedBox.shrink();
    }

    // Find page bounds
    double origWidth = 1.0;
    double origHeight = 1.0;
    double pageMinX = 9999.0;
    double pageMaxX = -9999.0;

    if (widget.mushafType == 'diyanet') {
      origWidth = 705.0;
      origHeight = 1147.0;
      for (var verse in _coordinates!) {
        for (var seg in verse['segs']) {
          final double xVal = (seg['x'] as num).toDouble();
          final double wVal = (seg['w'] as num).toDouble();
          if (xVal < pageMinX) pageMinX = xVal;
          if (xVal + wVal > pageMaxX) pageMaxX = xVal + wVal;
        }
      }
    } else if (widget.mushafType == 'tajweed') {
      origWidth = 456.0;
      origHeight = 707.0;
    } else { // madina
      origWidth = 2600.0;
      origHeight = 4206.0;
    }

    final pageCenterXml = (pageMinX < pageMaxX) ? (pageMinX + pageMaxX) / 2 : 463.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final parentW = constraints.maxWidth;
        final parentH = constraints.maxHeight;
        final double origRatio = origWidth / origHeight;

        double displayW;
        double displayH;
        double offsetX;
        double offsetY;

        if (parentW / parentH > origRatio) {
          displayH = parentH;
          displayW = parentH * origRatio;
          offsetX = (parentW - displayW) / 2;
          offsetY = 0;
        } else {
          displayW = parentW;
          displayH = parentW / origRatio;
          offsetX = 0;
          offsetY = (parentH - displayH) / 2;
        }

        final scaleX = displayW / origWidth;
        final scaleY = displayH / origHeight;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: (details) {
            final localPos = details.localPosition;
            final localX = localPos.dx;
            final localY = localPos.dy;

            // Check if tap is inside display bounds
            if (localX >= offsetX && localX <= offsetX + displayW &&
                localY >= offsetY && localY <= offsetY + displayH) {
              final mappedX = (localX - offsetX) / scaleX;
              final mappedY = (localY - offsetY) / scaleY;

              // Find which verse this falls into
              for (var verse in _coordinates!) {
                final segs = verse['segs'] as List<dynamic>;
                for (var seg in segs) {
                  final double rawX = (seg['x'] as num).toDouble();
                  final double rawY = (seg['y'] as num).toDouble();
                  final double rawW = (seg['w'] as num).toDouble();
                  final double rawH = (seg['h'] as num).toDouble();

                  double x1, y1, x2, y2;
                  if (widget.mushafType == 'diyanet') {
                    x1 = 352.5 + 0.957278 * (rawX - pageCenterXml);
                    y1 = 1.003 * rawY - 85.5;
                    x2 = x1 + 0.957278 * rawW;
                    y2 = y1 + 1.003 * rawH;
                  } else if (widget.mushafType == 'tajweed') {
                    x1 = 1.534 * rawX + 3.0;
                    final firstVerse = _coordinates!.first;
                    final firstAyahId = firstVerse['ayah_id'] ?? firstVerse['aya_id'];
                    final startsSurah = firstAyahId == 1;
                    final double tajweedOffsetY = startsSurah ? -7.0 : 33.0;
                    y1 = 1.525 * rawY + tajweedOffsetY;
                    x2 = x1 + 1.534 * rawW;
                    y2 = y1 + 1.525 * rawH;
                  } else { // madina
                    x1 = 7.907 * rawX + 160.0;
                    y1 = 9.500 * rawY + 40.5;
                    x2 = x1 + 7.907 * rawW;
                    y2 = y1 + 9.500 * rawH;
                  }

                  if (mappedX >= x1 && mappedX <= x2 && mappedY >= y1 && mappedY <= y2) {
                    final surahId = verse['sura_id'] as int;
                    final ayahId = (verse['ayah_id'] ?? verse['aya_id']) as int;
                    widget.onVerseTapped(surahId, ayahId);
                    return; // Stop searching once matched
                  }
                }
              }
            }
          },
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

// ── Web Written Mushaf Viewer Fallback ──────────────────────────────

class WebQuranPageView extends StatefulWidget {
  final PageController pageController;
  final void Function(int page) onPageChanged;
  final List<HighlightVerse> highlights;
  final Widget topBar;
  final Widget bottomBar;
  final void Function(int surah, int ayah) onVerseTapped;
  final Color pageBackgroundColor;

  const WebQuranPageView({
    super.key,
    required this.pageController,
    required this.onPageChanged,
    required this.highlights,
    required this.topBar,
    required this.bottomBar,
    required this.onVerseTapped,
    this.pageBackgroundColor = AppColors.mushafSepiaBg,
  });

  @override
  State<WebQuranPageView> createState() => _WebQuranPageViewState();
}

class _WebQuranPageViewState extends State<WebQuranPageView> {
  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: widget.pageController,
      onPageChanged: widget.onPageChanged,
      itemCount: 604,
      itemBuilder: (context, index) {
        final pageNum = index + 1;
        return _WebQuranPageItem(
          pageNum: pageNum,
          highlights: widget.highlights,
          onVerseTapped: widget.onVerseTapped,
          topBarHeight: 48 + MediaQuery.of(context).padding.top,
          bottomBarHeight: 72 + MediaQuery.of(context).padding.bottom,
          backgroundColor: widget.pageBackgroundColor,
        );
      },
    );
  }
}

class _WebQuranPageItem extends StatefulWidget {
  final int pageNum;
  final List<HighlightVerse> highlights;
  final void Function(int surah, int ayah) onVerseTapped;
  final double topBarHeight;
  final double bottomBarHeight;
  final Color backgroundColor;

  const _WebQuranPageItem({
    required this.pageNum,
    required this.highlights,
    required this.onVerseTapped,
    required this.topBarHeight,
    required this.bottomBarHeight,
    required this.backgroundColor,
  });

  @override
  State<_WebQuranPageItem> createState() => _WebQuranPageItemState();
}

class _WebQuranPageItemState extends State<_WebQuranPageItem> {
  late Future<QuranPageBundle> _futureBundle;

  @override
  void initState() {
    super.initState();
    _futureBundle = QuranApiService.fetchPage(widget.pageNum, isDiyanet: false);
  }

  @override
  void didUpdateWidget(covariant _WebQuranPageItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNum != widget.pageNum) {
      _futureBundle = QuranApiService.fetchPage(widget.pageNum, isDiyanet: false);
    }
  }

  String _toArabicDigits(int number) {
    final digits = {
      '0': '٠',
      '1': '١',
      '2': '٢',
      '3': '٣',
      '4': '٤',
      '5': '٥',
      '6': '٦',
      '7': '٧',
      '8': '٨',
      '9': '٩',
    };
    return number.toString().split('').map((c) => digits[c] ?? c).join();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isAr = l10n.localeName == 'ar';

    return FutureBuilder<QuranPageBundle>(
      future: _futureBundle,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.secondary,
              strokeWidth: 2,
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, color: AppColors.secondary, size: 48),
                const SizedBox(height: 12),
                Text(
                  l10n.failedToLoadData,
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _futureBundle = QuranApiService.fetchPage(widget.pageNum, isDiyanet: false);
                    });
                  },
                  child: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
                ),
              ],
            ),
          );
        }

        final bundle = snapshot.data!;
        final ayahs = bundle.arabic;

        // Group ayahs by Surah
        final surahGroups = <int, List<QuranAyah>>{};
        final orderedSurahIds = <int>[];
        for (final ayah in ayahs) {
          if (!surahGroups.containsKey(ayah.surahNumber)) {
            surahGroups[ayah.surahNumber] = [];
            orderedSurahIds.add(ayah.surahNumber);
          }
          surahGroups[ayah.surahNumber]!.add(ayah);
        }

        return Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              widget.topBarHeight + 16,
              16,
              widget.bottomBarHeight + 16,
            ),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: orderedSurahIds.map((surahId) {
                    final surahAyahs = surahGroups[surahId]!;
                    final firstAyah = surahAyahs.first;
                    final surahName = isAr
                        ? _MushafViewerScreenState._surahNames[surahId - 1]
                        : _MushafViewerScreenState._surahNamesEn[surahId - 1];

                    final List<Widget> surahWidgets = [];

                    final bool isSurahStart = firstAyah.numberInSurah == 1;

                    if (isSurahStart) {
                      surahWidgets.add(
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF1B4D3E).withValues(alpha: 0.8),
                                  const Color(0xFF153B2E).withValues(alpha: 0.9),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFD4AF37),
                                width: 1.5,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  'سُورَةُ $surahName',
                                  style: const TextStyle(
                                    fontFamily: 'Cairo',
                                    color: Color(0xFFD4AF37),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );

                      if (surahId != 1 && surahId != 9) {
                        surahWidgets.add(
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: Text(
                                'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E5E4E),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      }
                    }

                    final List<InlineSpan> spans = [];
                    for (final ayah in surahAyahs) {
                      String cleanText = ayah.text;
                      if (ayah.numberInSurah == 1 && surahId != 1 && surahId != 9) {
                        const bismillahStandard = "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ";
                        if (cleanText.startsWith(bismillahStandard)) {
                          cleanText = cleanText.substring(bismillahStandard.length).trim();
                        } else {
                          final index = cleanText.indexOf("ٱلرَّحِيمِ");
                          if (index != -1 && index < 45) {
                            cleanText = cleanText.substring(index + "ٱلرَّحِيمِ".length).trim();
                          }
                        }
                      }

                      final isHighlighted = widget.highlights.any((h) =>
                          h.surah == ayah.surahNumber &&
                          h.verseNumber == ayah.numberInSurah);
                      
                      final highlightColor = widget.highlights
                          .firstWhere(
                            (h) => h.surah == ayah.surahNumber && h.verseNumber == ayah.numberInSurah,
                            orElse: () => const HighlightVerse(surah: -1, verseNumber: -1, page: -1, color: Colors.transparent),
                          )
                          .color;

                      spans.add(
                        TextSpan(
                          text: '$cleanText ',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 24,
                            height: 1.8,
                            color: const Color(0xFF1E3A2F),
                            backgroundColor: isHighlighted ? highlightColor : Colors.transparent,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              widget.onVerseTapped(ayah.surahNumber, ayah.numberInSurah);
                            },
                        ),
                      );

                      spans.add(
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: GestureDetector(
                            onTap: () {
                              widget.onVerseTapped(ayah.surahNumber, ayah.numberInSurah);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFD4AF37),
                                        width: 1.8,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _toArabicDigits(ayah.numberInSurah),
                                    style: const TextStyle(
                                      fontFamily: 'Amiri',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E5E4E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    surahWidgets.add(
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text.rich(
                          TextSpan(children: spans),
                          textAlign: TextAlign.justify,
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: surahWidgets,
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

