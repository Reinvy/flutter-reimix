import '../entities/play_history.dart';
import '../entities/song.dart';

/// Aggregated listening statistics computed from the stored song library.
class ListeningStats {
  /// Songs sorted by playCount descending (top 20).
  final List<Song> topSongs;

  /// Artist names sorted by total play count descending (top 10).
  final List<ArtistStat> topArtists;

  /// Total accumulated listening time in milliseconds.
  final int totalListenedMs;

  /// Minutes listened per day for the last 7 days (index 0 = oldest day).
  final List<int> weeklyMinutes;

  /// Current consecutive days streak (days with ≥ 1 play ending today or yesterday).
  final int streak;

  const ListeningStats({
    required this.topSongs,
    required this.topArtists,
    required this.totalListenedMs,
    required this.weeklyMinutes,
    required this.streak,
  });
}

class ArtistStat {
  final String name;
  final int totalPlays;

  const ArtistStat({required this.name, required this.totalPlays});
}

/// Computes [ListeningStats] from a flat list of [Song] entities and a list of [PlayHistory] logs.
class GetListeningStats {
  const GetListeningStats();

  ListeningStats call(List<Song> allSongs, List<PlayHistory> playHistory) {
    // ── Top songs ────────────────────────────────────────────────────────────
    final topSongs = [...allSongs]..sort((a, b) => b.playCount.compareTo(a.playCount));
    final trimmedTopSongs = topSongs.take(20).toList();

    // ── Top artists ──────────────────────────────────────────────────────────
    final artistMap = <String, int>{};
    for (final s in allSongs) {
      final artist = s.artist?.trim();
      if (artist != null && artist.isNotEmpty) {
        artistMap[artist] = (artistMap[artist] ?? 0) + s.playCount;
      }
    }
    final topArtists =
        artistMap.entries.map((e) => ArtistStat(name: e.key, totalPlays: e.value)).toList()
          ..sort((a, b) => b.totalPlays.compareTo(a.totalPlays));

    // ── Total time ───────────────────────────────────────────────────────────
    final totalMs = playHistory.fold<int>(0, (sum, h) => sum + h.durationMs);

    // ── Weekly buckets (last 7 days) ─────────────────────────────────────────
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final buckets = List<int>.filled(7, 0);
    for (final h in playHistory) {
      final playedDate = DateTime(h.timestamp.year, h.timestamp.month, h.timestamp.day);
      final diff = todayStart.difference(playedDate).inDays;
      if (diff >= 0 && diff < 7) {
        // index 0 = 6 days ago, index 6 = today
        final idx = 6 - diff;
        buckets[idx] += (h.durationMs / 60000).round();
      }
    }

    // ── Streak ───────────────────────────────────────────────────────────────
    final playedDays = playHistory.map((h) {
      final d = h.timestamp;
      return '${d.year}-${d.month}-${d.day}';
    }).toSet();

    int streak = 0;
    var cursor = DateTime(now.year, now.month, now.day);
    
    // If today hasn't been played yet, check starting from yesterday
    if (!playedDays.contains('${cursor.year}-${cursor.month}-${cursor.day}')) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    while (playedDays.contains('${cursor.year}-${cursor.month}-${cursor.day}')) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return ListeningStats(
      topSongs: trimmedTopSongs,
      topArtists: topArtists.take(10).toList(),
      totalListenedMs: totalMs,
      weeklyMinutes: buckets,
      streak: streak,
    );
  }
}
