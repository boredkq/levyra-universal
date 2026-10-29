import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/models/unified_track.dart';
import '../core/models/audio_stream_descriptor.dart';
import '../core/models/synced_lyrics.dart';
import '../core/models/sponsorblock_segment.dart';
import '../sources/music_provider.dart';
import 'stream_cache_proxy.dart';
import 'dsp_processor.dart';
import 'sponsorblock_controller.dart';

enum PlaybackState {
  idle,
  buffering,
  playing,
  paused,
  error,
}

enum PlaybackRepeatMode {
  off,
  all,
  one,
}

class PlaybackController extends ChangeNotifier {
  final MusicProvider musicProvider;
  final StreamCacheProxy cacheProxy;
  final SponsorBlockController sponsorBlockController;

  DspProcessorSettings dspSettings = const DspProcessorSettings();

  PlaybackState _state = PlaybackState.idle;
  PlaybackState get state => _state;

  UnifiedTrack? _currentTrack;
  UnifiedTrack? get currentTrack => _currentTrack;

  AudioStreamDescriptor? _currentStream;
  AudioStreamDescriptor? get currentStream => _currentStream;

  String? _currentVideoStreamUrl;
  String? get currentVideoStreamUrl => _currentVideoStreamUrl;

  List<UnifiedTrack> _queue = [];
  List<UnifiedTrack> get queue => List.unmodifiable(_queue);

  int _queueIndex = -1;
  int get queueIndex => _queueIndex;

  Duration _position = Duration.zero;
  Duration get position => _position;

  Duration _duration = Duration.zero;
  Duration get duration => _duration;

  double _volume = 1.0;
  double get volume => _volume;

  double _effectiveVolume = 1.0;
  double get effectiveVolume => _effectiveVolume;

  bool _isShuffleEnabled = false;
  bool get isShuffleEnabled => _isShuffleEnabled;

  PlaybackRepeatMode _repeatMode = PlaybackRepeatMode.off;
  PlaybackRepeatMode get repeatMode => _repeatMode;

  bool _isVideoMode = false;
  bool get isVideoMode => _isVideoMode;

  List<SponsorBlockSegment> _currentSegments = [];
  List<SponsorBlockSegment> get currentSegments => _currentSegments;

  SyncedLyrics? _currentLyrics;
  SyncedLyrics? get currentLyrics => _currentLyrics;

  Timer? _positionTicker;

  PlaybackController({
    required this.musicProvider,
    required this.cacheProxy,
    SponsorBlockController? sponsorBlock,
  }) : sponsorBlockController = sponsorBlock ?? SponsorBlockController();

  Future<void> initialize() async {
    await cacheProxy.start();
  }

  Future<void> playTrack(UnifiedTrack track, {List<UnifiedTrack>? newQueue}) async {
    _state = PlaybackState.buffering;
    _currentTrack = track;
    _position = Duration.zero;
    _duration = Duration(milliseconds: track.durationMs);
    notifyListeners();

    if (newQueue != null && newQueue.isNotEmpty) {
      _queue = List.from(newQueue);
      _queueIndex = _queue.indexWhere((t) => t.id == track.id);
      if (_queueIndex == -1) {
        _queue.insert(0, track);
        _queueIndex = 0;
      }
    }

    try {
      // 1. Resolve Audio Stream Descriptor
      final streamDescriptor = await musicProvider.getStreamDescriptor(track.id);
      _currentStream = streamDescriptor;

      // 2. Wrap through local chunked proxy cacher if HTTP URL
      final effectivePlayUrl = streamDescriptor.streamUrl.startsWith('http')
          ? cacheProxy.getProxiedUrl(streamDescriptor.streamUrl, track.id)
          : streamDescriptor.streamUrl;

      // 3. Apply ReplayGain loudness normalization
      final replayGainMultiplier = dspSettings.calculateReplayGainMultiplier(track.replayGainDb ?? 0.0);
      _effectiveVolume = (_volume * replayGainMultiplier).clamp(0.0, 1.5);

      // 4. Fetch SponsorBlock segments if videoId / sourceId exists
      final vid = track.videoId ?? (track.source == TrackSource.youtubeMusic ? track.sourceId : null);
      if (vid != null) {
        _currentSegments = await sponsorBlockController.getSegments(vid);
      } else {
        _currentSegments = [];
      }

      // 5. Fetch Synced Lyrics
      _currentLyrics = await musicProvider.getLyrics(track.id);

      // 6. Preload video stream URL for seamless [Песня | Клип] mode
      if (vid != null) {
        _currentVideoStreamUrl = await musicProvider.getVideoStreamUrl(vid);
      } else {
        _currentVideoStreamUrl = null;
      }

      _state = PlaybackState.playing;
      _startPositionTicker();
      notifyListeners();
    } catch (e) {
      _state = PlaybackState.error;
      notifyListeners();
    }
  }

  void togglePlayPause() {
    if (_state == PlaybackState.playing) {
      _state = PlaybackState.paused;
      _stopPositionTicker();
    } else if (_state == PlaybackState.paused) {
      _state = PlaybackState.playing;
      _startPositionTicker();
    }
    notifyListeners();
  }

  void seek(Duration newPosition) {
    _position = newPosition;
    _checkSponsorBlockSkip();
    notifyListeners();
  }

  void skipNext() {
    if (_queue.isEmpty) return;

    if (_repeatMode == PlaybackRepeatMode.one && _currentTrack != null) {
      playTrack(_currentTrack!);
      return;
    }

    if (_queueIndex + 1 < _queue.length) {
      _queueIndex++;
      playTrack(_queue[_queueIndex]);
    } else if (_repeatMode == PlaybackRepeatMode.all) {
      _queueIndex = 0;
      playTrack(_queue[_queueIndex]);
    }
  }

  void skipPrevious() {
    if (_position.inSeconds > 3) {
      seek(Duration.zero);
      return;
    }

    if (_queueIndex > 0) {
      _queueIndex--;
      playTrack(_queue[_queueIndex]);
    } else {
      seek(Duration.zero);
    }
  }

  void setVolume(double newVolume) {
    _volume = newVolume.clamp(0.0, 1.0);
    final replayGainMultiplier = dspSettings.calculateReplayGainMultiplier(_currentTrack?.replayGainDb ?? 0.0);
    _effectiveVolume = (_volume * replayGainMultiplier).clamp(0.0, 1.5);
    notifyListeners();
  }

  void setVideoMode(bool enabled) {
    if (_isVideoMode == enabled) return;
    _isVideoMode = enabled;
    // Seamless timestamp sync remains preserved via _position
    notifyListeners();
  }

  void cycleRepeatMode() {
    switch (_repeatMode) {
      case PlaybackRepeatMode.off:
        _repeatMode = PlaybackRepeatMode.all;
        break;
      case PlaybackRepeatMode.all:
        _repeatMode = PlaybackRepeatMode.one;
        break;
      case PlaybackRepeatMode.one:
        _repeatMode = PlaybackRepeatMode.off;
        break;
    }
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffleEnabled = !_isShuffleEnabled;
    if (_isShuffleEnabled && _queue.isNotEmpty) {
      final current = _currentTrack;
      _queue.shuffle();
      if (current != null) {
        _queue.remove(current);
        _queue.insert(0, current);
        _queueIndex = 0;
      }
    }
    notifyListeners();
  }

  void updateDspSettings(DspProcessorSettings newSettings) {
    dspSettings = newSettings;
    final replayGainMultiplier = dspSettings.calculateReplayGainMultiplier(_currentTrack?.replayGainDb ?? 0.0);
    _effectiveVolume = (_volume * replayGainMultiplier).clamp(0.0, 1.5);
    notifyListeners();
  }

  void _startPositionTicker() {
    _positionTicker?.cancel();
    _positionTicker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (_state == PlaybackState.playing) {
        _position += const Duration(milliseconds: 250);
        _checkSponsorBlockSkip();

        if (_duration > Duration.zero && _position >= _duration) {
          skipNext();
        } else {
          notifyListeners();
        }
      }
    });
  }

  void _stopPositionTicker() {
    _positionTicker?.cancel();
    _positionTicker = null;
  }

  void _checkSponsorBlockSkip() {
    final vid = _currentTrack?.videoId ?? (_currentTrack?.source == TrackSource.youtubeMusic ? _currentTrack?.sourceId : null);
    if (vid == null) return;

    final skipTargetMs = sponsorBlockController.checkSkipTarget(vid, _position.inMilliseconds);
    if (skipTargetMs != null) {
      // Seamlessly jump past non-music segment!
      _position = Duration(milliseconds: skipTargetMs);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _stopPositionTicker();
    cacheProxy.stop();
    super.dispose();
  }
}