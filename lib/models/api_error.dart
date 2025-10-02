import 'package:equatable/equatable.dart';

/// Categorizes different types of API errors for better error handling
enum ApiErrorReason {
  notFound,
  serviceUnavailable,
  general,
}

/// Represents an error from the EFFIS API with categorized reason codes
/// 
/// Provides structured error information with automatic categorization
/// based on HTTP status codes per docs/data-model.md:
/// - 404 → notFound
/// - 503 → serviceUnavailable  
/// - Other codes → general
class ApiError extends Equatable {
  final String message;
  final int? statusCode;
  final ApiErrorReason reason;

  /// Creates an ApiError with automatic reason categorization
  /// 
  /// [message] must be non-empty. [statusCode] can be null for non-HTTP errors.
  /// [reason] is automatically determined from [statusCode] if not provided.
  ApiError({
    required this.message,
    this.statusCode,
    ApiErrorReason? reason,
  }) : reason = reason ?? _categorizeError(statusCode) {
    if (message.isEmpty) {
      throw ArgumentError('Error message cannot be empty');
    }
  }

  /// Categorizes error based on HTTP status code
  static ApiErrorReason _categorizeError(int? statusCode) {
    switch (statusCode) {
      case 404:
        return ApiErrorReason.notFound;
      case 503:
        return ApiErrorReason.serviceUnavailable;
      default:
        return ApiErrorReason.general;
    }
  }

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiError($statusCode): $message';
    } else {
      return 'ApiError: $message';
    }
  }

  @override
  List<Object?> get props => [message, statusCode, reason];
}