import '../../domain/entities/playlist.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../datasources/local/objectbox_datasource.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';

/// Concrete implementation of [PlaylistRepository] backed by ObjectBox.
class PlaylistRepositoryImpl implements PlaylistRepository {
  final ObjectBoxDatasource _db;

  PlaylistRepositoryImpl(this._db);

  // ── Mapping ─────────────────────────────────────────────────────────────────

  Song _songToEntity(SongModel m) => Song(
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

  Playlist _toEntity(PlaylistModel m) => Playlist(
    id: m.id,
    name: m.name,
    coverImagePath: m.coverImagePath,
    createdAt: m.createdAt,
    updatedAt: m.updatedAt,
    isSmartPlaylist: m.isSmartPlaylist,
    smartPlaylistType: m.smartPlaylistType,
    songs: m.songs.map(_songToEntity).toList(),
  );

  // ── PlaylistRepository ───────────────────────────────────────────────────────

  @override
  Future<List<Playlist>> getAll() async {
    return _db.playlistBox.getAll().map(_toEntity).toList();
  }

  @override
  Future<Playlist> create(String name, {String? coverImagePath}) async {
    final model = PlaylistModel()
      ..name = name
      ..coverImagePath = coverImagePath
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..isSmartPlaylist = false;
    _db.playlistBox.put(model);
    return _toEntity(model);
  }

  @override
  Future<void> addSong(int playlistId, Song song) async {
    final playlist = _db.playlistBox.get(playlistId);
    if (playlist == null) return;
    final songModel = _db.songBox.get(song.id);
    if (songModel == null) return;
    playlist.songs.add(songModel);
    playlist.updatedAt = DateTime.now();
    _db.playlistBox.put(playlist);
  }

  @override
  Future<void> removeSong(int playlistId, int songId) async {
    final playlist = _db.playlistBox.get(playlistId);
    if (playlist == null) return;
    playlist.songs.removeWhere((s) => s.id == songId);
    playlist.updatedAt = DateTime.now();
    _db.playlistBox.put(playlist);
  }

  @override
  Future<void> reorder(int playlistId, List<int> songIds) async {
    final playlist = _db.playlistBox.get(playlistId);
    if (playlist == null) return;
    playlist.songOrder = songIds;
    playlist.updatedAt = DateTime.now();
    _db.playlistBox.put(playlist);
  }

  @override
  Future<void> delete(int playlistId) async {
    _db.playlistBox.remove(playlistId);
  }
}
