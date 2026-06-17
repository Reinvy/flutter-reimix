import '../entities/song.dart';
import '../repositories/song_repository.dart';

/// Use-case: toggle the favorite flag on a song.
class ToggleFavorite {
  final SongRepository _repository;

  const ToggleFavorite(this._repository);

  Future<Song> call(int songId) => _repository.toggleFavorite(songId);
}
