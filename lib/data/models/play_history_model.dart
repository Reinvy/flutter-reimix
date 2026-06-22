import 'package:objectbox/objectbox.dart';
import 'song_model.dart';

@Entity()
class PlayHistoryModel {
  @Id()
  int id = 0;

  final song = ToOne<SongModel>();

  @Property(type: PropertyType.date)
  late DateTime timestamp;

  late int durationMs;
}
