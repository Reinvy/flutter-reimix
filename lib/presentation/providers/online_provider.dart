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

final youtubeSearchProvider =
    StateNotifierProvider<YoutubeSearchNotifier, AsyncValue<List<Song>>>((ref) {
  return YoutubeSearchNotifier();
});

// ── Download Queue Notifier ──────────────────────────────────────────────────

/// Map of Video ID to download progress (0.0 to 1.0)
class DownloadQueueNotifier extends StateNotifier<Map<String, double>> {
  DownloadQueueNotifier() : super({});

  bool isDownloading(String videoId) => state.containsKey(videoId);

  double? getProgress(String videoId) => state[videoId];

  Future<bool> download(Song song, WidgetRef ref) async {
    final videoId = song.filePath.replaceFirst('youtube://', '');
    if (state.containsKey(videoId)) return false; // Already downloading

    state = {...state, videoId: 0.0};
    final yt = YoutubeExplode();

    try {
      // 1. Get audio stream metadata
      final manifest = await yt.videos.streamsClient.getManifest(videoId);
      final audioStream = manifest.audioOnly.withHighestBitrate();
      final totalBytes = audioStream.size.totalBytes;

      // 2. Prepare local save directory
      final docsDir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${docsDir.path}/Downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // Safe filename format: youtube_[video_id].m4a
      final localPath = '${downloadsDir.path}/youtube_$videoId.m4a';
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
      }

      // 3. Download the stream chunk by chunk
      final stream = yt.videos.streamsClient.get(audioStream);
      final fileSink = file.openWrite();
      int downloadedBytes = 0;

      await for (final chunk in stream) {
        fileSink.add(chunk);
        downloadedBytes += chunk.length;
        
        // Update live progress
        final progress = downloadedBytes / totalBytes;
        state = {...state, videoId: progress};
      }

      await fileSink.close();

      // 4. Register downloaded song into ObjectBox
      final model = SongModel()
        ..filePath = file.path
        ..title = song.title
        ..artist = song.artist
        ..album = 'YouTube Download'
        ..durationMs = song.durationMs
        ..albumArtPath = song.albumArtPath // Keep remote URL thumbnail
        ..dateAdded = DateTime.now();
      
      objectBox.songBox.put(model);

      // Invalidate the libraryProvider so it scans and lists the downloaded song immediately
      ref.invalidate(libraryProvider);

      return true;
    } catch (_) {
      return false;
    } finally {
      yt.close();
      // Remove from active queue
      final updated = Map<String, double>.from(state)..remove(videoId);
      state = updated;
    }
  }
}

final downloadQueueProvider =
    StateNotifierProvider<DownloadQueueNotifier, Map<String, double>>((ref) {
  return DownloadQueueNotifier();
});

// ── Online Recent Searches Notifier ──────────────────────────────────────────

class OnlineRecentsNotifier extends StateNotifier<List<String>> {
  static const _key = 'online_recent_searches';

  OnlineRecentsNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList(_key) ?? [];
  }

  Future<void> add(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    
    final updated = [q, ...state.where((item) => item != q)].take(10).toList();
    state = updated;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, updated);
  }

  Future<void> remove(String query) async {
    final updated = state.where((item) => item != query).toList();
    state = updated;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, updated);
  }

  Future<void> clear() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final onlineRecentsProvider =
    StateNotifierProvider<OnlineRecentsNotifier, List<String>>((ref) {
  return OnlineRecentsNotifier();
});
