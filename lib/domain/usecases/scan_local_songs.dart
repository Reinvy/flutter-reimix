import '../entities/song.dart';
import '../repositories/song_repository.dart';

/// Use-case: scan the device MediaStore, persist new songs, and return the
/// complete library.
class ScanLocalSongs {
  final SongRepository _repository;

  const ScanLocalSongs(this._repository);

  Future<List<Song>> call() => _repository.scanAndSave();
}
