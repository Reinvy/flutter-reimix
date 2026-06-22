import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../../domain/entities/song.dart';
import '../../../main.dart' show objectBox;

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
    handleInterruptions: false, // Handle manually using AudioSession to support settings
    userAgent:
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    useProxyForRequestHeaders: false,
  );
  final _errorController = StreamController<AudioException>.broadcast();
  final _ytCache = <String, _YtCacheEntry>{};
  int? _currentBitrate;
  int? get currentBitrate => _currentBitrate;

  ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(children: []);
  List<Song> _queue = [];
  int _currentIndex = 0;

  ReimixAudioHandler() {
    _initAudioSession();

    // Forward just_audio events → audio_service playbackState
    _player.playbackEventStream.listen(
      _broadcastState,
      onError: (Object e, StackTrace st) {
        _handlePlaybackError(e);
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

  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      session.interruptionEventStream.listen((event) {
        final settings = objectBox.getSettings();
        if (!settings.audioFocusPause) return; // Do not pause if disabled in settings

        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _player.setVolume(0.2);
              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              pause();
              break;
          }
        } else {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _player.setVolume(1.0);
              break;
            case AudioInterruptionType.pause:
              // Optionally resume, but standard is to stay paused after phone calls
              break;
            case AudioInterruptionType.unknown:
              break;
          }
        }
      });
    } catch (_) {}
  }

  Future<void> _handlePlaybackError(Object error) async {
    if (_currentIndex >= 0 && _currentIndex < _queue.length) {
      final song = _queue[_currentIndex];
      if (song.filePath.startsWith('youtube://')) {
        final videoId = song.filePath.replaceFirst('youtube://', '');
        
        // Evict expired URL from cache
        _ytCache.remove(videoId);
        
        // Re-resolve URL and replace the active audio source in the playlist
        try {
          final position = _player.position;
          final newSource = await _createAudioSource(song);
          
          await _playlist.insert(_currentIndex, newSource);
          await _playlist.removeAt(_currentIndex + 1);
          
          if (_player.playing) {
            await _player.seek(position);
            await _player.play();
          } else {
            await _player.seek(position);
          }
        } catch (_) {
          // If refresh fails, let the error propagate
        }
      }
    }
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

  AudioStreamInfo _selectStream(StreamManifest manifest, String quality) {
    final audioStreams = manifest.audioOnly.toList();
    if (audioStreams.isEmpty) {
      throw StateError('No audio streams available');
    }
    
    // Sort by bitrate descending
    audioStreams.sort((a, b) => b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond));
    
    switch (quality) {
      case 'high':
        return audioStreams.first; // Highest bitrate
      case 'low':
        return audioStreams.last; // Lowest bitrate
      case 'medium':
        // Find stream closest to 128kbps (128000 bps)
        AudioStreamInfo best = audioStreams.first;
        double minDiff = double.infinity;
        for (final stream in audioStreams) {
          final diff = (stream.bitrate.bitsPerSecond - 128000).abs().toDouble();
          if (diff < minDiff) {
            minDiff = diff;
            best = stream;
          }
        }
        return best;
      case 'auto':
      default:
        return audioStreams.first;
    }
  }

  void _startBackgroundCache(String videoId, AudioStreamInfo streamInfo) {
    scheduleMicrotask(() async {
      final yt = YoutubeExplode();
      IOSink? fileSink;
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        final cacheDir = Directory('${docsDir.path}/yt_cache');
        if (!await cacheDir.exists()) {
          await cacheDir.create(recursive: true);
        }

        // Enforce LRU cache limit before downloading
        await _enforceLruCacheLimit(cacheDir);

        final tempFile = File('${cacheDir.path}/$videoId.temp');
        final targetFile = File('${cacheDir.path}/$videoId.m4a');

        if (await targetFile.exists()) return; // Already cached
        if (await tempFile.exists()) await tempFile.delete();

        final stream = yt.videos.streams.get(streamInfo);
        fileSink = tempFile.openWrite();
        await for (final chunk in stream) {
          fileSink.add(chunk);
        }
        await fileSink.close();
        fileSink = null;

        await tempFile.rename(targetFile.path);
      } catch (_) {
        // Fail silently in background
      } finally {
        yt.close();
        if (fileSink != null) {
          try {
            await fileSink.close();
          } catch (_) {}
        }
      }
    });
  }

  Future<void> _enforceLruCacheLimit(Directory cacheDir) async {
    try {
      final settings = objectBox.getSettings();
      final maxBytes = settings.maxCacheSizeMb * 1024 * 1024;

      final files = await cacheDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.m4a'))
          .cast<File>()
          .toList();
      
      int totalSize = 0;
      final fileStats = <File, DateTime>{};
      for (final file in files) {
        totalSize += await file.length();
        fileStats[file] = await file.lastModified();
      }

      if (totalSize < maxBytes) return; // Under limit

      // Sort oldest first
      files.sort((a, b) => (fileStats[a] ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(fileStats[b] ?? DateTime.fromMillisecondsSinceEpoch(0)));

      for (final file in files) {
        if (totalSize < maxBytes) break;
        final size = await file.length();
        await file.delete();
        totalSize -= size;
      }
    } catch (_) {}
  }

  Future<Uri> _resolveAudioUri(String filePath) async {
    if (filePath.startsWith('youtube://')) {
      final videoId = filePath.replaceFirst('youtube://', '');
      
      // 1. Check disk cache first
      final docsDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${docsDir.path}/yt_cache');
      final cacheFile = File('${cacheDir.path}/$videoId.m4a');
      if (await cacheFile.exists()) {
        try {
          await cacheFile.setLastModified(DateTime.now());
        } catch (_) {}
        _currentBitrate = -1; // -1 indicates local disk cache
        return Uri.file(cacheFile.path);
      }
      
      // 2. Check memory cache next
      final cached = _ytCache[videoId];
      if (cached != null && !cached.isExpired) {
        return cached.uri;
      }

      // 3. Resolve online stream URL
      final settings = objectBox.getSettings();
      final quality = settings.streamingQuality;

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
        final audioStream = _selectStream(manifest, quality);
        final url = audioStream.url;
        
        _ytCache[videoId] = _YtCacheEntry(url, DateTime.now());
        _currentBitrate = audioStream.bitrate.bitsPerSecond;
        
        // Start background download to disk cache
        _startBackgroundCache(videoId, audioStream);
        
        return url;
      } catch (e) {
        throw AudioException('Failed to resolve YouTube audio stream for $videoId', cause: e);
      } finally {
        yt.close();
      }
    }
    _currentBitrate = null; // Local song
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
