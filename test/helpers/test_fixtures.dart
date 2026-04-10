import 'package:reimix/domain/entities/playlist.dart';
import 'package:reimix/domain/entities/song.dart';

// ── Song fixtures ─────────────────────────────────────────────────────────────

/// Creates a [Song] with sensible defaults; override any field as needed.
Song fakeSong({
  int id = 1,
  String filePath = '/music/test_song.mp3',
  String title = 'Test Song',
  String? artist = 'Test Artist',
  String? album = 'Test Album',
  String? genre = 'Pop',
  int? year = 2024,
  int? trackNumber = 1,
  int durationMs = 210000, // 3m 30s
  String? albumArtPath,
  bool isFavorite = false,
  int playCount = 0,
  DateTime? lastPlayedAt,
  int totalListenedMs = 0,
  DateTime? dateAdded,
}) {
  return Song(
    id: id,
    filePath: filePath,
    title: title,
    artist: artist,
    album: album,
    genre: genre,
    year: year,
    trackNumber: trackNumber,
    durationMs: durationMs,
    albumArtPath: albumArtPath,
    isFavorite: isFavorite,
    playCount: playCount,
    lastPlayedAt: lastPlayedAt,
    totalListenedMs: totalListenedMs,
    dateAdded: dateAdded ?? DateTime(2024, 1, 1),
  );
}

/// A handful of reusable [Song] instances.
final Song song1 = fakeSong(id: 1, title: 'Song One', artist: 'Artist A');
final Song song2 = fakeSong(id: 2, title: 'Song Two', artist: 'Artist B', durationMs: 300000);
final Song song3 = fakeSong(id: 3, title: 'Song Three', artist: 'Artist A', isFavorite: true);
final Song songNoArtist = fakeSong(id: 4, title: 'No Artist Song', artist: null);
final Song longSong = fakeSong(id: 5, title: 'Long Song', durationMs: 3_720_000); // 1h 2m

// ── Playlist fixtures ─────────────────────────────────────────────────────────

/// Creates a [Playlist] with sensible defaults; override any field as needed.
Playlist fakePlaylist({
  int id = 1,
  String name = 'My Playlist',
  String? coverImagePath,
  DateTime? createdAt,
  DateTime? updatedAt,
  bool isSmartPlaylist = false,
  String? smartPlaylistType,
  List<Song> songs = const [],
}) {
  return Playlist(
    id: id,
    name: name,
    coverImagePath: coverImagePath,
    createdAt: createdAt ?? DateTime(2024, 1, 1),
    updatedAt: updatedAt,
    isSmartPlaylist: isSmartPlaylist,
    smartPlaylistType: smartPlaylistType,
    songs: songs,
  );
}

/// A handful of reusable [Playlist] instances.
final Playlist emptyPlaylist = fakePlaylist(id: 1, name: 'Empty');
final Playlist filledPlaylist = fakePlaylist(id: 2, name: 'Filled', songs: [song1, song2, song3]);
final Playlist smartFavorites = fakePlaylist(
  id: 3,
  name: 'Favorites',
  isSmartPlaylist: true,
  smartPlaylistType: 'favorites',
  songs: [song3],
);
