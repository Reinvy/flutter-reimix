import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../../../domain/entities/song.dart';

/// Background-capable audio handler.
///
/// Extends [BaseAudioHandler] (audio_service) and delegates playback to a
/// [just_audio] [AudioPlayer].  Manages the current queue, exposes position
/// and playing-state streams, and keeps the OS media session in sync.
class ReimixAudioHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer();

  List<Song> _queue = [];
  int _currentIndex = 0;

  ReimixAudioHandler() {
    // Forward just_audio events → audio_service playbackState
    _player.playbackEventStream.listen(
      _broadcastState,
      onError: (Object e, StackTrace st) {
        // Swallow playback errors so the handler keeps running
      },
    );

    // Auto-advance on track completion
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        skipToNext();
      }
    });
  }

  // ── Internal helpers ────────────────────────────────────────────────────────

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek, MediaAction.seekForward, MediaAction.seekBackward},
        androidCompactActionIndices: const [0, 1, 3],
        processingState: {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _currentIndex,
      ),
    );
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Starts playback of [song], optionally replacing the entire [queue].
  Future<void> playFromSong(Song song, {List<Song>? queue, int queueIndex = 0}) async {
    _queue = queue ?? [song];
    _currentIndex = queueIndex;
    mediaItem.add(song.toMediaItem());
    await _player.setAudioSource(AudioSource.uri(Uri.parse(song.filePath)));
    await _player.play();
  }

  // ── BaseAudioHandler overrides ───────────────────────────────────────────────

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
      final song = _queue[_currentIndex];
      mediaItem.add(song.toMediaItem());
      await _player.setAudioSource(AudioSource.uri(Uri.parse(song.filePath)));
      await _player.play();
    } else {
      // End of queue — stop
      await stop();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    // If more than 3 s in, seek to start; otherwise go to previous track
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else if (_currentIndex > 0) {
      _currentIndex--;
      final song = _queue[_currentIndex];
      mediaItem.add(song.toMediaItem());
      await _player.setAudioSource(AudioSource.uri(Uri.parse(song.filePath)));
      await _player.play();
    } else {
      await _player.seek(Duration.zero);
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode != AudioServiceShuffleMode.none;
    await _player.setShuffleModeEnabled(enabled);
    await super.setShuffleMode(shuffleMode);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    await _player.setLoopMode(
      {
        AudioServiceRepeatMode.none: LoopMode.off,
        AudioServiceRepeatMode.one: LoopMode.one,
        AudioServiceRepeatMode.all: LoopMode.all,
        AudioServiceRepeatMode.group: LoopMode.all,
      }[repeatMode]!,
    );
    await super.setRepeatMode(repeatMode);
  }

  // ── Convenience streams ─────────────────────────────────────────────────────

  Song? get currentSong => _queue.isNotEmpty ? _queue[_currentIndex] : null;

  List<Song> get currentQueue => List.unmodifiable(_queue);

  Stream<Duration> get positionStream => _player.positionStream;

  Stream<bool> get playingStream => _player.playingStream;

  Stream<Duration?> get durationStream => _player.durationStream;
}

// ── Extension ─────────────────────────────────────────────────────────────────

extension SongToMediaItem on Song {
  MediaItem toMediaItem() => MediaItem(
    id: filePath,
    title: title,
    artist: artist,
    album: album,
    duration: Duration(milliseconds: durationMs),
    artUri: albumArtPath != null ? Uri.file(albumArtPath!) : null,
  );
}
