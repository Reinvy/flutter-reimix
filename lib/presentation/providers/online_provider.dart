import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../data/models/song_model.dart';
import '../../domain/entities/song.dart';
import '../../main.dart' show objectBox;
import 'library_provider.dart';

// ── YouTube Search Notifier ──────────────────────────────────────────────────

class YoutubeSearchNotifier extends StateNotifier<AsyncValue<List<Song>>> {
  YoutubeSearchNotifier() : super(const AsyncValue.data([]));

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    final yt = YoutubeExplode();
    try {
      final results = await yt.search.search(query);
      final songs = results.map((video) {
        // Generate a unique non-zero integer ID from the video hash code.
        // Make it negative to clearly separate from local media store positive IDs.
        final id = -video.id.value.hashCode.abs();

        return Song(
          id: id,
          filePath: 'youtube://${video.id.value}',
          title: video.title,
          artist: video.author,
          album: 'YouTube Stream',
          durationMs: video.duration?.inMilliseconds ?? 0,
          albumArtPath: video.thumbnails.highResUrl,
          dateAdded: DateTime.now(),
        );
      }).toList();

      state = AsyncValue.data(songs);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    } finally {
      yt.close();
    }
  }
}

final youtubeSearchProvider = StateNotifierProvider<YoutubeSearchNotifier, AsyncValue<List<Song>>>((
  ref,
) {
  return YoutubeSearchNotifier();
});

// ── Download Queue Notifier ──────────────────────────────────────────────────

class DownloadQueueNotifier extends StateNotifier<Map<String, double>> {
  DownloadQueueNotifier() : super({}) {
    scheduleMicrotask(() => _loadQueue());
  }

  Ref? _ref;
  final List<Song> _downloadQueue = [];
  final Set<String> _activeDownloads = {};
  final Map<String, String> _speeds = {};
  final Map<String, String> _etas = {};

  bool isDownloading(String videoId) => state.containsKey(videoId);
  double? getProgress(String videoId) => state[videoId];
  bool isQueued(String videoId) => state[videoId] == -1.0;
  String getSpeed(String videoId) => _speeds[videoId] ?? '0 KB/s';
  String getEta(String videoId) => _etas[videoId] ?? '--:--';

  Future<void> _loadQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString('pending_download_queue');
      if (queueJson != null) {
        final list = jsonDecode(queueJson) as List;
        final songs = list.map((item) => _mapToSong(item as Map<String, dynamic>)).toList();
        for (final song in songs) {
          _enqueue(song);
        }
      }
    } catch (_) {}
  }

  Future<void> _saveQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _downloadQueue.map((s) => _songToMap(s)).toList();
      await prefs.setString('pending_download_queue', jsonEncode(list));
    } catch (_) {}
  }

  void _enqueue(Song song) {
    final videoId = song.filePath.replaceFirst('youtube://', '');
    if (state.containsKey(videoId)) return;

    if (_activeDownloads.length < 3) {
      _activeDownloads.add(videoId);
      state = {...state, videoId: 0.0};
      _startDownload(song);
    } else {
      _downloadQueue.add(song);
      state = {...state, videoId: -1.0}; // -1.0 means Queued
      _saveQueue();
    }
  }

  Future<bool> download(Song song, WidgetRef ref) async {
    final videoId = song.filePath.replaceFirst('youtube://', '');
    if (state.containsKey(videoId)) return false;

    _enqueue(song);
    return true;
  }

  void _startDownload(Song song) async {
    final videoId = song.filePath.replaceFirst('youtube://', '');
    final yt = YoutubeExplode();
    IOSink? fileSink;

    try {
      final manifest = await yt.videos.streamsClient.getManifest(videoId);
      final audioStream = manifest.audioOnly.withHighestBitrate();
      final totalBytes = audioStream.size.totalBytes;

      final docsDir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${docsDir.path}/Downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final localPath = '${downloadsDir.path}/youtube_$videoId.m4a';
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
      }

      final stream = yt.videos.streamsClient.get(audioStream);
      fileSink = file.openWrite();

      int downloadedBytes = 0;
      final startTime = DateTime.now();
      var lastUpdateTime = DateTime.now();

      await for (final chunk in stream) {
        fileSink.add(chunk);
        downloadedBytes += chunk.length;

        final now = DateTime.now();
        final deltaMs = now.difference(lastUpdateTime).inMilliseconds;
        
        if (deltaMs >= 500 || downloadedBytes == totalBytes) {
          final progress = downloadedBytes / totalBytes;
          
          final timeSinceStart = now.difference(startTime).inMilliseconds;
          final averageSpeedBps = timeSinceStart > 0 ? (downloadedBytes / (timeSinceStart / 1000)) : 0.0;
          
          String speedStr;
          if (averageSpeedBps > 1024 * 1024) {
            speedStr = '${(averageSpeedBps / (1024 * 1024)).toStringAsFixed(1)} MB/s';
          } else {
            speedStr = '${(averageSpeedBps / 1024).toStringAsFixed(0)} KB/s';
          }
          _speeds[videoId] = speedStr;

          if (averageSpeedBps > 0) {
            final remainingBytes = totalBytes - downloadedBytes;
            final remainingSeconds = (remainingBytes / averageSpeedBps).round();
            final minutes = remainingSeconds ~/ 60;
            final seconds = remainingSeconds % 60;
            _etas[videoId] = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
          } else {
            _etas[videoId] = '--:--';
          }

          if (mounted) {
            state = {...state, videoId: progress};
          }
          lastUpdateTime = now;
        }
      }

      await fileSink.close();
      fileSink = null;

      final model = SongModel()
        ..filePath = file.path
        ..title = song.title
        ..artist = song.artist
        ..album = 'YouTube Download'
        ..durationMs = song.durationMs
        ..albumArtPath = song.albumArtPath
        ..dateAdded = DateTime.now();

      objectBox.songBox.put(model);

    } catch (e) {
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        final localPath = '${docsDir.path}/Downloads/youtube_$videoId.m4a';
        final file = File(localPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    } finally {
      yt.close();
      if (fileSink != null) {
        try {
          await fileSink.close();
        } catch (_) {}
      }

      _speeds.remove(videoId);
      _etas.remove(videoId);
      _activeDownloads.remove(videoId);
      
      if (mounted) {
        final updated = Map<String, double>.from(state)..remove(videoId);
        state = updated;
      }
      
      if (mounted) {
        _ref?.invalidate(libraryProvider);
      }

      if (_downloadQueue.isNotEmpty) {
        final nextSong = _downloadQueue.removeAt(0);
        final nextVideoId = nextSong.filePath.replaceFirst('youtube://', '');
        _activeDownloads.add(nextVideoId);
        if (mounted) {
          state = {...state, nextVideoId: 0.0};
        }
        _saveQueue();
        _startDownload(nextSong);
      }
    }
  }

  Map<String, dynamic> _songToMap(Song song) {
    return {
      'id': song.id,
      'filePath': song.filePath,
      'title': song.title,
      'artist': song.artist,
      'album': song.album,
      'durationMs': song.durationMs,
      'albumArtPath': song.albumArtPath,
      'dateAdded': song.dateAdded.toIso8601String(),
    };
  }

  Song _mapToSong(Map<String, dynamic> map) {
    return Song(
      id: map['id'] as int,
      filePath: map['filePath'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String?,
      album: map['album'] as String?,
      durationMs: map['durationMs'] as int,
      albumArtPath: map['albumArtPath'] as String?,
      dateAdded: DateTime.tryParse(map['dateAdded'] as String) ?? DateTime.now(),
    );
  }
}

final downloadQueueProvider = StateNotifierProvider<DownloadQueueNotifier, Map<String, double>>((
  ref,
) {
  final notifier = DownloadQueueNotifier();
  notifier._ref = ref;
  return notifier;
});


// ── Online Recent Searches Notifier ──────────────────────────────────────────

class OnlineRecentsNotifier extends AsyncNotifier<List<String>> {
  static const _key = 'online_recent_searches';

  @override
  FutureOr<List<String>> build() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_key) ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<void> add(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;

    final current = state.valueOrNull ?? [];
    final updated = [q, ...current.where((item) => item != q)].take(10).toList();
    state = AsyncValue.data(updated);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, updated);
    } catch (_) {}
  }

  Future<void> remove(String query) async {
    final current = state.valueOrNull ?? [];
    final updated = current.where((item) => item != query).toList();
    state = AsyncValue.data(updated);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, updated);
    } catch (_) {}
  }

  Future<void> clear() async {
    state = const AsyncValue.data([]);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}

final onlineRecentsProvider = AsyncNotifierProvider<OnlineRecentsNotifier, List<String>>(() {
  return OnlineRecentsNotifier();
});

// ── Online Search Autocomplete Suggestions ───────────────────────────────────

class OnlineSuggestNotifier extends StateNotifier<AsyncValue<List<String>>> {
  OnlineSuggestNotifier() : super(const AsyncValue.data([]));

  Future<void> fetchSuggestions(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    final yt = YoutubeExplode();
    try {
      final suggestions = await yt.search.getQuerySuggestions(query);
      state = AsyncValue.data(suggestions);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    } finally {
      yt.close();
    }
  }

  void clear() {
    state = const AsyncValue.data([]);
  }
}

final onlineSuggestProvider =
    StateNotifierProvider<OnlineSuggestNotifier, AsyncValue<List<String>>>((ref) {
  return OnlineSuggestNotifier();
});

// ── Online Playlist Model & Search Notifier ──────────────────────────────────

class OnlinePlaylist {
  final String id;
  final String title;
  final int videoCount;
  final String thumbnailUrl;

  OnlinePlaylist({
    required this.id,
    required this.title,
    required this.videoCount,
    required this.thumbnailUrl,
  });
}

class YoutubePlaylistSearchNotifier extends StateNotifier<AsyncValue<List<OnlinePlaylist>>> {
  YoutubePlaylistSearchNotifier() : super(const AsyncValue.data([]));

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    final yt = YoutubeExplode();
    try {
      final results = await yt.search.searchContent(query, filter: TypeFilters.playlist);
      final playlists = results
          .whereType<SearchPlaylist>()
          .map((res) => OnlinePlaylist(
                id: res.id.value,
                title: res.title,
                videoCount: res.videoCount,
                thumbnailUrl: res.thumbnails.isNotEmpty ? res.thumbnails.first.url.toString() : '',
              ))
          .toList();
      state = AsyncValue.data(playlists);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    } finally {
      yt.close();
    }
  }

  void clear() {
    state = const AsyncValue.data([]);
  }
}

final youtubePlaylistSearchProvider =
    StateNotifierProvider<YoutubePlaylistSearchNotifier, AsyncValue<List<OnlinePlaylist>>>((ref) {
  return YoutubePlaylistSearchNotifier();
});

// ── Playlist Videos Provider ──────────────────────────────────────────────────

final playlistVideosProvider = FutureProvider.family<List<Song>, String>((ref, playlistId) async {
  final yt = YoutubeExplode();
  try {
    final videos = await yt.playlists.getVideos(playlistId).toList();
    return videos.map((video) {
      final id = -video.id.value.hashCode.abs();
      return Song(
        id: id,
        filePath: 'youtube://${video.id.value}',
        title: video.title,
        artist: video.author,
        album: 'YouTube Stream',
        durationMs: video.duration?.inMilliseconds ?? 0,
        albumArtPath: video.thumbnails.highResUrl,
        dateAdded: DateTime.now(),
      );
    }).toList();
  } finally {
    yt.close();
  }
});

// ── YouTube Trending Music Notifier ──────────────────────────────────────────

class YoutubeTrendingNotifier extends StateNotifier<AsyncValue<List<Song>>> {
  YoutubeTrendingNotifier() : super(const AsyncValue.data([]));

  Future<void> fetchTrending() async {
    state = const AsyncValue.loading();
    final yt = YoutubeExplode();
    try {
      final results = await yt.search.search("Trending Music");
      final songs = results.map((video) {
        final id = -video.id.value.hashCode.abs();
        return Song(
          id: id,
          filePath: 'youtube://${video.id.value}',
          title: video.title,
          artist: video.author,
          album: 'YouTube Stream',
          durationMs: video.duration?.inMilliseconds ?? 0,
          albumArtPath: video.thumbnails.highResUrl,
          dateAdded: DateTime.now(),
        );
      }).toList();
      state = AsyncValue.data(songs);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    } finally {
      yt.close();
    }
  }
}

final youtubeTrendingProvider =
    StateNotifierProvider<YoutubeTrendingNotifier, AsyncValue<List<Song>>>((ref) {
  return YoutubeTrendingNotifier()..fetchTrending();
});
