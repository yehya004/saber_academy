// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

class WebAudioPlayer {
  final String id;
  void Function(String state)? onStateChanged;
  void Function(double durationSeconds)? onDurationChanged;
  void Function(double positionSeconds)? onPositionChanged;
  void Function()? onComplete;

  WebAudioPlayer(this.id) {
    _injectJS();
    _setupListeners();
  }

  void _injectJS() {
    if (js.context['createSaberAudioPlayer'] == null) {
      js.context.callMethod('eval', [
        """
        window.SaberAudioPlayers = {};
        window.createSaberAudioPlayer = function(id) {
          console.log('[SaberAudio] Creating native HTML5 player for ID:', id);
          var audio = new Audio();
          audio.preload = 'auto';
          window.SaberAudioPlayers[id] = audio;
          
          audio.onplay = function() { 
            console.log('[SaberAudio] onplay event for ID:', id);
            if (typeof window['onStateChanged_' + id] === 'function') window['onStateChanged_' + id]('playing'); 
          };
          audio.onpause = function() { 
            console.log('[SaberAudio] onpause event for ID:', id);
            if (typeof window['onStateChanged_' + id] === 'function') window['onStateChanged_' + id]('paused'); 
          };
          audio.onended = function() { 
            console.log('[SaberAudio] onended event for ID:', id);
            if (typeof window['onStateChanged_' + id] === 'function') window['onStateChanged_' + id]('completed'); 
            if (typeof window['onComplete_' + id] === 'function') window['onComplete_' + id]();
          };
          audio.ondurationchange = function() { 
            console.log('[SaberAudio] ondurationchange event for ID:', id, 'duration:', audio.duration);
            if (typeof window['onDurationChanged_' + id] === 'function') window['onDurationChanged_' + id](audio.duration); 
          };
          audio.ontimeupdate = function() { 
            if (typeof window['onPositionChanged_' + id] === 'function') window['onPositionChanged_' + id](audio.currentTime); 
          };
          audio.onerror = function() {
            var err = audio.error;
            var msg = 'Unknown media error';
            if (err) {
              switch (err.code) {
                case 1: msg = 'MEDIA_ERR_ABORTED (Playback aborted by user)'; break;
                case 2: msg = 'MEDIA_ERR_NETWORK (Network error occurred)'; break;
                case 3: msg = 'MEDIA_ERR_DECODE (Media decoding failed)'; break;
                case 4: msg = 'MEDIA_ERR_SRC_NOT_SUPPORTED (Format or URL not supported)'; break;
              }
            }
            console.error('[SaberAudio] Native MediaError for:', id, 'code:', err ? err.code : 'none', 'message:', msg, 'details:', err ? err.message : '');
          };
          return audio;
        };
        window.playSaberAudio = function(id, url, rate) {
          console.log('[SaberAudio] playSaberAudio triggered for ID:', id, 'url:', url, 'rate:', rate);
          var audio = window.SaberAudioPlayers[id];
          if (!audio) {
            audio = window.createSaberAudioPlayer(id);
          }
          
          var absoluteUrl = url;
          if (url.indexOf('http') !== 0 && url.indexOf('data:') !== 0) {
            absoluteUrl = window.location.origin + '/' + url;
          }
          
          if (audio.src !== absoluteUrl) {
            console.log('[SaberAudio] updating source from:', audio.src, 'to:', absoluteUrl);
            audio.src = absoluteUrl;
            audio.load();
          }
          
          audio.playbackRate = rate || 1.0;
          
          var playPromise = audio.play();
          if (playPromise !== undefined) {
            playPromise.then(function() {
              console.log('[SaberAudio] play() Promise succeeded for:', id);
            }).catch(function(err) {
              console.error('[SaberAudio] play() Promise rejected for:', id, 'error:', err);
            });
          }
        };
        window.pauseSaberAudio = function(id) {
          console.log('[SaberAudio] pauseSaberAudio triggered for ID:', id);
          var audio = window.SaberAudioPlayers[id];
          if (audio) {
            audio.pause();
          }
        };
        window.seekSaberAudio = function(id, seconds) {
          console.log('[SaberAudio] seekSaberAudio triggered for ID:', id, 'seconds:', seconds);
          var audio = window.SaberAudioPlayers[id];
          if (audio) {
            audio.currentTime = seconds;
          }
        };
        window.setRateSaberAudio = function(id, rate) {
          console.log('[SaberAudio] setRateSaberAudio triggered for ID:', id, 'rate:', rate);
          var audio = window.SaberAudioPlayers[id];
          if (audio) {
            audio.playbackRate = rate;
          }
        };
        window.disposeSaberAudio = function(id) {
          console.log('[SaberAudio] disposeSaberAudio triggered for ID:', id);
          var audio = window.SaberAudioPlayers[id];
          if (audio) {
            audio.pause();
            audio.src = '';
            delete window.SaberAudioPlayers[id];
          }
        };
        window.setupSaberAudioListeners = function(id, stateCb, durCb, posCb, compCb) {
          console.log('[SaberAudio] setting up listeners mapping for ID:', id);
          // Handled via dynamically injected callbacks
        };
        """
      ]);
    }
  }

  void _setupListeners() {
    final stateCbName = 'onStateChanged_$id';
    final durCbName = 'onDurationChanged_$id';
    final posCbName = 'onPositionChanged_$id';
    final compCbName = 'onComplete_$id';

    js.context[stateCbName] = (dynamic state) {
      if (onStateChanged != null) onStateChanged!(state as String);
    };
    js.context[durCbName] = (dynamic dur) {
      if (onDurationChanged != null) {
        onDurationChanged!(dur != null ? (dur as num).toDouble() : 0.0);
      }
    };
    js.context[posCbName] = (dynamic pos) {
      if (onPositionChanged != null) {
        onPositionChanged!(pos != null ? (pos as num).toDouble() : 0.0);
      }
    };
    js.context[compCbName] = () {
      if (onComplete != null) onComplete!();
    };

    js.context.callMethod('setupSaberAudioListeners', [
      id,
      stateCbName,
      durCbName,
      posCbName,
      compCbName,
    ]);
  }

  void play(String url, {double playbackRate = 1.0}) {
    js.context.callMethod('playSaberAudio', [id, url, playbackRate]);
  }

  void pause() {
    js.context.callMethod('pauseSaberAudio', [id]);
  }

  void seek(double seconds) {
    js.context.callMethod('seekSaberAudio', [id, seconds]);
  }

  void setPlaybackRate(double rate) {
    js.context.callMethod('setRateSaberAudio', [id, rate]);
  }

  void dispose() {
    js.context.callMethod('disposeSaberAudio', [id]);
    js.context.callMethod('eval', [
      'delete window["onStateChanged_$id"]; delete window["onDurationChanged_$id"]; delete window["onPositionChanged_$id"]; delete window["onComplete_$id"];'
    ]);
  }
}
