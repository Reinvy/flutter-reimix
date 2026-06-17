import '../entities/playlist.dart';
import '../repositories/playlist_repository.dart';

/// Creates a new user playlist after validating the name.
class CreatePlaylist {
  final PlaylistRepository _repository;

  const CreatePlaylist(this._repository);

  /// Returns the created [Playlist].
  ///
  /// Throws [ArgumentError] if [name] is empty or exceeds 60 characters.
  Future<Playlist> call(String name, {String? coverImagePath}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('Playlist name cannot be empty.');
    if (trimmed.length > 60) throw ArgumentError('Playlist name must be ≤ 60 characters.');
    return _repository.create(trimmed, coverImagePath: coverImagePath);
  }
}
