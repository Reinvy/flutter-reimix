import 'song.dart';

/// Pure domain entity representing a single play log.
class PlayHistory {
  final int id;
  final Song song;
  final DateTime timestamp;
  final int durationMs;

  const PlayHistory({
    required this.id,
    required this.song,
    required this.timestamp,
    required this.durationMs,
  });

  PlayHistory copyWith({
    int? id,
    Song? song,
    DateTime? timestamp,
    int? durationMs,
  }) {
    return PlayHistory(
      id: id ?? this.id,
      song: song ?? this.song,
      timestamp: timestamp ?? this.timestamp,
      durationMs: durationMs ?? this.durationMs,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is PlayHistory && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
