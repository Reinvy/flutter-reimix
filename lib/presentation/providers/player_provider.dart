import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exceptions.dart';
import '../../data/datasources/audio/audio_handler.dart';
import '../../domain/entities/song.dart';
import '../../main.dart' show audioHandler;
import 'library_provider.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

enum RepeatMode { off, one, all }

enum ShuffleMode { off, on }

// ── Value class ───────────────────────────────────────────────────────────────

class PlayerState {
  final Song? currentSong;
  final List<Song> queue;
  final Duration position;
  final bool isPlaying;
  final bool isLoading;
  final ShuffleMode shuffleMode;
  final RepeatMode repeatMode;
  final double volume;
  final double speed;
  final Duration? sleepTimeLeft;
  final bool sleepAtEndOfSong;
  final int? currentBitrate;

  const PlayerState({
    this.currentSong,
    this.queue = const [],
    this.position = Duration.zero,
    this.isPlaying = false,
    this.isLoading = false,
    this.shuffleMode = ShuffleMode.off,
    this.repeatMode = RepeatMode.off,
    this.volume = 1.0,
    this.speed = 1.0,
    this.sleepTimeLeft,
    this.sleepAtEndOfSong = false,
    this.currentBitrate,
  });

  PlayerState copyWith({
    Song? currentSong,
    List<Song>? queue,
    Duration? position,
    bool? isPlaying,
    bool? isLoading,
    ShuffleMode? shuffleMode,
    RepeatMode? repeatMode,
    double? volume,
    double? speed,
    Duration? sleepTimeLeft,
    bool? sleepAtEndOfSong,
    int? currentBitrate,
    bool clearSleepTimer = false,
    bool clearBitrate = false,
  }) {
    return PlayerState(
      currentSong: currentSong ?? this.currentSong,
      queue: queue ?? this.queue,
      position: position ?? this.position,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      shuffleMode: shuffleMode ?? this.shuffleMode,
      repeatMode: repeatMode ?? this.repeatMode,
      volume: volume ?? this.volume,
      speed: speed ?? this.speed,
      sleepTimeLeft: clearSleepTimer ? null : (sleepTimeLeft ?? this.sleepTimeLeft),
      sleepAtEndOfSong: clearSleepTimer ? false : (sleepAtEndOfSong ?? this.sleepAtEndOfSong),
      currentBitrate: clearBitrate ? null : (currentBitrate ?? this.currentBitrate),
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

/// Bridges [ReimixAudioHandler] streams with Riverpod state.
class PlayerNotifier extends StateNotifier<PlayerState> {
  final ReimixAudioHandler _handler;
  final Ref _ref;
  late final StreamSubscription<Duration> _positionSub;
  late final StreamSubscription<bool> _playingSub;
  late final StreamSubscription<PlaybackState> _playbackSub;
  late final StreamSubscription<MediaItem?> _mediaItemSub;
  late final StreamSubscription<List<int>?> _shuffleSub;
  Timer? _sleepTimer;
  double? _originalVolume;

  /// Guards against recording the same song multiple times per queue session.
  final _recordedSongs = <int>{};

  PlayerNotifier(this._handler, this._ref) : super(const PlayerState()) {
    _positionSub = _handler.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
      _checkListenThreshold(pos);
    });

    _playingSub = _handler.playingStream.listen((playing) {
      state = state.copyWith(isPlaying: playing);
    });
    _playbackSub = _handler.playbackState.listen((pb) {
      final loading =
          pb.processingState == AudioProcessingState.loading ||
          pb.processingState == AudioProcessingState.buffering;
      state = state.copyWith(
        isPlaying: pb.playing,
        isLoading: loading,
        position: pb.updatePosition,
        speed: pb.speed,
        currentBitrate: _handler.currentBitrate,
      );
    });

    _mediaItemSub = _handler.mediaItem.listen((item) {
      List<Song>? handlerQueue;
      try {
        final dynamic q = _handler.currentQueue;
        if (q is List<Song>) {
          handlerQueue = q;
        }
      } catch (_) {}

      final nextSong = _handler.currentSong;
      final prevSong = state.currentSong;

      state = state.copyWith(
        currentSong: nextSong,
        queue: handlerQueue ?? state.queue,
        currentBitrate: _handler.currentBitrate,
      );

      // End of song sleep timer trigger
      if (state.sleepAtEndOfSong && prevSong != null && nextSong != null && prevSong.id != nextSong.id) {
        _sleepTimerExpired();
      }
    });

    // Sync queue whenever shuffle order changes
    _shuffleSub = _handler.shuffleIndicesStream.listen((_) {
      state = state.copyWith(queue: _handler.currentQueue);
    });
  }

  void _checkListenThreshold(Duration position) {
    final song = state.currentSong;
    if (song == null || song.durationMs <= 0) return;
    if (_recordedSongs.contains(song.id)) return;
    final pct = position.inMilliseconds / song.durationMs;
    if (pct >= 0.8) {
      _recordedSongs.add(song.id);
      // Use the injected stats repository via Ref instead of direct instantiation
      _ref.read(statsRepositoryProvider).recordListen(
        songId: song.id,
        durationMs: (song.durationMs * 0.8).round(),
      );
    }
  }

  @override
  void dispose() {
    _positionSub.cancel();
    _playingSub.cancel();
    _playbackSub.cancel();
    _mediaItemSub.cancel();
    _shuffleSub.cancel();
    _sleepTimer?.cancel();
    super.dispose();
  }

  // ── Playback controls ───────────────────────────────────────────────────────

  Future<void> play(Song song, {List<Song>? queue, int index = 0}) async {
    // Clear guard when starting a new queue
    _recordedSongs.clear();
    final effectiveQueue = queue ?? [song];
    state = state.copyWith(currentSong: song, queue: effectiveQueue, isLoading: true);
    await _handler.playFromSong(song, queue: effectiveQueue, queueIndex: index);
  }

  Future<void> resume() => _handler.play();

  Future<void> pause() => _handler.pause();

  Future<void> stop() async {
    await _handler.stop();
    state = const PlayerState();
  }

  Future<void> seek(Duration position) => _handler.seek(position);

  Future<void> skipToNext() async {
    await _handler.skipToNext();
    state = state.copyWith(currentSong: _handler.currentSong);
  }

  Future<void> skipToPrevious() async {
    await _handler.skipToPrevious();
    state = state.copyWith(currentSong: _handler.currentSong);
  }

  // ── Mode toggles ────────────────────────────────────────────────────────────

  Future<void> toggleShuffle() async {
    final next = state.shuffleMode == ShuffleMode.off ? ShuffleMode.on : ShuffleMode.off;
    await _handler.setShuffleMode(
      next == ShuffleMode.on ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
    );
    state = state.copyWith(shuffleMode: next);
  }

  Future<void> cycleRepeatMode() async {
    final next = switch (state.repeatMode) {
      RepeatMode.off => RepeatMode.all,
      RepeatMode.all => RepeatMode.one,
      RepeatMode.one => RepeatMode.off,
    };
    await _handler.setRepeatMode(
      {
        RepeatMode.off: AudioServiceRepeatMode.none,
        RepeatMode.all: AudioServiceRepeatMode.all,
        RepeatMode.one: AudioServiceRepeatMode.one,
      }[next]!,
    );
    state = state.copyWith(repeatMode: next);
  }

  // ── Volume & Speed ──────────────────────────────────────────────────────────

  Future<void> setVolume(double volume) async {
    await _handler.setVolume(volume);
    state = state.copyWith(volume: volume);
  }

  Future<void> setSpeed(double speed) async {
    await _handler.setSpeed(speed);
    state = state.copyWith(speed: speed);
  }

  // ── Queue Management ────────────────────────────────────────────────────────

  Future<void> removeFromQueue(int index) async {
    await _handler.removeQueueItemAt(index);
    state = state.copyWith(
      currentSong: _handler.currentSong,
      queue: _handler.currentQueue,
    );
  }

  // ── Sleep Timer ────────────────────────────────────────────────────────────

  void _sleepTimerExpired() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    if (_originalVolume != null) {
      setVolume(_originalVolume!);
      _originalVolume = null;
    }
    pause();
    state = state.copyWith(sleepTimeLeft: Duration.zero);
    Future.delayed(const Duration(milliseconds: 100), () {
      state = state.copyWith(clearSleepTimer: true);
    });
  }

  void startSleepTimer(Duration duration, {bool endOfSong = false}) {
    _sleepTimer?.cancel();
    if (_originalVolume != null) {
      setVolume(_originalVolume!);
      _originalVolume = null;
    }

    if (endOfSong) {
      state = state.copyWith(clearSleepTimer: true, sleepAtEndOfSong: true);
      return;
    }

    _originalVolume = state.volume;
    state = state.copyWith(sleepTimeLeft: duration, sleepAtEndOfSong: false);
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final left = state.sleepTimeLeft;
      if (left == null || left.inSeconds <= 1) {
        _sleepTimerExpired();
      } else {
        final newLeft = left - const Duration(seconds: 1);
        state = state.copyWith(sleepTimeLeft: newLeft);
        if (newLeft.inSeconds <= 10) {
          final factor = newLeft.inSeconds / 10.0;
          final fadeVolume = (_originalVolume ?? state.volume) * factor;
          _handler.setVolume(fadeVolume);
        }
      }
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    if (_originalVolume != null) {
      setVolume(_originalVolume!);
      _originalVolume = null;
    }
    state = state.copyWith(clearSleepTimer: true);
  }

  // ── Favorite Toggle ────────────────────────────────────────────────────────

  Future<void> toggleFavorite(Song song) async {
    final updated = await _ref.read(songRepositoryProvider).toggleFavorite(song.id);
    state = state.copyWith(
      currentSong: state.currentSong?.id == song.id ? updated : state.currentSong,
      queue: state.queue.map((s) => s.id == song.id ? updated : s).toList(),
    );
    _ref.invalidate(libraryProvider);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final audioHandlerProvider = Provider<ReimixAudioHandler>((_) => audioHandler);

final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  return PlayerNotifier(ref.read(audioHandlerProvider), ref);
});

/// Stream of audio playback errors from [ReimixAudioHandler].
/// Consumed by the shell to show snackbars and skip broken tracks.
final audioErrorStreamProvider = StreamProvider<AudioException>((ref) {
  return ref.read(audioHandlerProvider).audioErrors;
});
