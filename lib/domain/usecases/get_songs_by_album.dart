import '../entities/song.dart';
import '../repositories/song_repository.dart';

/// Use-case: retrieve all songs belonging to a specific album.
class GetSongsByAlbum {
  final SongRepository _repository;

  const GetSongsByAlbum(this._repository);

  Future<List<Song>> call(String album) => _repository.getSongsByAlbum(album);
}
