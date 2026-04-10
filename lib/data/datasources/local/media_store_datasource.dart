import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/services.dart';

import '../../models/song_model.dart';
import 'objectbox_datasource.dart';

/// Queries device audio files via platform MethodChannels and persists results.
///
/// - Android: Kotlin reads `MediaStore.Audio.Media` (API 16+).
/// - iOS: Swift reads `MPMediaQuery.songs()`.
///
/// On Android, if MediaStore does not provide a genre (API < 30),
/// `audio_metadata_reader` is used as a fallback to read it from the file tags.
///
/// Pagination is not needed — the platform side returns all results at once.
/// `_mergeIntoDatabase` deduplicates by [filePath] before persisting.
class MediaStoreDatasource {
  final ObjectBoxDatasource _db;
  static const _channel = MethodChannel('reimix/media_store');

  static const _supportedMimeTypes = {
    'audio/mpeg',
    'audio/flac',
    'audio/aac',
    'audio/mp4',
    'audio/ogg',
    'audio/x-wav',
    'audio/wav',
  };
  static const _supportedExtensions = {'mp3', 'flac', 'aac', 'm4a', 'ogg', 'wav'};

  MediaStoreDatasource(this._db);

  /// Queries all audio files from the platform, filters to supported formats,
  /// merges with existing database records (preserving isFavorite, playCount,
  /// etc.), and returns the complete persisted list.
  Future<List<SongModel>> scanAndSave() async {
    final rawList = await _channel.invokeListMethod<Object>('querySongs') ?? [];

    final now = DateTime.now();
    final incoming = <SongModel>[];

    for (final item in rawList) {
      if (item is! Map) continue;
      final song = Map<String, dynamic>.from(item);

      final filePath = song['filePath'] as String?;
      if (filePath == null || filePath.isEmpty) continue;

      // Filter by MIME type or file extension
      final mimeType = song['mimeType'] as String?;
      final ext = filePath.contains('.') ? filePath.split('.').last.toLowerCase() : '';
      final isMimeAllowed = mimeType != null && _supportedMimeTypes.contains(mimeType);
      final isExtAllowed = _supportedExtensions.contains(ext);
      if (!isMimeAllowed && !isExtAllowed) continue;

      // Genre: use platform-provided value first; fallback to audio_metadata_reader on Android
      String? genre = song['genre'] as String?;
      if (Platform.isAndroid && (genre == null || genre.isEmpty)) {
        genre = await _readGenreFromFile(filePath);
      }

      final model = SongModel()
        ..filePath = filePath
        ..title = song['title'] as String? ?? filePath.split('/').last
        ..artist = song['artist'] as String?
        ..album = song['album'] as String?
        ..genre = genre
        ..year = song['year'] as int?
        ..trackNumber = song['track'] as int?
        ..durationMs = (song['duration'] as int?) ?? 0
        ..albumArtPath = null
        ..isFavorite = false
        ..playCount = 0
        ..totalListenedMs = 0
        ..dateAdded = now;
      incoming.add(model);
    }

    _mergeIntoDatabase(incoming);
    return _db.songBox.getAll();
  }

  /// Reads the genre string from file ID3/Vorbis tags.
  /// Returns `null` on any error (e.g. file missing, unsupported codec).
  Future<String?> _readGenreFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return null;
      final metadata = readMetadata(file, getImage: false);
      final genres = metadata.genres;
      if (genres.isNotEmpty) return genres.first;
    } catch (_) {
      // Ignore — genre is optional
    }
    return null;
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
