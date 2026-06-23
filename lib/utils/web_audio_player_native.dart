import 'dart:async';
import 'package:audioplayers/audioplayers.dart' as ap;

class WebAudioPlayer {
  final String id;
  void Function(String state)? onStateChanged;
  void Function(double durationSeconds)? onDurationChanged;
  void Function(double positionSeconds)? onPositionChanged;
  void Function()? onComplete;

  late final ap.AudioPlayer _player;
  StreamSubscription? _stateSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _positionSub;

  WebAudioPlayer(this.id) {
    _player = ap.AudioPlayer();
    _setupListeners();
  }

  void _setupListeners() {
    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (onStateChanged != null) {
        if (state == ap.PlayerState.playing) {
          onStateChanged!('playing');
        } else if (state == ap.PlayerState.paused) {
          onStateChanged!('paused');
        } else if (state == ap.PlayerState.completed) {
          onStateChanged!('completed');
          if (onComplete != null) onComplete!();
        } else {
          onStateChanged!('stopped');
        }
      }
    });

    _durationSub = _player.onDurationChanged.listen((dur) {
      if (onDurationChanged != null) {
        onDurationChanged!(dur.inMilliseconds / 1000.0);
      }
    });

    _positionSub = _player.onPositionChanged.listen((pos) {
      if (onPositionChanged != null) {
        onPositionChanged!(pos.inMilliseconds / 1000.0);
      }
    });
  }

  void play(String url, {double playbackRate = 1.0}) async {
    try {
      await _player.setPlaybackRate(playbackRate);
      await _player.play(ap.UrlSource(url));
    } catch (_) {}
  }

  void pause() async {
    try {
      await _player.pause();
    } catch (_) {}
  }

  void seek(double seconds) async {
    try {
      await _player.seek(Duration(milliseconds: (seconds * 1000).round()));
    } catch (_) {}
  }

  void setPlaybackRate(double rate) async {
    try {
      await _player.setPlaybackRate(rate);
    } catch (_) {}
  }

  void dispose() async {
    try {
      await _stateSub?.cancel();
      await _durationSub?.cancel();
      await _positionSub?.cancel();
      await _player.dispose();
    } catch (_) {}
  }
}
