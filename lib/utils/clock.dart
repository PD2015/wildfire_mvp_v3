/// Clock abstraction for testable time operations
///
/// Provides deterministic time for TTL calculations in cache operations.
/// Use SystemClock in production, FakeClock in tests.
abstract class Clock {
  /// Get current UTC time
  ///
  /// Returns current time in UTC timezone for consistent TTL calculations
  /// across different system timezones.
  DateTime nowUtc();
}

/// Production clock implementation using system time
class SystemClock implements Clock {
  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}
