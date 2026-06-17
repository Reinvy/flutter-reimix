import '../../domain/repositories/stats_repository.dart';
import '../datasources/local/objectbox_datasource.dart';

/// Concrete implementation of [StatsRepository] backed by ObjectBox.
class StatsRepositoryImpl implements StatsRepository {
  final ObjectBoxDatasource _db;

  StatsRepositoryImpl(this._db);

  @override
  Future<void> recordListen({required int songId, required int durationMs}) async {
    final song = _db.songBox.get(songId);
    if (song == null) return;
    song.playCount += 1;
    song.totalListenedMs += durationMs;
    song.lastPlayedAt = DateTime.now();
    _db.songBox.put(song);
  }
}
