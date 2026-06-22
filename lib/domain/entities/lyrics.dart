/// Represents a single timed lyric line.
class LyricLine {
  final Duration timestamp;
  final String text;

  const LyricLine({required this.timestamp, required this.text});
}

/// Domain entity for song lyrics.
///
/// Contains both plain and timed (LRC-formatted) lyrics.
/// [syncedLines] is null when only plain lyrics are available.
class Lyrics {
  final int songId;
  final String? plainText;
  final List<LyricLine>? syncedLines;
  final DateTime fetchedAt;

  const Lyrics({
    required this.songId,
    this.plainText,
    this.syncedLines,
    required this.fetchedAt,
  });

  bool get hasSynced => syncedLines != null && syncedLines!.isNotEmpty;
  bool get hasLyrics => (plainText?.isNotEmpty ?? false) || hasSynced;
}
