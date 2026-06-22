import 'package:on_audio_query_pluse/on_audio_query.dart' hide SongModel;

import '../../models/song_model.dart';
import 'objectbox_datasource.dart';

/// Wraps [OnAudioQuery] to scan device MediaStore and persist results.
///
/// Queries both EXTERNAL and INTERNAL storage, deduplicates by [filePath],
/// and writes new entries to ObjectBox without overwriting existing metadata.
class MediaStoreDatasource {
  final ObjectBoxDatasource _db;
  final OnAudioQuery _audioQuery = OnAudioQuery();

  /// Guards against concurrent [querySongs] calls which crash with
  /// "Reply already submitted" on the platform channel.
  Future<List<SongModel>>? _ongoingScan;

  MediaStoreDatasource(this._db);

  /// Queries all audio files from every available storage (external + internal),
  /// merges with existing database records (preserving isFavorite, playCount,
  /// etc.), and returns the complete persisted list.
  Future<List<SongModel>> scanAndSave() {
    _ongoingScan ??= _doScan().whenComplete(() => _ongoingScan = null);
    return _ongoingScan!;
  }

  Future<List<SongModel>> _doScan() async {
    // Ensure the library's own internal permission check passes before querying.
    // permission_handler grants the system-level permission, but on_audio_query
    // performs a separate check; without this call it shows "storage access required".
    final hasPermission = await _audioQuery.checkAndRequest();
    if (!hasPermission) return _db.songBox.getAll();

    final results = await Future.wait([
      _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      ),
      _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.INTERNAL,
        ignoreCase: true,
      ),
    ]);

    // Deduplicate across both storages by filePath
    final seen = <String>{};
    final filtered = results.expand((list) => list).where((s) {
      return seen.add(s.data);
    });

    final now = DateTime.now();
    final incoming = filtered.map((s) {
      final model = SongModel()
        ..filePath = s.data
        ..title = s.title
        ..artist = s.artist
        ..album = s.album
        ..genre = s.genre
        ..year = _parseYear(s.getMap['year'])
        ..trackNumber = s.track
        ..durationMs = s.duration ?? 0
        ..albumArtPath = null
        ..isFavorite = false
        ..playCount = 0
        ..totalListenedMs = 0
        ..dateAdded = now;
      return model;
    }).toList();

    // Retrieve settings to apply duration and folder exclusions
    final settings = _db.getSettings();
    final minDurationMs = settings.scanMinDurationSeconds * 1000;
    final excludedFolders = settings.excludedFolders;

    final filteredIncoming = incoming.where((s) {
      // Filter out short files
      if (s.durationMs < minDurationMs) return false;

      // Filter out files in excluded directories
      final normalizedPath = s.filePath.replaceAll('\\', '/').toLowerCase();
      for (final folder in excludedFolders) {
        if (folder.trim().isEmpty) continue;
        final normalizedFolder = folder.replaceAll('\\', '/').toLowerCase();
        if (normalizedPath.contains(normalizedFolder)) {
          return false;
        }
      }
      return true;
    }).toList();

    _mergeIntoDatabase(filteredIncoming);
    return _db.songBox.getAll();
  }

  /// Inserts only songs whose [filePath] is not yet stored, keeping existing
  /// metadata (favorites, play counts) intact.
  ///
  /// Also removes songs from the database that no longer exist on the device,
  /// but exempts:
  ///  - Songs prefixed with `youtube://` (online/streamed songs)
  ///  - Songs stored in the app's documents directory (downloaded files)
  void _mergeIntoDatabase(List<SongModel> incoming) {
    final existing = _db.songBox.getAll();
    final incomingPaths = {for (final s in incoming) s.filePath};

    // Insert new songs that are not yet in the database
    final newSongs = incoming.where((m) {
      return !existing.any((e) => e.filePath == m.filePath);
    }).toList();

    if (newSongs.isNotEmpty) {
      _db.songBox.putMany(newSongs);
    }

    // Remove songs that were deleted from the device.
    // Exempt: youtube:// streams and downloaded files (in-app documents dir).
    final toRemove = existing.where((e) {
      // Never remove online/streamed songs
      if (e.filePath.startsWith('youtube://')) return false;
      // Never remove app-downloaded files
      if (e.filePath.contains('/Downloads/youtube_')) return false;
      // Remove if no longer in the scanned set
      return !incomingPaths.contains(e.filePath);
    }).toList();

    if (toRemove.isNotEmpty) {
      _db.songBox.removeMany(toRemove.map((s) => s.id).toList());
    }
  }

  /// Safely parses the year value from MediaStore, which may be returned as
  /// an int, a String (e.g. "2023"), or null.
  int? _parseYear(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    return int.tryParse(raw.toString().trim().split('-').first);
  }
}
