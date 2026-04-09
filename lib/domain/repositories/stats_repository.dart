/// Abstract contract for listening statistics and app settings persistence.
abstract class StatsRepository {
  /// Records a listen event: increments playCount, accumulates [durationMs],
  /// and updates lastPlayedAt for the song with [songId].
  Future<void> recordListen({required int songId, required int durationMs});
}
