import '../entities/song.dart';
import '../repositories/song_repository.dart';

/// Use-case: retrieve all songs by a specific artist.
class GetSongsByArtist {
  final SongRepository _repository;

  const GetSongsByArtist(this._repository);

  Future<List<Song>> call(String artist) => _repository.getSongsByArtist(artist);
}
