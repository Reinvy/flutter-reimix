/// Formats a [Duration] into a human-readable string.
///
/// Returns `"h:mm:ss"` when the duration is one hour or longer,
/// otherwise returns `"m:ss"`.
///
/// Examples:
/// - 0 s  → "0:00"
/// - 90 s → "1:30"
/// - 1h 5m 7s → "1:05:07"
String formatDuration(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);
  final seconds = d.inSeconds.remainder(60);

  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');

  if (hours > 0) {
    return '$hours:$mm:$ss';
  }
  return '$minutes:$ss';
}
