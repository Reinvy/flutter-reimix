/// Pure domain entity — no ObjectBox or platform dependencies.
class Song {
  final int id;
  final String filePath;
  final String title;
  final String? artist;
  final String? album;
  final String? genre;
  final int? year;
  final int? trackNumber;
  final int durationMs;
  final String? albumArtPath;
  final bool isFavorite;
  final int playCount;
  final DateTime? lastPlayedAt;
  final int totalListenedMs;
  final DateTime dateAdded;

  const Song({
    required this.id,
    required this.filePath,
    required this.title,
    this.artist,
    this.album,
    this.genre,
    this.year,
    this.trackNumber,
    required this.durationMs,
    this.albumArtPath,
    this.isFavorite = false,
    this.playCount = 0,
    this.lastPlayedAt,
    this.totalListenedMs = 0,
    required this.dateAdded,
  });

  Song copyWith({
    int? id,
    String? filePath,
    String? title,
    String? artist,
    String? album,
    String? genre,
    int? year,
    int? trackNumber,
    int? durationMs,
    String? albumArtPath,
    bool? isFavorite,
    int? playCount,
    DateTime? lastPlayedAt,
    int? totalListenedMs,
    DateTime? dateAdded,
  }) {
    return Song(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      genre: genre ?? this.genre,
      year: year ?? this.year,
      trackNumber: trackNumber ?? this.trackNumber,
      durationMs: durationMs ?? this.durationMs,
      albumArtPath: albumArtPath ?? this.albumArtPath,
      isFavorite: isFavorite ?? this.isFavorite,
      playCount: playCount ?? this.playCount,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      totalListenedMs: totalListenedMs ?? this.totalListenedMs,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other) || (other is Song && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
