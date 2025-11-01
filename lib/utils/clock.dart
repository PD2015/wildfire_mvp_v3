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

/// Test clock implementation with controllable time for testing
///
/// Allows tests to control time progression and verify TTL behavior
/// deterministically without waiting for actual time to pass.
class TestClock implements Clock {
  DateTime _currentTime;

  TestClock({DateTime? initialTime})
      : _currentTime = (initialTime ?? DateTime.now()).toUtc();

  @override
  DateTime nowUtc() => _currentTime;

  /// Advance the clock by a duration
  void advance(Duration duration) {
    _currentTime = _currentTime.add(duration);
  }

  /// Set the clock to a specific time
  void setTime(DateTime time) {
    _currentTime = time.toUtc();
  }
}
