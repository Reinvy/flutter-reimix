import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local/objectbox_datasource.dart';
import '../../data/repositories_impl/playlist_repository_impl.dart';
import '../../domain/entities/playlist.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/playlist_repository.dart';
import '../../domain/usecases/create_playlist.dart';
import '../../domain/usecases/add_song_to_playlist.dart';
import '../../main.dart' show objectBox;

// ── Infrastructure providers ──────────────────────────────────────────────────

final _objectBoxProvider = Provider<ObjectBoxDatasource>((_) => objectBox);

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  return PlaylistRepositoryImpl(ref.read(_objectBoxProvider));
});

// ── Notifier ──────────────────────────────────────────────────────────────────

class PlaylistNotifier extends AsyncNotifier<List<Playlist>> {
  PlaylistRepository get _repo => ref.read(playlistRepositoryProvider);

  @override
  Future<List<Playlist>> build() => _repo.getAll();

  Future<void> create(String name, {String? coverImagePath}) async {
    final useCase = CreatePlaylist(_repo);
    await useCase(name, coverImagePath: coverImagePath);
    ref.invalidateSelf();
  }

  Future<void> addSong(int playlistId, Song song) async {
    final useCase = AddSongToPlaylist(_repo);
    await useCase(playlistId, song);
    ref.invalidateSelf();
  }

  Future<void> removeSong(int playlistId, int songId) async {
    await _repo.removeSong(playlistId, songId);
    ref.invalidateSelf();
  }

  Future<void> reorder(int playlistId, List<int> songIds) async {
    await _repo.reorder(playlistId, songIds);
    ref.invalidateSelf();
  }

  Future<void> delete(int playlistId) async {
    await _repo.delete(playlistId);
    ref.invalidateSelf();
  }
}

final playlistProvider = AsyncNotifierProvider<PlaylistNotifier, List<Playlist>>(
  PlaylistNotifier.new,
);
