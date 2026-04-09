import '../entities/playlist.dart';
import '../entities/song.dart';

/// Abstract contract for playlist CRUD operations.
abstract class PlaylistRepository {
  /// Returns all playlists (smart + user-created) from local storage.
  Future<List<Playlist>> getAll();

  /// Creates a new user playlist with the given [name] and optional
  /// [coverImagePath]. Returns the persisted [Playlist].
  Future<Playlist> create(String name, {String? coverImagePath});

  /// Adds [song] to the playlist identified by [playlistId].
  Future<void> addSong(int playlistId, Song song);

  /// Removes the song with [songId] from the playlist [playlistId].
  Future<void> removeSong(int playlistId, int songId);

  /// Persists a new song order (list of song IDs) for [playlistId].
  Future<void> reorder(int playlistId, List<int> songIds);

  /// Permanently deletes the playlist with [playlistId].
  Future<void> delete(int playlistId);
}
