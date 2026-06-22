import '../entities/lyrics.dart';

/// Abstract contract for fetching and caching lyrics.
abstract class LyricsRepository {
  /// Returns cached lyrics for [songId] if available, otherwise null.
  Future<Lyrics?> getCachedLyrics(int songId);

  /// Fetches lyrics from the remote API for [title] + [artist].
  ///
  /// [durationSeconds] is used by LRCLIB to identify the correct track.
  /// Returns null if no lyrics found.
  Future<Lyrics?> fetchLyrics({
    required int songId,
    required String title,
    required String artist,
    int? durationSeconds,
  });

  /// Saves [lyrics] to local cache.
  Future<void> cacheLyrics(Lyrics lyrics);
}
