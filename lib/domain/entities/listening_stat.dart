/// Represents a single listening event for stats tracking.
class ListeningStat {
  final int songId;
  final DateTime listenedAt;
  final int durationMs;

  const ListeningStat({required this.songId, required this.listenedAt, required this.durationMs});
}
