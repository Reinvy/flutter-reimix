/// Pure domain entity representing a music album.
class Album {
  final String name;
  final String? artist;
  final String? artPath;
  final int songCount;

  const Album({required this.name, this.artist, this.artPath, required this.songCount});

  Album copyWith({String? name, String? artist, String? artPath, int? songCount}) {
    return Album(
      name: name ?? this.name,
      artist: artist ?? this.artist,
      artPath: artPath ?? this.artPath,
      songCount: songCount ?? this.songCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Album && other.name == name);

  @override
  int get hashCode => name.hashCode;
}
