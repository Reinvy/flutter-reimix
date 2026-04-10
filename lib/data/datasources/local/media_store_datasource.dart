import 'package:on_audio_query/on_audio_query.dart' hide SongModel;

import '../../models/song_model.dart';
import 'objectbox_datasource.dart';

/// Wraps [OnAudioQuery] to scan device MediaStore and persist results.
///
/// Pagination is handled by [OnAudioQuery] internally; the datasource
/// fetches all songs in a single call and deduplicates by [filePath]
/// before writing to ObjectBox.
class MediaStoreDatasource {
  final ObjectBoxDatasource _db;
  final OnAudioQuery _audioQuery = OnAudioQuery();

  static const _supportedFormats = {'mp3', 'flac', 'aac', 'm4a', 'ogg', 'wav'};

  MediaStoreDatasource(this._db);

  /// Queries all audio files, filters to [_supportedFormats], merges with
  /// existing database records (preserving isFavorite, playCount, etc.),
  /// and returns the complete persisted list.
  Future<List<SongModel>> scanAndSave() async {
    final rawSongs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    final filtered = rawSongs.where((s) {
      final ext = s.fileExtension.toLowerCase();
      return _supportedFormats.contains(ext);
    });

    final now = DateTime.now();
    final incoming = filtered.map((s) {
      final model = SongModel()
        ..filePath = s.data
        ..title = s.title
        ..artist = s.artist
        ..album = s.album
        ..genre = s.genre
        ..year = s.getMap['year'] as int?
        ..trackNumber = s.track
        ..durationMs = s.duration ?? 0
        ..albumArtPath = null
        ..isFavorite = false
        ..playCount = 0
        ..totalListenedMs = 0
        ..dateAdded = now;
      return model;
    }).toList();

    _mergeIntoDatabase(incoming);
    return _db.songBox.getAll();
  }

  /// Inserts only songs whose [filePath] is not yet stored, keeping existing
  /// metadata (favorites, play counts) intact.
  void _mergeIntoDatabase(List<SongModel> incoming) {
    final existing = _db.songBox.getAll();
    final knownPaths = {for (final s in existing) s.filePath};

    final newSongs = incoming.where((m) => !knownPaths.contains(m.filePath)).toList();

    if (newSongs.isNotEmpty) {
      _db.songBox.putMany(newSongs);
    }
  }
}
