import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/web_audio_player.dart';
import 'quran_api_service.dart';

class QuranAudioService extends ChangeNotifier {
  static final QuranAudioService _instance = QuranAudioService._internal();
  factory QuranAudioService() => _instance;

  QuranAudioService._internal() {
    _initPrefs();
    if (kIsWeb) {
      _webPlayer = WebAudioPlayer('quran_audio_player');
      _webPlayer!.onStateChanged = (stateStr) {
        _isPlaying = stateStr == 'playing';
        notifyListeners();
      };
      _webPlayer!.onComplete = () {
        _handleAyahCompletion();
      };
    } else {
      _player = AudioPlayer();
      _player!.onPlayerStateChanged.listen((s) {
        _isPlaying = s == PlayerState.playing;
        notifyListeners();
      });
      _player!.onPlayerComplete.listen((_) {
        _handleAyahCompletion();
      });
    }
  }

  Future<void> unlockWeb() async {
    if (kIsWeb) {
      try {
        _webPlayer?.play('data:audio/wav;base64,UklGRigAAABXQVZFZm10IBIAAAABAAEARKwAAIhYAQACABAAAABkYXRhAgAAAAAA');
      } catch (e) {
        debugPrint("Web audio unlock error: $e");
      }
    }
  }

  AudioPlayer? _player;
  WebAudioPlayer? _webPlayer;
  final _dio = Dio();
  SharedPreferences? _prefs;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  int _playingPage = -1;
  int get playingPage => _playingPage;

  int _playingAyahIndex = -1;
  int get playingAyahIndex => _playingAyahIndex;

  String _selectedQari = 'ar.alafasy';
  String get selectedQari => _selectedQari;

  int _repeatCount = 1;
  int get repeatCount => _repeatCount;

  int _currentRepeatPlayed = 0;
  int get currentRepeatPlayed => _currentRepeatPlayed;

  String _mushafType = 'madina';
  String get mushafType => _mushafType;

  QuranPageBundle? _bundle;
  QuranPageBundle? get bundle => _bundle;

  // New audio features: Playback Speed and Single Ayah Repeat
  double _playbackSpeed = 1.0;
  double get playbackSpeed => _playbackSpeed;

  bool _repeatSingleAyah = false;
  bool get repeatSingleAyah => _repeatSingleAyah;

  // New audio features: Download Manager State
  bool _isAudioDownloading = false;
  bool get isAudioDownloading => _isAudioDownloading;

  double _audioDownloadProgress = 0.0;
  double get audioDownloadProgress => _audioDownloadProgress;

  String? _audioDownloadError;
  String? get audioDownloadError => _audioDownloadError;

  // Bulk downloads state
  bool _isBulkDownloading = false;
  bool get isBulkDownloading => _isBulkDownloading;

  String? _bulkDownloadQari;
  String? get bulkDownloadQari => _bulkDownloadQari;

  double _bulkDownloadProgress = 0.0;
  double get bulkDownloadProgress => _bulkDownloadProgress;

  bool _cancelBulkDownload = false;

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    final savedQari = _prefs?.getString('selected_qari');
    if (savedQari != null) {
      _selectedQari = savedQari;
      notifyListeners();
    }
  }

  void setSelectedQari(String qari) {
    if (qari == _selectedQari) return;
    _selectedQari = qari;
    _prefs?.setString('selected_qari', qari);
    if (_isPlaying) {
      stop();
    }
    notifyListeners();
  }

  Future<void> setPlaybackSpeed(double speed) async {
    if (speed == _playbackSpeed) return;
    _playbackSpeed = speed;
    if (_isPlaying) {
      if (kIsWeb) {
        _webPlayer?.setPlaybackRate(speed);
      } else {
        await _player?.setPlaybackRate(speed);
      }
    }
    notifyListeners();
  }

  void toggleRepeatSingleAyah() {
    _repeatSingleAyah = !_repeatSingleAyah;
    _currentRepeatPlayed = 0;
    notifyListeners();
  }

  static const Map<String, String> _everyAyahFolders = {
    'ar.alafasy': 'Alafasy_128kbps',
    'ar.abdurrahmaansudais': 'Abdurrahmaan_As-Sudais_192kbps',
    'ar.mahermuaiqly': 'Maher_AlMuaiqly_64kbps',
    'ar.husary': 'Husary_128kbps',
    'ar.minshawi': 'Minshawy_Murattal_128kbps',
    'ar.ghamadi': 'Ghamadi_40kbps',
    'ar.ahmedajamy': 'Ahmed_ibn_Ali_al-Ajamy_128kbps_ketaballah.net',
    'ar.abdulbasitmurattal': 'Abdul_Basit_Murattal_192kbps',
    'ar.yasseraddussari': 'Yasser_Ad-Dussary_128kbps',
    'ar.shuraym': 'Saood_ash-Shuraym_128kbps',
    'ar.hudhaify': 'Hudhaify_128kbps',
    'ar.nasseralqatami': 'Nasser_Alqatami_128kbps',
  };

  String _getAudioUrl(String qari, int absoluteAyah, int surahNum, int numberInSurah) {
    final folder = _everyAyahFolders[qari];
    if (folder != null) {
      final s = surahNum.toString().padLeft(3, '0');
      final a = numberInSurah.toString().padLeft(3, '0');
      return 'https://everyayah.com/data/$folder/$s$a.mp3';
    }
    return 'https://cdn.islamic.network/quran/audio/128/$qari/$absoluteAyah.mp3';
  }

  // Local Audio paths helpers
  Future<String> _getLocalAudioPath(String qari, int ayahNumber) async {
    if (kIsWeb) return '';
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/quran_audio/$qari');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return '${dir.path}/$ayahNumber.mp3';
  }

  Future<bool> isAyahDownloaded(String qari, int ayahNumber) async {
    if (kIsWeb) return false;
    final path = await _getLocalAudioPath(qari, ayahNumber);
    final file = File(path);
    return await file.exists() && file.lengthSync() > 0;
  }

  Future<bool> isPageAudioDownloaded(int page, QuranPageBundle? pageBundle) async {
    if (kIsWeb) return false;
    if (pageBundle == null || pageBundle.arabic.isEmpty) return false;
    for (final ayah in pageBundle.arabic) {
      final exists = await isAyahDownloaded(_selectedQari, ayah.number);
      if (!exists) return false;
    }
    return true;
  }

  // Audio Downloading Methods
  Future<void> downloadPageAudio(int page, QuranPageBundle pageBundle) async {
    if (kIsWeb) return;
    if (_isAudioDownloading) return;
    _isAudioDownloading = true;
    _audioDownloadProgress = 0.0;
    _audioDownloadError = null;
    notifyListeners();

    try {
      final ayahs = pageBundle.arabic;
      int downloaded = 0;
      for (final ayah in ayahs) {
        final localPath = await _getLocalAudioPath(_selectedQari, ayah.number);
        final file = File(localPath);
        if (!await file.exists() || file.lengthSync() == 0) {
          final url = _getAudioUrl(_selectedQari, ayah.number, ayah.surahNumber, ayah.numberInSurah);
          await _dio.download(url, localPath);
        }
        downloaded++;
        _audioDownloadProgress = downloaded / ayahs.length;
        notifyListeners();
      }
    } catch (e) {
      _audioDownloadError = e.toString();
    } finally {
      _isAudioDownloading = false;
      notifyListeners();
    }
  }

  Future<void> playPage(int page, QuranPageBundle pageBundle, {String type = 'madina', int initialIndex = 0, bool autoPlay = true}) async {
    _playingPage = page;
    _bundle = pageBundle;
    _mushafType = type;
    _playingAyahIndex = initialIndex;
    _currentRepeatPlayed = 0;
    
    if (autoPlay && _bundle != null && _bundle!.arabic.isNotEmpty) {
      await _playActiveAyah();
    } else {
      notifyListeners();
    }
  }

  Future<void> _playActiveAyah({bool isRepeat = false}) async {
    if (_bundle == null || _playingAyahIndex < 0 || _playingAyahIndex >= _bundle!.arabic.length) return;
    
    if (!isRepeat) {
      _currentRepeatPlayed = 0;
    }
    
    final ayah = _bundle!.arabic[_playingAyahIndex];
    
    try {
      if (kIsWeb) {
        final url = _getAudioUrl(_selectedQari, ayah.number, ayah.surahNumber, ayah.numberInSurah);
        _webPlayer?.play(url, playbackRate: _playbackSpeed);
        _isPlaying = true;
        notifyListeners();
        return;
      }

      await _player?.stop();
      final localPath = await _getLocalAudioPath(_selectedQari, ayah.number);
      final localFile = File(localPath);
      if (await localFile.exists() && localFile.lengthSync() > 0) {
        await _player?.play(DeviceFileSource(localPath));
      } else {
        final url = _getAudioUrl(_selectedQari, ayah.number, ayah.surahNumber, ayah.numberInSurah);
        await _player?.play(UrlSource(url));
      }
      await _player?.setPlaybackRate(_playbackSpeed);
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      debugPrint("QuranAudioService play error: $e");
    }
  }

  Future<void> togglePlay() async {
    if (_playingPage == -1 || _bundle == null || _bundle!.arabic.isEmpty) return;
    
    if (_isPlaying) {
      if (kIsWeb) {
        _webPlayer?.pause();
      } else {
        await _player?.pause();
      }
    } else {
      if (_playingAyahIndex == -1) {
        _playingAyahIndex = 0;
      }
      await _playActiveAyah(isRepeat: true); // resume playing current ayah
    }
  }

  Future<void> toggleAyah(int idx) async {
    if (_playingAyahIndex == idx && _isPlaying) {
      if (kIsWeb) {
        _webPlayer?.pause();
      } else {
        await _player?.pause();
      }
    } else {
      _playingAyahIndex = idx;
      await _playActiveAyah();
    }
  }

  Future<void> playAyahDirectly(int page, QuranPageBundle pageBundle, int idx, {String type = 'madina'}) async {
    _playingPage = page;
    _bundle = pageBundle;
    _mushafType = type;
    _playingAyahIndex = idx;
    await _playActiveAyah();
  }

  Future<void> stop() async {
    if (kIsWeb) {
      _webPlayer?.dispose();
    } else {
      await _player?.stop();
    }
    _playingAyahIndex = -1;
    _playingPage = -1;
    _isPlaying = false;
    _currentRepeatPlayed = 0;
    notifyListeners();
  }

  Future<void> skipNext() async {
    if (_bundle == null || _playingAyahIndex == -1) return;
    if (_playingAyahIndex < _bundle!.arabic.length - 1) {
      _playingAyahIndex++;
      await _playActiveAyah();
    }
  }

  Future<void> skipPrevious() async {
    if (_bundle == null || _playingAyahIndex == -1) return;
    if (_playingAyahIndex > 0) {
      _playingAyahIndex--;
      await _playActiveAyah();
    }
  }

  void _handleAyahCompletion() {
    _currentRepeatPlayed++;
    if (_repeatSingleAyah) {
      _playActiveAyah(isRepeat: true);
    } else if (_repeatCount == 999 || _currentRepeatPlayed < _repeatCount) {
      _playActiveAyah(isRepeat: true);
    } else {
      _currentRepeatPlayed = 0;
      _advanceAyah();
    }
  }

  Future<void> _advancePage() async {
    final totalPages = _mushafType == 'diyanet' ? 605 : 604;
    if (_playingPage == -1 || _playingPage >= totalPages) {
      stop();
      return;
    }
    final nextPage = _playingPage + 1;
    try {
      final nextBundle = await QuranApiService.fetchPage(
        nextPage,
        isDiyanet: _mushafType == 'diyanet',
      );
      if (nextBundle.arabic.isNotEmpty) {
        _playingPage = nextPage;
        _bundle = nextBundle;
        _playingAyahIndex = 0;
        _currentRepeatPlayed = 0;
        await _playActiveAyah();
      } else {
        stop();
      }
    } catch (e) {
      debugPrint("Error advancing to page $nextPage: $e");
      stop();
    }
  }

  void _advanceAyah() {
    if (_bundle == null) return;
    final next = _playingAyahIndex + 1;
    if (next < _bundle!.arabic.length) {
      _playingAyahIndex = next;
      _playActiveAyah();
    } else {
      _advancePage();
    }
  }

  void cycleRepeatCount() {
    if (_repeatCount == 1) {
      _repeatCount = 3;
    } else if (_repeatCount == 3) {
      _repeatCount = 5;
    } else if (_repeatCount == 5) {
      _repeatCount = 10;
    } else if (_repeatCount == 10) {
      _repeatCount = 999; // infinite
    } else {
      _repeatCount = 1;
    }
    _currentRepeatPlayed = 0;
    notifyListeners();
  }

  static const List<int> _surahVerseCounts = [
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128,
    111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73,
    54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60,
    49, 62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12, 12, 30, 52, 52,
    44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42, 29, 19, 36, 25, 22, 17, 19,
    26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3,
    6, 3, 5, 4, 5, 6
  ];

  static List<int> absoluteToSurahAyah(int absoluteAyah) {
    int currentSum = 0;
    for (int sIdx = 0; sIdx < _surahVerseCounts.length; sIdx++) {
      final count = _surahVerseCounts[sIdx];
      if (absoluteAyah <= currentSum + count) {
        final surahNum = sIdx + 1;
        final numberInSurah = absoluteAyah - currentSum;
        return [surahNum, numberInSurah];
      }
      currentSum += count;
    }
    return [1, 1];
  }

  /// Returns the total size of downloaded audio files for a qari in MB
  Future<double> getQariDirSizeInMB(String qari) async {
    if (kIsWeb) return 0.0;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDir.path}/quran_audio/$qari');
      if (!await dir.exists()) return 0.0;
      int totalBytes = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          totalBytes += await entity.length();
        }
      }
      return totalBytes / (1024 * 1024);
    } catch (_) {
      return 0.0;
    }
  }

  Future<int> getDownloadedAyahsCount(String qari) async {
    if (kIsWeb) return 0;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDir.path}/quran_audio/$qari');
      if (!await dir.exists()) return 0;
      final files = dir.listSync();
      int count = 0;
      for (final f in files) {
        if (f is File && f.path.endsWith('.mp3') && f.lengthSync() > 0) {
          count++;
        }
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  void cancelBulkDownload() {
    _cancelBulkDownload = true;
  }

  Future<void> startBulkDownload(
    String qari, {
    required void Function(double progress) onProgress,
    required VoidCallback onCompleted,
    required void Function(String error) onError,
  }) async {
    if (kIsWeb) {
      onError('التحميل غير مدعوم على المتصفح.');
      return;
    }
    if (_isBulkDownloading) {
      onError('هناك عملية تحميل أخرى قيد التشغيل بالفعل.');
      return;
    }

    _isBulkDownloading = true;
    _bulkDownloadQari = qari;
    _bulkDownloadProgress = 0.0;
    _cancelBulkDownload = false;
    notifyListeners();

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDir.path}/quran_audio/$qari');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      int downloaded = await getDownloadedAyahsCount(qari);
      onProgress(downloaded / 6236.0);

      // Download in parallel batches of 5
      const batchSize = 5;
      for (int i = 1; i <= 6236; i += batchSize) {
        if (_cancelBulkDownload) break;

        final end = (i + batchSize - 1).clamp(1, 6236);
        final downloadFutures = <Future<void>>[];

        for (int ayah = i; ayah <= end; ayah++) {
          final file = File('${dir.path}/$ayah.mp3');
          if (await file.exists() && file.lengthSync() > 0) {
            continue;
          }

          final mapping = absoluteToSurahAyah(ayah);
          final surahNum = mapping[0];
          final ayahInSurah = mapping[1];
          final url = _getAudioUrl(qari, ayah, surahNum, ayahInSurah);

          downloadFutures.add(
            _dio.download(url, file.path).then((_) {
              downloaded++;
              _bulkDownloadProgress = downloaded / 6236.0;
              onProgress(_bulkDownloadProgress);
              notifyListeners();
            }).catchError((e) {
              debugPrint("Bulk download failed for ayah $ayah: $e");
              if (file.existsSync()) file.deleteSync();
            }),
          );
        }

        await Future.wait(downloadFutures);
      }

      _isBulkDownloading = false;
      _bulkDownloadQari = null;
      notifyListeners();

      if (_cancelBulkDownload) {
        onError('تم إلغاء عملية التحميل.');
      } else {
        final finalCount = await getDownloadedAyahsCount(qari);
        if (finalCount >= 6230) {
          onCompleted();
        } else {
          onError('فشل تحميل بعض الآيات. يرجى المحاولة مرة أخرى.');
        }
      }
    } catch (e) {
      _isBulkDownloading = false;
      _bulkDownloadQari = null;
      notifyListeners();
      onError('حدث خطأ أثناء تحميل الصوتيات: $e');
    }
  }

  Future<void> deleteAudioForQari(String qari) async {
    if (kIsWeb) return;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDir.path}/quran_audio/$qari');
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to delete audio directory for $qari: $e");
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      _webPlayer?.dispose();
    } else {
      _player?.dispose();
    }
    super.dispose();
  }
}
