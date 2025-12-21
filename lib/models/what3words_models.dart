import 'package:equatable/equatable.dart';

/// Validated what3words address with formatting utilities
///
/// Ensures format compliance and provides display/copy formatting.
/// Format: three lowercase words separated by dots (e.g., "slurs.this.name")
///
/// Constitutional compliance:
/// - C2: what3words addresses should NEVER be logged (privacy risk)
class What3wordsAddress extends Equatable {
  /// Raw words without prefix (e.g., "slurs.this.name")
  final String words;

  const What3wordsAddress._(this.words);

  /// Creates validated address, returns null if invalid format
  ///
  /// Accepts formats:
  /// - "word.word.word"
  /// - "/word.word.word"
  /// - "///word.word.word"
  static What3wordsAddress? tryParse(String input) {
    // Remove leading slashes and whitespace, convert to lowercase
    final cleaned =
        input.replaceAll(RegExp(r'^/{1,3}'), '').trim().toLowerCase();

    if (!_isValidFormat(cleaned)) return null;
    return What3wordsAddress._(cleaned);
  }

  /// Creates validated address, throws ArgumentError if invalid
  factory What3wordsAddress.parse(String input) {
    final result = tryParse(input);
    if (result == null) {
      throw ArgumentError('Invalid what3words format: $input');
    }
    return result;
  }

  /// Validates what3words format
  ///
  /// Rules:
  /// - Exactly 3 words separated by dots
  /// - Each word: 1-20 lowercase letters only
  /// - No numbers, hyphens, or special characters
  static bool _isValidFormat(String input) {
    final parts = input.split('.');
    if (parts.length != 3) return false;

    // Each word: 1-20 lowercase letters
    final wordPattern = RegExp(r'^[a-z]{1,20}$');
    return parts.every((p) => wordPattern.hasMatch(p));
  }

  /// Checks if a string looks like a what3words address
  ///
  /// Returns true if the input matches the expected format.
  /// Useful for detecting what3words input in search bars.
  static bool looksLikeWhat3words(String input) {
    final cleaned =
        input.replaceAll(RegExp(r'^/{1,3}'), '').trim().toLowerCase();
    return _isValidFormat(cleaned);
  }

  /// Display format with triple-slash prefix (///word.word.word)
  String get displayFormat => '///$words';

  /// Short format for copying to clipboard (word.word.word)
  String get copyFormat => words;

  @override
  List<Object> get props => [words];

  @override
  String toString() => displayFormat;
}

/// Error types for what3words service operations
///
/// Sealed class hierarchy for exhaustive pattern matching.
/// All errors provide a user-friendly message via [userMessage].
sealed class What3wordsError {
  const What3wordsError();

  /// Human-readable error message suitable for UI display
  String get userMessage;
}

/// API returned an error response
///
/// Covers cases like:
/// - Invalid API key
/// - Rate limit exceeded
/// - Invalid what3words address (not found)
/// - Server errors
class What3wordsApiError extends What3wordsError {
  /// Error code from API (e.g., "InvalidKey", "QuotaExceeded")
  final String code;

  /// Error message from API
  final String message;

  /// HTTP status code (if available)
  final int? statusCode;

  const What3wordsApiError({
    required this.code,
    required this.message,
    this.statusCode,
  });

  @override
  String get userMessage => switch (code) {
        'InvalidKey' => 'what3words service unavailable',
        'InvalidInput' => 'Invalid what3words address',
        'QuotaExceeded' => 'what3words limit reached, try again later',
        'BadWords' => 'what3words address not found',
        _ => 'what3words error: $message',
      };

  @override
  String toString() =>
      'What3wordsApiError(code: $code, message: $message, statusCode: $statusCode)';
}

/// Network or connectivity error
///
/// Covers cases like:
/// - No internet connection
/// - DNS resolution failure
/// - Connection timeout
/// - Server unreachable
class What3wordsNetworkError extends What3wordsError {
  /// Optional technical details (not shown to user)
  final String? details;

  const What3wordsNetworkError([this.details]);

  @override
  String get userMessage => 'Unable to reach what3words service';

  @override
  String toString() => 'What3wordsNetworkError(details: $details)';
}

/// Invalid address format (client-side validation failure)
///
/// Returned when input doesn't match what3words format
/// before making an API call.
class What3wordsInvalidAddressError extends What3wordsError {
  /// The invalid input that was provided
  final String input;

  const What3wordsInvalidAddressError(this.input);

  @override
  String get userMessage => 'Invalid what3words format';

  @override
  String toString() => 'What3wordsInvalidAddressError(input: $input)';
}
