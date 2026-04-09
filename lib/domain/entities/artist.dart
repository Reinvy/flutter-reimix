/// Pure domain entity representing a music artist.
class Artist {
  final String name;
  final int songCount;

  const Artist({required this.name, required this.songCount});

  Artist copyWith({String? name, int? songCount}) {
    return Artist(name: name ?? this.name, songCount: songCount ?? this.songCount);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Artist && other.name == name);

  @override
  int get hashCode => name.hashCode;
}
