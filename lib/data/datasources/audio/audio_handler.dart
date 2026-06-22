import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../../domain/entities/song.dart';

class _YtCacheEntry {
  final Uri uri;
  final DateTime resolvedAt;
  _YtCacheEntry(this.uri, this.resolvedAt);

  bool get isExpired => DateTime.now().difference(resolvedAt).inHours >= 4;
}

/// Background-capable audio handler.
///
/// Extends [BaseAudioHandler] (audio_service) and delegates playback to a
/// [just_audio] [AudioPlayer] utilizing [ConcatenatingAudioSource] for native queue support.
class ReimixAudioHandler extends BaseAudioHandler with SeekHandler {
  final _player = AudioPlayer(
    userAgent:
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    useProxyForRequestHeaders: false,
  );
  final _errorController = StreamController<AudioException>.broadcast();
  final _ytCache = <String, _YtCacheEntry>{};

  ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(children: []);
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

    // Monitor current playing item index and update OS metadata + preload next track
    _player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _queue.length) {
        _currentIndex = index;
        final song = _queue[_currentIndex];
        mediaItem.add(song.toMediaItem());
        
        // Preload next track
        _preloadNextSong(index + 1);
      }
    });

    // Auto-advance is handled natively by just_audio because it's a playlist source.
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
      
      // Check cache first
      final cached = _ytCache[videoId];
      if (cached != null && !cached.isExpired) {
        return cached.uri;
      }

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
        final url = audioStream.url;
        
        // Cache resolved URL
        _ytCache[videoId] = _YtCacheEntry(url, DateTime.now());
        return url;
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
        tag: song.toMediaItem(),
      );
    }
    return AudioSource.uri(resolvedUri, tag: song.toMediaItem());
  }

  Future<void> _preloadNextSong(int index) async {
    if (index < 0 || index >= _queue.length) return;
    final nextSong = _queue[index];
    if (nextSong.filePath.startsWith('youtube://')) {
      try {
        final nextSource = await _createAudioSource(nextSong);
        if (_currentIndex == index - 1) {
          // Double-check index hasn't changed during async operations
          await _playlist.insert(index, nextSource);
          await _playlist.removeAt(index + 1);
        }
      } catch (_) {}
    }
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Starts playback of [song], replacing the entire [queue].
  Future<void> playFromSong(Song song, {List<Song>? queue, int queueIndex = 0}) async {
    _queue = queue ?? [song];
    _currentIndex = queueIndex;
    mediaItem.add(song.toMediaItem());

    try {
      final sources = <AudioSource>[];
      for (int i = 0; i < _queue.length; i++) {
        final s = _queue[i];
        if (i == queueIndex) {
          sources.add(await _createAudioSource(s));
        } else {
          // Pre-populate placeholders for YouTube, local source directly for gapless local
          if (s.filePath.startsWith('youtube://')) {
            sources.add(AudioSource.uri(Uri.parse('about:blank'), tag: s.toMediaItem()));
          } else {
            sources.add(AudioSource.uri(Uri.parse(s.filePath), tag: s.toMediaItem()));
          }
        }
      }

      _playlist = ConcatenatingAudioSource(children: sources);
      await _player.setAudioSource(_playlist, initialIndex: queueIndex);
      await _player.play();

      _preloadNextSong(queueIndex + 1);
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
    if (_player.hasNext) {
      await _player.seekToNext();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else if (_player.hasPrevious) {
      await _player.seekToPrevious();
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

  @override
  Future<void> removeQueueItemAt(int index) async {
    if (index < 0 || index >= _queue.length) return;
    if (_queue.length == 1) {
      await stop();
      return;
    }

    _queue.removeAt(index);
    await _playlist.removeAt(index);
  }

  // ── Convenience streams ─────────────────────────────────────────────────────

  Song? get currentSong => _queue.isNotEmpty && _currentIndex < _queue.length ? _queue[_currentIndex] : null;

  /// Returns songs in the effective playback order.
  ///
  /// When shuffle is enabled, just_audio reorders tracks internally via
  /// [AudioPlayer.effectiveIndices]. We expose those indices here so that
  /// [PlayerNotifier] can reflect the correct visible queue order.
  List<Song> get currentQueue {
    final effective = _player.effectiveIndices;
    if (effective.length == _queue.length) {
      return List.unmodifiable(effective.map((i) => _queue[i]).toList());
    }
    return List.unmodifiable(_queue);
  }

  /// Emits whenever the effective shuffle order changes so [PlayerNotifier]
  /// can update its queue state reactively.
  Stream<List<int>?> get shuffleIndicesStream => _player.shuffleIndicesStream;

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
