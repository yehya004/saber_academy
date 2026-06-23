import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/quran_api_service.dart';
import '../../services/quran_audio_service.dart';

/// Bottom-sheet panel showing Quran text, English/Turkish translation,
/// Arabic tafsir (ar.muyassar), and integrated per-ayah audio playback.
class TafsirPanel extends StatefulWidget {
  final int  mushafPage;
  final String mushafType;
  /// When true, starts playing the first ayah automatically after loading.
  final bool autoPlay;

  const TafsirPanel({
    super.key,
    required this.mushafPage,
    this.mushafType = 'madina',
    this.autoPlay = false,
  });

  @override
  State<TafsirPanel> createState() => _TafsirPanelState();
}

class _TafsirPanelState extends State<TafsirPanel>
    with SingleTickerProviderStateMixin {
  // ── Qari list ────────────────────────────────────────────────
  static const _qaris = <Map<String, String>>[
    {'id': 'ar.alafasy',            'name': 'مشاري العفاسي'},
    {'id': 'ar.abdurrahmaansudais', 'name': 'عبد الرحمن السديس'},
    {'id': 'ar.mahermuaiqly',       'name': 'ماهر المعيقلي'},
    {'id': 'ar.husary',             'name': 'محمود خليل الحصري'},
    {'id': 'ar.minshawi',           'name': 'محمد صديق المنشاوي'},
    {'id': 'ar.ghamadi',            'name': 'سعد الغامدي'},
    {'id': 'ar.ahmedajamy',         'name': 'أحمد العجمي'},
    {'id': 'ar.abdulbasitmurattal', 'name': 'عبد الباسط عبد الصمد'},
    {'id': 'ar.yasseraddussari',    'name': 'ياسر الدوسري'},
    {'id': 'ar.shuraym',            'name': 'سعود الشريم'},
    {'id': 'ar.hudhaify',           'name': 'علي الحذيفي'},
    {'id': 'ar.nasseralqatami',      'name': 'ناصر القطامي'},
  ];

  // ── State ────────────────────────────────────────────────────
  late final TabController _tabs;
  final _audioService = QuranAudioService();

  QuranPageBundle? _bundle;
  bool _loading   = true;
  bool _hasError  = false;

  int get _playingIdx => _audioService.playingPage == widget.mushafPage ? _audioService.playingAyahIndex : -1;
  bool get _isPlaying => _audioService.isPlaying && _audioService.playingPage == widget.mushafPage;
  String get _selectedQari => _audioService.selectedQari;
  int get _repeatCount => _audioService.repeatCount;

  // ── Colours ──────────────────────────────────────────────────
  static const _gold    = Color(0xFFD4AF37);
  static const _bgSheet = Color(0xFF1A1A1E);
  static const _bgBar   = Color(0xFF0D1A14);

  // ── Init / Dispose ───────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _audioService.addListener(_onAudioStateChanged);
    _loadData();
  }

  @override
  void dispose() {
    _audioService.removeListener(_onAudioStateChanged);
    _tabs.dispose();
    super.dispose();
  }

  void _onAudioStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // ── Data ────────────────────────────────────────────────────
  Future<void> _loadData() async {
    try {
      final b = await QuranApiService.fetchPage(
        widget.mushafPage,
        isDiyanet: widget.mushafType == 'diyanet',
      );
      if (!mounted) return;
      setState(() {
        _bundle  = b;
        _loading = false;
      });
      if (widget.autoPlay && b.arabic.isNotEmpty) {
        if (_audioService.playingPage != widget.mushafPage || !_audioService.isPlaying) {
          await _audioService.playPage(widget.mushafPage, b, type: widget.mushafType, initialIndex: 0);
        }
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _hasError = true; });
    }
  }

  // ── Audio ───────────────────────────────────────────────────
  Future<void> _toggleAyah(int idx) async {
    if (_audioService.playingPage == widget.mushafPage) {
      await _audioService.toggleAyah(idx);
    } else {
      if (_bundle == null) return;
      await _audioService.playAyahDirectly(widget.mushafPage, _bundle!, idx, type: widget.mushafType);
    }
  }

  void _cycleRepeatCount() {
    _audioService.cycleRepeatCount();
  }

  // ── Build ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.80,
      decoration: const BoxDecoration(
        color:        _bgSheet,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        children: [
          // ── Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width:  40,
            height: 4,
            decoration: BoxDecoration(
              color:        Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.tafsirPanelTitle(widget.mushafPage),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildQariPicker(l10n),
                    if (_isPlaying)
                      IconButton(
                        icon:  const Icon(Icons.stop_circle_outlined,
                            color: Colors.white38),
                        onPressed: () async {
                          await _audioService.stop();
                        },
                        padding:     EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ── Tab bar
          TabBar(
            controller:           _tabs,
            labelColor:           _gold,
            unselectedLabelColor: Colors.white38,
            indicatorColor:       _gold,
            labelStyle:           const TextStyle(fontSize: 12),
            tabs: [
              Tab(text: l10n.tafsirTabQuran),
              const Tab(text: 'English'),
              const Tab(text: 'Türkçe'),
              Tab(text: l10n.tafsirTabTafsir),
            ],
          ),

          // ── Content
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: _gold, strokeWidth: 2))
                : (_hasError || _bundle == null || _bundle!.isEmpty)
                    ? _buildError(l10n)
                    : TabBarView(
                        controller: _tabs,
                        children: [
                          _buildList(l10n, _bundle!.arabic,  isRtl: true),
                          _buildList(l10n, _bundle!.english, isRtl: false),
                          _buildList(l10n, _bundle!.turkish, isRtl: false),
                          _buildList(l10n, _bundle!.tafsir,  isRtl: true),
                        ],
                      ),
          ),

          // ── Persistent audio mini-bar (shown only while an ayah is active)
          if (_bundle != null &&
              _playingIdx >= 0 &&
              _playingIdx < _bundle!.arabic.length)
            _buildAudioBar(l10n),
        ],
      ),
    );
  }

  // ── Error state
  Widget _buildError(AppLocalizations l10n) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white24, size: 42),
            const SizedBox(height: 12),
            Text(l10n.failedToLoadData,
                style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() { _loading = true; _hasError = false; });
                _loadData();
              },
              child: Text(l10n.retryButton,
                  style: const TextStyle(color: _gold)),
            ),
          ],
        ),
      );

  // ── Ayah list
  Widget _buildList(AppLocalizations l10n, List<QuranAyah> ayahs, {required bool isRtl}) {
    if (ayahs.isEmpty) {
      return Center(
          child: Text(l10n.notAvailable,
              style: const TextStyle(color: Colors.white38, fontSize: 13)));
    }
    return ListView.builder(
      padding:   const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      itemCount: ayahs.length,
      itemBuilder: (_, i) {
        final ayah      = ayahs[i];
        final isActive  = _playingIdx == i;
        final isPlaying = isActive && _isPlaying;

        return Container(
          margin:  const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isActive
                ? _gold.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: isActive
                ? Border.all(color: _gold.withValues(alpha: 0.35))
                : null,
          ),
          child: Column(
            crossAxisAlignment:
                isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Ayah header row
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _toggleAyah(i),
                    child: Container(
                      width:  30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isActive
                            ? _gold.withValues(alpha: 0.20)
                            : Colors.white12,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        size:  16,
                        color: isActive ? _gold : Colors.white54,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.ayahLabel(ayah.surahNameAr, '${ayah.numberInSurah}'),
                      style: TextStyle(
                        color:    isActive ? _gold : Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Ayah text
              Text(
                ayah.text,
                style: TextStyle(
                  color:    Colors.white.withValues(alpha: 0.88),
                  fontSize: isRtl ? 17 : 13,
                  height:   isRtl ? 2.0 : 1.5,
                ),
                textAlign:     isRtl ? TextAlign.right : TextAlign.left,
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Audio mini-bar (prev | play/pause | next | ayah info)
  Widget _buildAudioBar(AppLocalizations l10n) {
    final ayah = _bundle!.arabic[_playingIdx];
    return Container(
      color:   _bgBar,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.skip_previous,
                color: _playingIdx > 0 ? Colors.white70 : Colors.white24,
                size: 22),
            onPressed: _playingIdx > 0 ? () => _audioService.skipPrevious() : null,
            padding:     EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          ),
          IconButton(
            icon: Icon(
              _isPlaying
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_filled,
              color: _gold,
              size:  36,
            ),
            onPressed: () => _audioService.togglePlay(),
            padding:     EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
          IconButton(
            icon: Icon(Icons.skip_next,
                color: _playingIdx < (_bundle!.arabic.length - 1)
                    ? Colors.white70
                    : Colors.white24,
                    size: 22),
            onPressed: _playingIdx < (_bundle!.arabic.length - 1)
                ? () => _audioService.skipNext()
                : null,
            padding:     EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          ),
          IconButton(
            icon: Icon(
              _repeatCount == 1 ? Icons.repeat_one_outlined : Icons.repeat,
              color: _repeatCount > 1 ? _gold : Colors.white70,
              size: 20,
            ),
            onPressed: _cycleRepeatCount,
            padding:     EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            tooltip: l10n.localeName == 'ar' ? 'تكرار الآية' : 'Repeat Ayah',
          ),
          Text(
            _repeatCount == 999 ? '∞' : '${_repeatCount}x',
            style: TextStyle(
              color: _repeatCount > 1 ? _gold : Colors.white54,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.ayahLabel(ayah.surahNameAr, '${ayah.numberInSurah}'),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getQariName(BuildContext context, String id, String defaultName) {
    final l10n = AppLocalizations.of(context);
    final isAr = l10n.localeName == 'ar';
    if (isAr) return defaultName;

    switch (id) {
      case 'ar.alafasy': return 'Mishary Alafasy';
      case 'ar.abdurrahmaansudais': return 'Abdul Rahman Al-Sudais';
      case 'ar.mahermuaiqly': return 'Maher Al-Muaiqly';
      case 'ar.husary': return 'Mahmoud Khalil Al-Husary';
      case 'ar.minshawi': return 'Mohamed Siddiq El-Minshawi';
      case 'ar.ghamadi': return 'Saad Al-Ghamdi';
      case 'ar.ahmedajamy': return 'Ahmed Al-Ajmy';
      case 'ar.abdulbasitmurattal': return 'Abdul Basit Abdul Samad';
      case 'ar.yasseraddussari': return 'Yasser Al-Dosari';
      case 'ar.shuraym': return 'Saud Al-Shuraim';
      case 'ar.hudhaify': return 'Ali Al-Hudhaify';
      case 'ar.nasseralqatami': return 'Nasser Al-Qatami';
      default: return defaultName;
    }
  }

  // ── Qari picker button
  Widget _buildQariPicker(AppLocalizations l10n) {
    final rawName = _qaris.firstWhere(
      (q) => q['id'] == _selectedQari,
      orElse: () => _qaris.first,
    )['name']!;
    final name = _getQariName(context, _selectedQari, rawName);
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: _gold,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: const Icon(Icons.record_voice_over_outlined, size: 16),
      label: Text(name, style: const TextStyle(fontSize: 11)),
      onPressed: () => _showQariDialog(l10n),
    );
  }

  void _showQariDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (_) => SimpleDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: Text(l10n.selectReciterTitle,
            style: const TextStyle(color: Colors.white, fontSize: 15)),
        children: _qaris.map((q) {
          final isSelected = q['id'] == _selectedQari;
          return SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _audioService.setSelectedQari(q['id']!);
            },
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isSelected ? _gold : Colors.white38,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(_getQariName(context, q['id']!, q['name']!),
                    style: TextStyle(
                      color: isSelected ? _gold : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    )),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
