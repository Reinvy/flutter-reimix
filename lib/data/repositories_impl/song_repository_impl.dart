import '../../domain/entities/album.dart';
import '../../domain/entities/artist.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/song_repository.dart';
import '../datasources/local/media_store_datasource.dart';
import '../datasources/local/objectbox_datasource.dart';
import '../models/song_model.dart';
import '../../objectbox.g.dart';

/// Concrete implementation of [SongRepository].
///
/// Uses [MediaStoreDatasource] for device scanning and [ObjectBoxDatasource]
/// for local persistence & queries.
class SongRepositoryImpl implements SongRepository {
  final MediaStoreDatasource _mediaStore;
  final ObjectBoxDatasource _db;

  SongRepositoryImpl(this._mediaStore, this._db);

  // ── Mapping ─────────────────────────────────────────────────────────────────

  Song _toEntity(SongModel m) => Song(
    id: m.id,
    filePath: m.filePath,
    title: m.title,
    artist: m.artist,
    album: m.album,
    genre: m.genre,
    year: m.year,
    trackNumber: m.trackNumber,
    durationMs: m.durationMs,
    albumArtPath: m.albumArtPath,
    isFavorite: m.isFavorite,
    playCount: m.playCount,
    lastPlayedAt: m.lastPlayedAt,
    totalListenedMs: m.totalListenedMs,
    dateAdded: m.dateAdded,
  );

  // ── SongRepository ───────────────────────────────────────────────────────────

  @override
  Future<List<Song>> getAllSongs() async {
    return _db.songBox.getAll().map(_toEntity).toList();
  }

  @override
  Future<List<Song>> scanAndSave() async {
    final models = await _mediaStore.scanAndSave();
    return models.map(_toEntity).toList();
  }

  @override
  Future<List<Song>> getSongsByArtist(String artist) async {
    final query = _db.songBox.query(SongModel_.artist.equals(artist)).build();
    final results = query.find().map(_toEntity).toList();
    query.close();
    return results;
  }

  @override
  Future<List<Song>> getSongsByAlbum(String album) async {
    final query = _db.songBox.query(SongModel_.album.equals(album)).build();
    final results = query.find().map(_toEntity).toList();
    query.close();
    return results;
  }

  @override
  Future<Song> toggleFavorite(int songId) async {
    final model = _db.songBox.get(songId);
    if (model == null) throw StateError('Song not found: $songId');
    model.isFavorite = !model.isFavorite;
    _db.songBox.put(model);
    return _toEntity(model);
  }

  @override
  Stream<List<Song>> watchAllSongs() {
    return _db.songBox
        .query()
        .watch(triggerImmediately: true)
        .map((query) => query.find().map(_toEntity).toList());
  }

  @override
  Future<List<Album>> getAllAlbums() async {
    final songs = _db.songBox.getAll();
    final albumMap = <String, Album>{};
    for (final s in songs) {
      final name = s.album ?? 'Unknown Album';
      final existing = albumMap[name];
      if (existing == null) {
        albumMap[name] = Album(name: name, artist: s.artist, artPath: s.albumArtPath, songCount: 1);
      } else {
        albumMap[name] = existing.copyWith(
          artPath: existing.artPath ?? s.albumArtPath,
          songCount: existing.songCount + 1,
        );
      }
    }
    return albumMap.values.toList();
  }

  @override
  Future<List<Artist>> getAllArtists() async {
    final songs = _db.songBox.getAll();
    final artistMap = <String, int>{};
    for (final s in songs) {
      final name = s.artist ?? 'Unknown Artist';
      artistMap[name] = (artistMap[name] ?? 0) + 1;
    }
    return artistMap.entries.map((e) => Artist(name: e.key, songCount: e.value)).toList();
  }
}
