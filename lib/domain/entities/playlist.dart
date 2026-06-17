import 'song.dart';

/// Pure domain entity representing a playlist.
class Playlist {
  final int id;
  final String name;
  final String? coverImagePath;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isSmartPlaylist;
  final String? smartPlaylistType;
  final List<Song> songs;

  const Playlist({
    required this.id,
    required this.name,
    this.coverImagePath,
    required this.createdAt,
    this.updatedAt,
    this.isSmartPlaylist = false,
    this.smartPlaylistType,
    this.songs = const [],
  });

  Playlist copyWith({
    int? id,
    String? name,
    String? coverImagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSmartPlaylist,
    String? smartPlaylistType,
    List<Song>? songs,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSmartPlaylist: isSmartPlaylist ?? this.isSmartPlaylist,
      smartPlaylistType: smartPlaylistType ?? this.smartPlaylistType,
      songs: songs ?? this.songs,
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other) || (other is Playlist && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
