import 'package:equatable/equatable.dart';

/// Base class for cache operation errors
///
/// Provides type-safe error handling for cache operations with
/// specific error categories for proper error recovery.
sealed class CacheError extends Equatable {
  const CacheError();
}

/// Error accessing underlying storage system (SharedPreferences)
class StorageError extends CacheError {
  const StorageError(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  List<Object?> get props => [message, cause];

  @override
  String toString() =>
      'StorageError: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Error serializing/deserializing cache entry data
class SerializationError extends CacheError {
  const SerializationError(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  List<Object?> get props => [message, cause];

  @override
  String toString() =>
      'SerializationError: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Cache entry has unsupported version format
class UnsupportedVersionError extends CacheError {
  const UnsupportedVersionError(this.version);

  final String version;

  @override
  List<Object?> get props => [version];

  @override
  String toString() =>
      'UnsupportedVersionError: version "$version" is not supported';
}
