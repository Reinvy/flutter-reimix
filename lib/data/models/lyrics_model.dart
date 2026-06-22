import 'package:objectbox/objectbox.dart';

/// Persisted lyrics data for a song.
///
/// [syncedLrc] stores the raw LRC-format string (with timestamps).
/// [plainText] stores the fallback unsynced lyrics.
@Entity()
class LyricsModel {
  @Id()
  int id = 0;

  /// The ObjectBox ID of the corresponding [SongModel].
  int songId = 0;

  String? plainText;

  /// Raw LRC-format lyrics string (e.g., "[00:12.34] Line text").
  String? syncedLrc;

  @Property(type: PropertyType.date)
  late DateTime fetchedAt;
}
