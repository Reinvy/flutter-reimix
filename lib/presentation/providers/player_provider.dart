import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exceptions.dart';
import '../../data/datasources/audio/audio_handler.dart';
import '../../data/repositories_impl/stats_repository_impl.dart';
import '../../domain/entities/song.dart';
import '../../main.dart' show audioHandler, objectBox;
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
    bool clearSleepTimer = false,
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
  Timer? _sleepTimer;

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

      state = state.copyWith(
        currentSong: _handler.currentSong,
        queue: handlerQueue ?? state.queue,
      );
    });
  }

  void _checkListenThreshold(Duration position) {
    final song = state.currentSong;
    if (song == null || song.durationMs <= 0) return;
    if (_recordedSongs.contains(song.id)) return;
    final pct = position.inMilliseconds / song.durationMs;
    if (pct >= 0.8) {
      _recordedSongs.add(song.id);
      StatsRepositoryImpl(
        objectBox,
      ).recordListen(songId: song.id, durationMs: (song.durationMs * 0.8).round());
    }
  }

  @override
  void dispose() {
    _positionSub.cancel();
    _playingSub.cancel();
    _playbackSub.cancel();
    _mediaItemSub.cancel();
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

  void startSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    state = state.copyWith(sleepTimeLeft: duration);
    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final left = state.sleepTimeLeft;
      if (left == null || left.inSeconds <= 1) {
        timer.cancel();
        _sleepTimer = null;
        state = state.copyWith(clearSleepTimer: true);
        pause();
      } else {
        state = state.copyWith(sleepTimeLeft: left - const Duration(seconds: 1));
      }
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
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
