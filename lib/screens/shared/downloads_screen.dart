import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../services/mushaf_download_service.dart';
import '../../services/quran_api_service.dart';
import '../../services/quran_audio_service.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _downloadService = MushafDownloadService();
  final _audioService = QuranAudioService();

  // State counts for Mushafs
  int _madinaDownloadedCount = 0;
  int _diyanetDownloadedCount = 0;
  bool _madinaIsDownloaded = false;
  bool _diyanetIsDownloaded = false;
  double _madinaSizeMB = 0.0;
  double _diyanetSizeMB = 0.0;

  // Downloading state for Mushafs
  String? _downloadingMushafType;
  double _mushafDownloadProgress = 0.0;

  // State counts for Tafsir
  bool _muyassarIsDownloaded = false;
  bool _englishIsDownloaded = false;
  bool _diyanetTafsirIsDownloaded = false;

  // Downloading state for Tafsir
  String? _downloadingTafsirEdition;
  double _tafsirDownloadProgress = 0.0;

  // State counts for Reciters
  final Map<String, int> _reciterDownloadedCounts = {};
  final Map<String, double> _reciterSizesMB = {};
  bool _loadingCounts = true;

  static const _qaris = <Map<String, String>>[
    {'id': 'ar.alafasy',            'name': 'مشاري العفاسي', 'nameEn': 'Mishary Alafasy'},
    {'id': 'ar.abdurrahmaansudais', 'name': 'عبد الرحمن السديس', 'nameEn': 'Abdul Rahman Al-Sudais'},
    {'id': 'ar.mahermuaiqly',       'name': 'ماهر المعيقلي', 'nameEn': 'Maher Al-Muaiqly'},
    {'id': 'ar.husary',             'name': 'محمود خليل الحصري', 'nameEn': 'Mahmoud Khalil Al-Husary'},
    {'id': 'ar.minshawi',           'name': 'محمد صديق المنشاوي', 'nameEn': 'Muhammad Siddiq Al-Minshawi'},
    {'id': 'ar.ghamadi',            'name': 'سعد الغامدي', 'nameEn': 'Saad Al-Ghamdi'},
    {'id': 'ar.ahmedajamy',         'name': 'أحمد العجمي', 'nameEn': 'Ahmed Al-Ajamy'},
    {'id': 'ar.abdulbasitmurattal', 'name': 'عبد الباسط عبد الصمد', 'nameEn': 'Abdul Basit Abdul Samad'},
    {'id': 'ar.yasseraddussari',    'name': 'ياسر الدوسري', 'nameEn': 'Yasser Al-Dossari'},
    {'id': 'ar.shuraym',            'name': 'سعود الشريم', 'nameEn': 'Saud Al-Shuraim'},
    {'id': 'ar.faresabbad',         'name': 'فارس عباد', 'nameEn': 'Fares Abbad'},
    {'id': 'ar.hudhaify',           'name': 'علي الحذيفي', 'nameEn': 'Ali Al-Huthaify'},
    {'id': 'ar.nasseralqatami',      'name': 'ناصر القطامي', 'nameEn': 'Nasser Al-Qatami'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _audioService.addListener(_onAudioStateChanged);
    _loadAllStatus();
  }

  @override
  void dispose() {
    _audioService.removeListener(_onAudioStateChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onAudioStateChanged() {
    if (mounted) {
      setState(() {});
      // Refresh audio downloaded count if a bulk download finishes
      if (!_audioService.isBulkDownloading) {
        _refreshReciterCounts();
      }
    }
  }

  Future<void> _loadAllStatus() async {
    setState(() => _loadingCounts = true);
    await Future.wait([
      _refreshMushafStatus(),
      _refreshTafsirStatus(),
      _refreshReciterCounts(),
    ]);
    if (mounted) {
      setState(() => _loadingCounts = false);
    }
  }

  Future<void> _refreshMushafStatus() async {
    final madinaCount = await _downloadService.getDownloadedPagesCount('madina');
    final diyanetCount = await _downloadService.getDownloadedPagesCount('diyanet');
    final madinaDone = await _downloadService.isDownloaded('madina');
    final diyanetDone = await _downloadService.isDownloaded('diyanet');
    final madinaMB = await _downloadService.getDirSizeInMB('madina');
    final diyanetMB = await _downloadService.getDirSizeInMB('diyanet');

    if (mounted) {
      setState(() {
        _madinaDownloadedCount = madinaCount;
        _diyanetDownloadedCount = diyanetCount;
        _madinaIsDownloaded = madinaDone;
        _diyanetIsDownloaded = diyanetDone;
        _madinaSizeMB = madinaMB;
        _diyanetSizeMB = diyanetMB;
      });
    }
  }

  Future<void> _refreshTafsirStatus() async {
    final muyassarDone = await QuranApiService.isTafsirDownloaded('ar.muyassar');
    final englishDone = await QuranApiService.isTafsirDownloaded('en.sahih');
    final diyanetDone = await QuranApiService.isTafsirDownloaded('tr.diyanet');

    if (mounted) {
      setState(() {
        _muyassarIsDownloaded = muyassarDone;
        _englishIsDownloaded = englishDone;
        _diyanetTafsirIsDownloaded = diyanetDone;
      });
    }
  }

  Future<void> _refreshReciterCounts() async {
    for (final qari in _qaris) {
      final id = qari['id']!;
      final count = await _audioService.getDownloadedAyahsCount(id);
      final sizeMB = await _audioService.getQariDirSizeInMB(id);
      _reciterDownloadedCounts[id] = count;
      _reciterSizesMB[id] = sizeMB;
    }
    if (mounted) {
      setState(() {});
    }
  }

  // ── Action handlers ──────────────────────────────────────────

  Future<void> _downloadMushaf(String type) async {
    if (_downloadingMushafType != null) return;
    setState(() {
      _downloadingMushafType = type;
      _mushafDownloadProgress = 0.0;
    });

    await _downloadService.startDownload(
      type: type,
      onProgress: (progress) {
        if (mounted && _downloadingMushafType == type) {
          setState(() {
            _mushafDownloadProgress = progress;
          });
        }
      },
      onCompleted: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).localeName == 'ar'
                    ? 'تم تحميل المصحف بنجاح ✓'
                    : 'Mushaf downloaded successfully ✓',
              ),
              backgroundColor: AppColors.success,
            ),
          );
          setState(() {
            _downloadingMushafType = null;
          });
          _refreshMushafStatus();
        }
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: AppColors.error,
            ),
          );
          setState(() {
            _downloadingMushafType = null;
          });
          _refreshMushafStatus();
        }
      },
    );
  }

  void _cancelMushafDownload() {
    _downloadService.cancelDownload();
    setState(() {
      _downloadingMushafType = null;
    });
    _refreshMushafStatus();
  }

  Future<void> _deleteMushaf(String type) async {
    final confirmed = await _showConfirmDialog();
    if (!confirmed) return;

    await _downloadService.deleteMushaf(type);
    await _refreshMushafStatus();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).localeName == 'ar'
                ? 'تم حذف ملفات المصحف بنجاح'
                : 'Mushaf files deleted successfully',
          ),
        ),
      );
    }
  }

  Future<void> _downloadTafsir(String edition) async {
    if (_downloadingTafsirEdition != null) return;
    setState(() {
      _downloadingTafsirEdition = edition;
      _tafsirDownloadProgress = 0.0;
    });

    try {
      await QuranApiService.downloadFullTafsir(edition, (progress) {
        if (mounted && _downloadingTafsirEdition == edition) {
          setState(() {
            _tafsirDownloadProgress = progress;
          });
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).localeName == 'ar'
                  ? 'تم تحميل التفسير بنجاح ✓'
                  : 'Tafsir downloaded successfully ✓',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _downloadingTafsirEdition = null;
        });
        _refreshTafsirStatus();
      }
    }
  }

  Future<void> _deleteTafsir(String edition) async {
    final confirmed = await _showConfirmDialog();
    if (!confirmed) return;

    await QuranApiService.deleteTafsir(edition);
    await _refreshTafsirStatus();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).localeName == 'ar'
                ? 'تم حذف التفسير بنجاح'
                : 'Tafsir deleted successfully',
          ),
        ),
      );
    }
  }

  Future<void> _downloadReciter(String qariId) async {
    await _audioService.startBulkDownload(
      qariId,
      onProgress: (progress) {
        // UI updates automatically via listener
      },
      onCompleted: () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).localeName == 'ar'
                    ? 'تم تحميل التلاوة كاملة بنجاح ✓'
                    : 'Recitation downloaded successfully ✓',
              ),
              backgroundColor: AppColors.success,
            ),
          );
          _refreshReciterCounts();
        }
      },
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: AppColors.error,
            ),
          );
          _refreshReciterCounts();
        }
      },
    );
  }

  void _cancelAudioDownload() {
    _audioService.cancelBulkDownload();
  }

  Future<void> _deleteReciter(String qariId) async {
    final confirmed = await _showConfirmDialog();
    if (!confirmed) return;

    await _audioService.deleteAudioForQari(qariId);
    await _refreshReciterCounts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).localeName == 'ar'
                ? 'تم حذف التلاوة بنجاح'
                : 'Recitation deleted successfully',
          ),
        ),
      );
    }
  }

  Future<bool> _showConfirmDialog() async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E22),
        title: Text(l10n.deleteConfirmTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(l10n.deleteConfirmMessage, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButton, style: const TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.deleteButton, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ── Build methods ────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isAr = l10n.localeName == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          l10n.downloadsTitle,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.secondary,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.secondary,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: [
            Tab(text: l10n.downloadsTabMushafs),
            Tab(text: l10n.downloadsTabTafsirs),
            Tab(text: l10n.downloadsTabReciters),
          ],
        ),
      ),
      body: _loadingCounts
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMushafTab(l10n, isAr),
                _buildTafsirTab(l10n, isAr),
                _buildRecitersTab(l10n, isAr),
              ],
            ),
    );
  }

  // ── TAB 1: MUSHAFS ───────────────────────────────────────────
  Widget _buildMushafTab(AppLocalizations l10n, bool isAr) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.medium),
      children: [
        // Madina Mushaf Card
        _buildDownloadCard(
          title: l10n.madinaMushafName,
          subtitle: _downloadingMushafType == 'madina'
              ? l10n.downloadProgress('${(_mushafDownloadProgress * 100).toStringAsFixed(0)}%')
              : l10n.downloadedPagesCount(_madinaDownloadedCount, 604),
          icon: Icons.menu_book_rounded,
          isDownloaded: _madinaIsDownloaded,
          isDownloading: _downloadingMushafType == 'madina',
          progress: _mushafDownloadProgress,
          onDownload: () => _downloadMushaf('madina'),
          onCancel: _cancelMushafDownload,
          onDelete: () => _deleteMushaf('madina'),
          sizeInfo: _madinaSizeMB > 1
              ? '${_madinaSizeMB.toStringAsFixed(0)} MB'
              : '~135 MB',
        ),
        const SizedBox(height: AppSpacing.medium),
        // Diyanet Mushaf Card
        _buildDownloadCard(
          title: l10n.diyanetMushafName,
          subtitle: _downloadingMushafType == 'diyanet'
              ? l10n.downloadProgress('${(_mushafDownloadProgress * 100).toStringAsFixed(0)}%')
              : l10n.downloadedPagesCount(_diyanetDownloadedCount, 605),
          icon: Icons.import_contacts_rounded,
          isDownloaded: _diyanetIsDownloaded,
          isDownloading: _downloadingMushafType == 'diyanet',
          progress: _mushafDownloadProgress,
          onDownload: () => _downloadMushaf('diyanet'),
          onCancel: _cancelMushafDownload,
          onDelete: () => _deleteMushaf('diyanet'),
          sizeInfo: _diyanetSizeMB > 1
              ? '${_diyanetSizeMB.toStringAsFixed(0)} MB'
              : '~194 MB',
        ),
      ],
    );
  }

  // ── TAB 2: TAFSIRS ───────────────────────────────────────────
  Widget _buildTafsirTab(AppLocalizations l10n, bool isAr) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.medium),
      children: [
        // Muyassar Arabic Tafsir
        _buildDownloadCard(
          title: l10n.muyassarTafsirName,
          subtitle: _downloadingTafsirEdition == 'ar.muyassar'
              ? l10n.downloadProgress('${(_tafsirDownloadProgress * 100).toStringAsFixed(0)}%')
              : (_muyassarIsDownloaded ? l10n.downloadedStatus : l10n.notDownloadedStatus),
          icon: Icons.description_rounded,
          isDownloaded: _muyassarIsDownloaded,
          isDownloading: _downloadingTafsirEdition == 'ar.muyassar',
          progress: _tafsirDownloadProgress,
          onDownload: () => _downloadTafsir('ar.muyassar'),
          onCancel: () {}, // Not cancellable safely mid-batch
          onDelete: () => _deleteTafsir('ar.muyassar'),
          sizeInfo: '1.2 MB',
        ),
        const SizedBox(height: AppSpacing.medium),
        // English Sahih International Translation
        _buildDownloadCard(
          title: l10n.englishTranslationName,
          subtitle: _downloadingTafsirEdition == 'en.sahih'
              ? l10n.downloadProgress('${(_tafsirDownloadProgress * 100).toStringAsFixed(0)}%')
              : (_englishIsDownloaded ? l10n.downloadedStatus : l10n.notDownloadedStatus),
          icon: Icons.translate_rounded,
          isDownloaded: _englishIsDownloaded,
          isDownloading: _downloadingTafsirEdition == 'en.sahih',
          progress: _tafsirDownloadProgress,
          onDownload: () => _downloadTafsir('en.sahih'),
          onCancel: () {},
          onDelete: () => _deleteTafsir('en.sahih'),
          sizeInfo: '1.4 MB',
        ),
        const SizedBox(height: AppSpacing.medium),
        // Turkish Diyanet Meali Translation
        _buildDownloadCard(
          title: l10n.turkishTranslationName,
          subtitle: _downloadingTafsirEdition == 'tr.diyanet'
              ? l10n.downloadProgress('${(_tafsirDownloadProgress * 100).toStringAsFixed(0)}%')
              : (_diyanetTafsirIsDownloaded ? l10n.downloadedStatus : l10n.notDownloadedStatus),
          icon: Icons.translate_rounded,
          isDownloaded: _diyanetTafsirIsDownloaded,
          isDownloading: _downloadingTafsirEdition == 'tr.diyanet',
          progress: _tafsirDownloadProgress,
          onDownload: () => _downloadTafsir('tr.diyanet'),
          onCancel: () {},
          onDelete: () => _deleteTafsir('tr.diyanet'),
          sizeInfo: '1.5 MB',
        ),
      ],
    );
  }

  // ── TAB 3: RECITERS ──────────────────────────────────────────
  Widget _buildRecitersTab(AppLocalizations l10n, bool isAr) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.medium),
      itemCount: _qaris.length,
      itemBuilder: (context, index) {
        final qari = _qaris[index];
        final id = qari['id']!;
        final name = isAr ? qari['name']! : qari['nameEn']!;

        final count = _reciterDownloadedCounts[id] ?? 0;
        final isDownloaded = count >= 6230; // completed or nearly completed
        final isDownloading = _audioService.isBulkDownloading && _audioService.bulkDownloadQari == id;
        final progress = isDownloading ? _audioService.bulkDownloadProgress : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.medium),
          child: _buildDownloadCard(
            title: name,
            subtitle: isDownloading
                ? l10n.downloadProgress('${(progress * 100).toStringAsFixed(0)}%')
                : l10n.downloadedAyahsCount(count, 6236),
            icon: Icons.record_voice_over_rounded,
            isDownloaded: isDownloaded,
            isDownloading: isDownloading,
            progress: progress,
            onDownload: () => _downloadReciter(id),
            onCancel: _cancelAudioDownload,
            onDelete: () => _deleteReciter(id),
            sizeInfo: (_reciterSizesMB[id] ?? 0.0) > 1
                ? '${(_reciterSizesMB[id]!).toStringAsFixed(0)} MB'
                : '~400–800 MB',
          ),
        );
      },
    );
  }

  // ── REUSABLE DOWNLOAD CARD WIDGET ────────────────────────────
  Widget _buildDownloadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDownloaded,
    required bool isDownloading,
    required double progress,
    required VoidCallback onDownload,
    required VoidCallback onCancel,
    required VoidCallback onDelete,
    required String sizeInfo,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                children: [
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDownloading
                          ? AppColors.primary
                          : (isDownloaded ? AppColors.success : AppColors.textSecondary),
                      fontWeight: isDownloaded || isDownloading ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!isDownloading && sizeInfo.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        sizeInfo,
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ),
                ],
              ),
            ),
            trailing: isDownloading
                ? IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 28),
                    onPressed: onCancel,
                  )
                : (isDownloaded
                    ? IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 26),
                        onPressed: onDelete,
                      )
                    : IconButton(
                        icon: const Icon(Icons.download_for_offline_outlined, color: AppColors.primary, size: 28),
                        onPressed: onDownload,
                      )),
          ),
          if (isDownloading)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.progressTrack,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
