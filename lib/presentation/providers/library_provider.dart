import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local/media_store_datasource.dart';
import '../../data/datasources/local/objectbox_datasource.dart';
import '../../data/repositories_impl/song_repository_impl.dart';
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
  }
}

final libraryProvider = AsyncNotifierProvider<LibraryNotifier, List<Song>>(LibraryNotifier.new);
