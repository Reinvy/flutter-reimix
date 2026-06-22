import '../../domain/entities/play_history.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/stats_repository.dart';
import '../datasources/local/objectbox_datasource.dart';
import '../models/play_history_model.dart';
import '../models/song_model.dart';

/// Concrete implementation of [StatsRepository] backed by ObjectBox.
class StatsRepositoryImpl implements StatsRepository {
  final ObjectBoxDatasource _db;

  StatsRepositoryImpl(this._db);

  Song _toSongEntity(SongModel m) => Song(
        id: m.id,
        filePath: m.filePath,
        title: m.title,
        artist: m.artist,
        album: m.album,
        genre: m.genre,
        year: m.year,
        trackNumber: m.trackNumber,
        durationMs: m.durationMs,
        albumArtPath: m.albumArtPath,
        isFavorite: m.isFavorite,
        playCount: m.playCount,
        lastPlayedAt: m.lastPlayedAt,
        totalListenedMs: m.totalListenedMs,
        dateAdded: m.dateAdded,
      );

  PlayHistory _toPlayHistoryEntity(PlayHistoryModel m) {
    final songModel = m.song.target;
    final songEntity = songModel != null
        ? _toSongEntity(songModel)
        : Song(
            id: 0,
            filePath: '',
            title: 'Unknown Song',
            durationMs: 0,
            dateAdded: DateTime.now(),
          );
    return PlayHistory(
      id: m.id,
      song: songEntity,
      timestamp: m.timestamp,
      durationMs: m.durationMs,
    );
  }

  @override
  Future<void> recordListen({required int songId, required int durationMs}) async {
    final song = _db.songBox.get(songId);
    if (song == null) return;
    
    // Update Song's aggregate stats
    song.playCount += 1;
    song.totalListenedMs += durationMs;
    song.lastPlayedAt = DateTime.now();
    _db.songBox.put(song);

    // Save individual Play History record
    final history = PlayHistoryModel()
      ..timestamp = DateTime.now()
      ..durationMs = durationMs;
    history.song.target = song;
    _db.playHistoryBox.put(history);
  }

  @override
  Future<List<PlayHistory>> getPlayHistory() async {
    final models = _db.playHistoryBox.getAll();
    return models.map(_toPlayHistoryEntity).toList();
  }

  @override
  Stream<List<PlayHistory>> watchPlayHistory() {
    return _db.playHistoryBox
        .query()
        .watch(triggerImmediately: true)
        .map((query) => query.find().map(_toPlayHistoryEntity).toList());
  }
}
