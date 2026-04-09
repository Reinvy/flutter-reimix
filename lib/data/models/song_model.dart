import 'package:objectbox/objectbox.dart';

@Entity()
class SongModel {
  @Id()
  int id = 0;

  late String filePath;
  late String title;
  String? artist;
  String? album;
  String? genre;
  int? year;
  int? trackNumber;
  late int durationMs;
  String? albumArtPath;
  bool isFavorite = false;
  int playCount = 0;

  @Property(type: PropertyType.date)
  DateTime? lastPlayedAt;

  int totalListenedMs = 0;

  @Property(type: PropertyType.date)
  late DateTime dateAdded;
}
