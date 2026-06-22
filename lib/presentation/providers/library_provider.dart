import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local/media_store_datasource.dart';
import '../../data/datasources/local/objectbox_datasource.dart';
import '../../data/repositories_impl/song_repository_impl.dart';
import '../../data/repositories_impl/stats_repository_impl.dart';
import '../../domain/entities/album.dart';
import '../../domain/entities/artist.dart';
import '../../domain/entities/song.dart';
import '../../main.dart' show objectBox;

// ── Datasource & repository providers ────────────────────────────────────────

final _objectBoxProvider = Provider<ObjectBoxDatasource>((_) => objectBox);

final mediaStoreDatasourceProvider = Provider<MediaStoreDatasource>((ref) {
  return MediaStoreDatasource(ref.read(_objectBoxProvider));
});

final songRepositoryProvider = Provider<SongRepositoryImpl>((ref) {
  return SongRepositoryImpl(ref.read(mediaStoreDatasourceProvider), ref.read(_objectBoxProvider));
});

final statsRepositoryProvider = Provider<StatsRepositoryImpl>((ref) {
  return StatsRepositoryImpl(ref.read(_objectBoxProvider));
});

// ── Library notifier ─────────────────────────────────────────────────────────

/// Async state for the full song library.
///
/// Call [scan()] to trigger a MediaStore scan and refresh the list.
class LibraryNotifier extends AsyncNotifier<List<Song>> {
  @override
  Future<List<Song>> build() {
    return ref.read(songRepositoryProvider).getAllSongs();
  }

  Future<void> scan() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(songRepositoryProvider).scanAndSave());
    if (state is AsyncData) {
      ref.read(scanCompleteCountProvider.notifier).state++;
    }
  }
}

final libraryProvider = AsyncNotifierProvider<LibraryNotifier, List<Song>>(LibraryNotifier.new);

/// Incremented each time a library scan completes successfully.
/// Listen to this in UI widgets to show a "scan complete" notification.
final scanCompleteCountProvider = StateProvider<int>((_) => 0);

// ── Derived providers ─────────────────────────────────────────────────────────

/// Last 20 songs played, sorted by lastPlayedAt descending.
final recentlyPlayedProvider = FutureProvider<List<Song>>((ref) async {
  final songs = await ref.watch(libraryProvider.future);
  final played = songs.where((s) => s.lastPlayedAt != null).toList()
    ..sort((a, b) => b.lastPlayedAt!.compareTo(a.lastPlayedAt!));
  return played.take(20).toList();
});

/// Up to 10 favorite songs.
final favoritesProvider = FutureProvider<List<Song>>((ref) async {
  final songs = await ref.watch(libraryProvider.future);
  return songs.where((s) => s.isFavorite).take(10).toList();
});

/// All albums derived from stored songs.
final albumsProvider = FutureProvider<List<Album>>((ref) {
  return ref.read(songRepositoryProvider).getAllAlbums();
});

/// All artists derived from stored songs.
final artistsProvider = FutureProvider<List<Artist>>((ref) {
  return ref.read(songRepositoryProvider).getAllArtists();
});
