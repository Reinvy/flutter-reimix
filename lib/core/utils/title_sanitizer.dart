class SanitizedMetadata {
  final String artist;
  final String title;

  const SanitizedMetadata({required this.artist, required this.title});

  @override
  String toString() => '$artist - $title';
}

class TitleSanitizer {
  /// Regular expressions matching common YouTube noise/junk elements in video titles.
  static final List<RegExp> _noisePatterns = [
    // Matches parentheses containing keywords like (Official Video), (2009 Remaster), (Live at Wembley)
    RegExp(r'\([^)]*\b(video|audio|music|lyrics|lyric|hd|4k|hq|live|remaster|remastered|mv|clip|official)\b[^)]*\)', caseSensitive: false),
    // Matches brackets containing keywords like [Official Video], [2009 Remaster], [Live]
    RegExp(r'\[[^\]]*\b(video|audio|music|lyrics|lyric|hd|4k|hq|live|remaster|remastered|mv|clip|official)\b[^\]]*\]', caseSensitive: false),
    // Matches standalone features
    RegExp(r'\(feat\.\s+[^)]+\)', caseSensitive: false),
    RegExp(r'\[feat\.\s+[^\]]+\]', caseSensitive: false),
    RegExp(r'\(ft\.\s+[^)]+\)', caseSensitive: false),
    RegExp(r'\[ft\.\s+[^\]]+\]', caseSensitive: false),
    RegExp(r'\b(feat|ft)\b\.\s+[^\s)]+', caseSensitive: false),
    // standalone video/audio text
    RegExp(r'\b(official\s+)?(music\s+)?(video|audio)\b', caseSensitive: false),
    RegExp(r'\s*remaster(?:ed)?\s*', caseSensitive: false),
  ];

  /// Sanitizes a video title and returns a clean [SanitizedMetadata].
  static SanitizedMetadata sanitize(String videoTitle, {String? channelName}) {
    String working = videoTitle;

    // Remove all noise patterns
    for (final pattern in _noisePatterns) {
      working = working.replaceAll(pattern, '');
    }

    // Clean up surrounding quotes and brackets
    working = working
        .replaceAll(RegExp(r'''^[“"\'\[\(\s\-–—:]+'''), '')
        .replaceAll(RegExp(r'''[”"\'\]\)\s\-–—:]+$'''), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ') // Normalize spaces
        .trim();

    // Check for standard separators: - or – or — or :
    final separatorMatch = RegExp(r'\s+[-–—:]\s+').firstMatch(working);
    String artist = '';
    String title = '';

    if (separatorMatch != null) {
      final index = separatorMatch.start;
      final separatorLength = separatorMatch.end - separatorMatch.start;
      artist = working.substring(0, index).trim();
      title = working.substring(index + separatorLength).trim();
    } else {
      // No clear separator: use channelName as artist if provided, title is the cleaned title
      title = working;
      if (channelName != null) {
        // Strip common channel suffix like "VEVO", "Official", "Topic", etc.
        artist = channelName
            .replaceAll(RegExp(r'\b(official|music|topic|channel|records)\b|vevo\b', caseSensitive: false), '')
            .replaceAll(RegExp(r'\s{2,}'), ' ')
            .trim();
      }
    }

    // Fallbacks
    if (artist.isEmpty) artist = channelName ?? 'Unknown Artist';
    if (title.isEmpty) title = videoTitle;

    return SanitizedMetadata(
      artist: artist,
      title: title,
    );
  }
}
