import '../entities/song.dart';
import '../entities/album.dart';
import '../entities/artist.dart';

/// Abstract contract for all song-related data operations.
abstract class SongRepository {
  /// Returns all songs currently stored in the local database.
  Future<List<Song>> getAllSongs();

  /// Scans device MediaStore, persists new songs, and returns the full list.
  Future<List<Song>> scanAndSave();

  /// Returns songs filtered by the given [artist] name.
  Future<List<Song>> getSongsByArtist(String artist);

  /// Returns songs filtered by the given [album] name.
  Future<List<Song>> getSongsByAlbum(String album);

  /// Toggles the favorite flag on the song with [songId] and returns the
  /// updated [Song].
  Future<Song> toggleFavorite(int songId);

  /// Live stream that emits the full song list whenever the database changes.
  Stream<List<Song>> watchAllSongs();

  /// Returns a deduplicated list of all albums derived from stored songs.
  Future<List<Album>> getAllAlbums();

  /// Returns a deduplicated list of all artists derived from stored songs.
  Future<List<Artist>> getAllArtists();
}
