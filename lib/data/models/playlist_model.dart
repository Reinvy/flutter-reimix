import 'package:objectbox/objectbox.dart';
import 'song_model.dart';

@Entity()
class PlaylistModel {
  @Id()
  int id = 0;

  late String name;
  String? coverImagePath;

  @Property(type: PropertyType.date)
  late DateTime createdAt;

  @Property(type: PropertyType.date)
  DateTime? updatedAt;

  bool isSmartPlaylist = false;

  /// 'recently_played' | 'most_played' | 'favorites'
  String? smartPlaylistType;

  final songs = ToMany<SongModel>();

  /// Ordered list of SongModel ids for manual ordering
  // Stored as comma-separated string because ObjectBox doesn't support List<int> natively
  String songOrderRaw = '';

  @Transient()
  List<int> get songOrder =>
      songOrderRaw.isEmpty ? [] : songOrderRaw.split(',').map(int.parse).toList();

  @Transient()
  set songOrder(List<int> value) {
    songOrderRaw = value.join(',');
  }
}
