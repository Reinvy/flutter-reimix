import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/app_exceptions.dart';
import 'player_provider.dart';

/// Represents a single logged error entry.
class ErrorLogEntry {
  final DateTime timestamp;
  final String message;
  final String? details;

  ErrorLogEntry({
    required this.timestamp,
    required this.message,
    this.details,
  });
}

/// A notifier that manages in-memory error logs.
class ErrorLogNotifier extends StateNotifier<List<ErrorLogEntry>> {
  ErrorLogNotifier() : super([]);

  /// Appends a new error entry to the log.
  void logError(String message, {String? details}) {
    state = [
      ...state,
      ErrorLogEntry(
        timestamp: DateTime.now(),
        message: message,
        details: details,
      ),
    ];
  }

  /// Clears all error logs.
  void clearLogs() {
    state = [];
  }
}

/// Provider for the list of error log entries.
/// Listen/read this provider to display or modify logged errors.
final errorLogProvider = StateNotifierProvider<ErrorLogNotifier, List<ErrorLogEntry>>((ref) {
  final notifier = ErrorLogNotifier();

  // Automatically listen to the audio error stream and log playback exceptions.
  ref.listen<AsyncValue<AudioException>>(audioErrorStreamProvider, (previous, next) {
    next.whenData((error) {
      notifier.logError(
        error.message,
        details: error.cause?.toString(),
      );
    });
  });

  return notifier;
});
