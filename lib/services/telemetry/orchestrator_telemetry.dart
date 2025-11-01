/// Telemetry interface for FireRiskService orchestration monitoring
///
/// Provides hooks for measuring service attempt timing, fallback depth tracking,
/// and overall orchestration performance. Designed for minimal overhead while
/// enabling observability into the fallback chain behavior.
library orchestrator_telemetry;

/// Data source identifier for telemetry tracking
enum TelemetrySource {
  effis('EFFIS'),
  sepa('SEPA'),
  cache('Cache'),
  mock('Mock');

  const TelemetrySource(this.displayName);
  final String displayName;
}

/// Interface for orchestrator telemetry collection
///
/// Implementations can provide logging, metrics collection, or testing spies.
/// All methods are designed to be non-blocking and should not throw exceptions
/// that could disrupt the orchestration flow.
///
/// Example implementation:
/// ```dart
/// class LoggingTelemetry implements OrchestratorTelemetry {
///   @override
///   void onAttemptStart(TelemetrySource source) {
///     print('Attempting ${source.displayName}...');
///   }
///
///   @override
///   void onAttemptEnd(TelemetrySource source, Duration elapsed, bool success) {
///     print('${source.displayName}: ${elapsed.inMilliseconds}ms, success: $success');
///   }
/// }
/// ```
abstract class OrchestratorTelemetry {
  /// Called when starting an attempt to fetch data from a service
  ///
  /// [source] identifies which service is being attempted (EFFIS, SEPA, etc.)
  void onAttemptStart(TelemetrySource source);

  /// Called when a service attempt completes (success or failure)
  ///
  /// [source] identifies which service was attempted
  /// [elapsed] is the time taken for the attempt
  /// [success] indicates whether the attempt returned usable data
  void onAttemptEnd(TelemetrySource source, Duration elapsed, bool success);

  /// Called when the orchestrator advances to the next fallback level
  ///
  /// [depth] indicates fallback depth:
  /// - 0: Primary attempt (EFFIS)
  /// - 1: First fallback (SEPA for Scotland, Cache otherwise)
  /// - 2: Second fallback (Cache after SEPA failure)
  /// - 3: Final fallback (Mock)
  void onFallbackDepth(int depth);

  /// Called when orchestration completes with final result
  ///
  /// [chosenSource] indicates which service provided the final result
  /// [totalElapsed] is the total time from request start to completion
  void onComplete(TelemetrySource chosenSource, Duration totalElapsed);
}

/// No-op telemetry implementation for production use when telemetry is disabled
class NoOpTelemetry implements OrchestratorTelemetry {
  const NoOpTelemetry();

  @override
  void onAttemptStart(TelemetrySource source) {
    // No-op
  }

  @override
  void onAttemptEnd(TelemetrySource source, Duration elapsed, bool success) {
    // No-op
  }

  @override
  void onFallbackDepth(int depth) {
    // No-op
  }

  @override
  void onComplete(TelemetrySource chosenSource, Duration totalElapsed) {
    // No-op
  }
}

/// Test spy implementation for verifying orchestration behavior in tests
class SpyTelemetry implements OrchestratorTelemetry {
  final List<TelemetryEvent> events = [];

  @override
  void onAttemptStart(TelemetrySource source) {
    events.add(AttemptStartEvent(source, DateTime.now()));
  }

  @override
  void onAttemptEnd(TelemetrySource source, Duration elapsed, bool success) {
    events.add(AttemptEndEvent(source, elapsed, success, DateTime.now()));
  }

  @override
  void onFallbackDepth(int depth) {
    events.add(FallbackDepthEvent(depth, DateTime.now()));
  }

  @override
  void onComplete(TelemetrySource chosenSource, Duration totalElapsed) {
    events.add(CompleteEvent(chosenSource, totalElapsed, DateTime.now()));
  }

  /// Clears recorded events (useful for test setup)
  void clear() {
    events.clear();
  }

  /// Returns all events of a specific type
  List<T> eventsOfType<T extends TelemetryEvent>() {
    return events.whereType<T>().toList();
  }
}

/// Base class for telemetry events
abstract class TelemetryEvent {
  final DateTime timestamp;
  const TelemetryEvent(this.timestamp);
}

/// Event fired when a service attempt begins
class AttemptStartEvent extends TelemetryEvent {
  final TelemetrySource source;
  const AttemptStartEvent(this.source, DateTime timestamp) : super(timestamp);

  @override
  String toString() => 'AttemptStart(${source.displayName})';
}

/// Event fired when a service attempt completes
class AttemptEndEvent extends TelemetryEvent {
  final TelemetrySource source;
  final Duration elapsed;
  final bool success;

  const AttemptEndEvent(
    this.source,
    this.elapsed,
    this.success,
    DateTime timestamp,
  ) : super(timestamp);

  @override
  String toString() =>
      'AttemptEnd(${source.displayName}, ${elapsed.inMilliseconds}ms, $success)';
}

/// Event fired when fallback depth increases
class FallbackDepthEvent extends TelemetryEvent {
  final int depth;
  const FallbackDepthEvent(this.depth, DateTime timestamp) : super(timestamp);

  @override
  String toString() => 'FallbackDepth($depth)';
}

/// Event fired when orchestration completes
class CompleteEvent extends TelemetryEvent {
  final TelemetrySource chosenSource;
  final Duration totalElapsed;

  const CompleteEvent(this.chosenSource, this.totalElapsed, DateTime timestamp)
    : super(timestamp);

  @override
  String toString() =>
      'Complete(${chosenSource.displayName}, ${totalElapsed.inMilliseconds}ms)';
}
