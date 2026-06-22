import '../entities/play_history.dart';

/// Abstract contract for listening statistics and app settings persistence.
abstract class StatsRepository {
  /// Records a listen event: increments playCount, accumulates [durationMs],
  /// and updates lastPlayedAt for the song with [songId].
  Future<void> recordListen({required int songId, required int durationMs});

  /// Retrieves the complete list of play history logs.
  Future<List<PlayHistory>> getPlayHistory();

  /// Watches for changes in the play history.
  Stream<List<PlayHistory>> watchPlayHistory();
}
