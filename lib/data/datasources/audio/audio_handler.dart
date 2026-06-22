import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../../domain/entities/song.dart';

/// Background-capable audio handler.
///
/// Extends [BaseAudioHandler] (audio_service) and delegates playback to a
/// [just_audio] [AudioPlayer].  Manages the current queue, exposes position
/// and playing-state streams, and keeps the OS media session in sync.
class ReimixAudioHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer(
    userAgent:
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    useProxyForRequestHeaders: false,
  );
  final _errorController = StreamController<AudioException>.broadcast();

  List<Song> _queue = [];
  int _currentIndex = 0;

  ReimixAudioHandler() {
    // Forward just_audio events → audio_service playbackState
    _player.playbackEventStream.listen(
      _broadcastState,
      onError: (Object e, StackTrace st) {
        _errorController.add(
          AudioException('Playback error — file may be missing or corrupt.', cause: e),
        );
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

  Future<Uri> _resolveAudioUri(String filePath) async {
    if (filePath.startsWith('youtube://')) {
      final videoId = filePath.replaceFirst('youtube://', '');
      final yt = YoutubeExplode();
      try {
        final manifest = await yt.videos.streams.getManifest(
          videoId,
          ytClients: [
            YoutubeApiClient.androidVr,
            YoutubeApiClient.safari,
            YoutubeApiClient.android,
            YoutubeApiClient.ios,
          ],
        );
        final audioStream = manifest.audioOnly.withHighestBitrate();
        return audioStream.url;
      } catch (e) {
        throw AudioException('Failed to resolve YouTube audio stream for $videoId', cause: e);
      } finally {
        yt.close();
      }
    }
    return Uri.parse(filePath);
  }

  Future<AudioSource> _createAudioSource(Song song) async {
    final resolvedUri = await _resolveAudioUri(song.filePath);
    final isYoutube = song.filePath.startsWith('youtube://');
    if (isYoutube) {
      return AudioSource.uri(
        resolvedUri,
        headers: const {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': '*/*',
          'Accept-Encoding': 'gzip, deflate, br',
          'Connection': 'keep-alive',
          'Origin': 'https://www.youtube.com',
          'Referer': 'https://www.youtube.com/',
        },
      );
    }
    return AudioSource.uri(resolvedUri);
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Starts playback of [song], optionally replacing the entire [queue].
  Future<void> playFromSong(Song song, {List<Song>? queue, int queueIndex = 0}) async {
    _queue = queue ?? [song];
    _currentIndex = queueIndex;
    mediaItem.add(song.toMediaItem());
    try {
      final source = await _createAudioSource(song);
      await _player.setAudioSource(source);
      await _player.play();
    } catch (e) {
      _errorController.add(
        AudioException(
          'Cannot play "${song.title}" — file may have been moved or deleted.',
          cause: e,
        ),
      );
    }
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
      try {
        final source = await _createAudioSource(song);
        await _player.setAudioSource(source);
        await _player.play();
      } catch (e) {
        _errorController.add(
          AudioException('Cannot play "${song.title}" — stream error.', cause: e),
        );
      }
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
      try {
        final source = await _createAudioSource(song);
        await _player.setAudioSource(source);
        await _player.play();
      } catch (e) {
        _errorController.add(
          AudioException('Cannot play "${song.title}" — stream error.', cause: e),
        );
      }
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

  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
    await super.setSpeed(speed);
  }

  Future<void> removeQueueItemAt(int index) async {
    if (index < 0 || index >= _queue.length) return;
    if (_queue.length == 1) {
      await stop();
      return;
    }

    final currentPlayingRemoved = (index == _currentIndex);
    _queue.removeAt(index);

    if (currentPlayingRemoved) {
      if (_currentIndex >= _queue.length) {
        _currentIndex = _queue.length - 1;
      }
      final song = _queue[_currentIndex];
      mediaItem.add(song.toMediaItem());
      try {
        final source = await _createAudioSource(song);
        await _player.setAudioSource(source);
        if (_player.playing) {
          await _player.play();
        }
      } catch (e) {
        _errorController.add(
          AudioException(
            'Cannot play "${song.title}" — file may have been moved or deleted.',
            cause: e,
          ),
        );
      }
    } else if (index < _currentIndex) {
      _currentIndex--;
    }
  }


  // ── Convenience streams ─────────────────────────────────────────────────────

  Song? get currentSong => _queue.isNotEmpty ? _queue[_currentIndex] : null;

  List<Song> get currentQueue => List.unmodifiable(_queue);

  Stream<Duration> get positionStream => _player.positionStream;

  Stream<bool> get playingStream => _player.playingStream;

  Stream<Duration?> get durationStream => _player.durationStream;

  /// Stream of audio errors (file not found, codec failures, etc.)
  Stream<AudioException> get audioErrors => _errorController.stream;
}

// ── Extension ─────────────────────────────────────────────────────────────────

extension SongToMediaItem on Song {
  MediaItem toMediaItem() => MediaItem(
    id: filePath,
    title: title,
    artist: artist,
    album: album,
    duration: Duration(milliseconds: durationMs),
    artUri: albumArtPath != null
        ? (albumArtPath!.startsWith('http') ? Uri.parse(albumArtPath!) : Uri.file(albumArtPath!))
        : null,
  );
}
