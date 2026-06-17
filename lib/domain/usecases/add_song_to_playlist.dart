import '../entities/song.dart';
import '../repositories/playlist_repository.dart';

/// Adds a [Song] to an existing playlist.
class AddSongToPlaylist {
  final PlaylistRepository _repository;

  const AddSongToPlaylist(this._repository);

  Future<void> call(int playlistId, Song song) {
    return _repository.addSong(playlistId, song);
  }
}
