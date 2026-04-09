import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/audio/audio_handler.dart';
import '../../domain/entities/song.dart';
import '../../main.dart' show audioHandler;

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

  const PlayerState({
    this.currentSong,
    this.queue = const [],
    this.position = Duration.zero,
    this.isPlaying = false,
    this.isLoading = false,
    this.shuffleMode = ShuffleMode.off,
    this.repeatMode = RepeatMode.off,
    this.volume = 1.0,
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
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

/// Bridges [ReimixAudioHandler] streams with Riverpod state.
class PlayerNotifier extends StateNotifier<PlayerState> {
  final ReimixAudioHandler _handler;
  late final StreamSubscription<Duration> _positionSub;
  late final StreamSubscription<bool> _playingSub;
  late final StreamSubscription<PlaybackState> _playbackSub;

  PlayerNotifier(this._handler) : super(const PlayerState()) {
    _positionSub = _handler.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
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
      );
    });
  }

  @override
  void dispose() {
    _positionSub.cancel();
    _playingSub.cancel();
    _playbackSub.cancel();
    super.dispose();
  }

  // ── Playback controls ───────────────────────────────────────────────────────

  Future<void> play(Song song, {List<Song>? queue, int index = 0}) async {
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
}

// ── Provider ──────────────────────────────────────────────────────────────────

final audioHandlerProvider = Provider<ReimixAudioHandler>((_) => audioHandler);

final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  return PlayerNotifier(ref.read(audioHandlerProvider));
});
