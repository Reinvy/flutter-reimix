/// Typed exception hierarchy for all Reimix error scenarios.
library;

/// Base class for all application-specific exceptions.
abstract class AppException implements Exception {
  final String message;
  final Object? cause;

  const AppException(this.message, {this.cause});

  @override
  String toString() => '$runtimeType: $message${cause != null ? '\n  Caused by: $cause' : ''}';
}

/// Thrown when audio playback fails (file not found, codec error, etc.)
class AudioException extends AppException {
  const AudioException(super.message, {super.cause});
}

/// Thrown when file-system or storage operations fail.
class StorageException extends AppException {
  const StorageException(super.message, {super.cause});
}

/// Thrown when ObjectBox/database operations fail.
class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.cause});
}

/// Thrown when the app lacks required system permissions.
class PermissionException extends AppException {
  const PermissionException(super.message, {super.cause});
}
