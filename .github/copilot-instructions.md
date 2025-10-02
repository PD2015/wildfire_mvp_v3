# wildfire_mvp_v3 Development Guidelines

Auto-generated from all feature plans. Last updated: 2025-10-02

## Active Technologies
- Dart 3.0+ with Flutter SDK + http package, dartz (Either type), equatable (value objects) (001-spec-a1-effisservice)
- Dart 3.0+ with Flutter SDK + flutter_bloc, equatable, http (inherited from A2), dartz (Either type from A2) (003-a3-riskbanner-home)
- N/A (widget consumes A2 FireRiskService data) (003-a3-riskbanner-home)

## Project Structure
```
src/
tests/
```

## Commands
# Add commands for Dart 3.0+ with Flutter SDK

## Code Style
Dart 3.0+ with Flutter SDK: Follow standard conventions

## Recent Changes
- 003-a3-riskbanner-home: Added Dart 3.0+ with Flutter SDK + flutter_bloc, equatable, http (inherited from A2), dartz (Either type from A2)
- 001-spec-a1-effisservice: Added Dart 3.0+ with Flutter SDK + http package, dartz (Either type), equatable (value objects)
- 002-spec-a2-fireriskservice: Added FireRiskService orchestration with fallback chain, geographic utilities, telemetry, privacy compliance

## FireRiskService Implementation Patterns

### Orchestration Service Architecture
```dart
// Dependency injection with optional services
FireRiskServiceImpl({
  required EffisService effisService,     // A1 implementation - always required
  SepaService? sepaService,               // Optional Scotland-specific service
  CacheService? cacheService,             // Optional caching layer
  required MockService mockService,       // Required never-fail fallback
  OrchestratorTelemetry? telemetry,       // Optional observability
});
```

### Testing Orchestration Services
Use controllable mocks for integration testing:
```dart
// Setup controllable timing and failures
when(mockEffisService.getFwi(lat: anyNamed('lat'), lon: anyNamed('lon')))
  .thenAnswer((_) async {
    await Future.delayed(Duration(milliseconds: 800)); // Simulate network
    return Left(ApiError(message: 'Service unavailable'));
  });

// Verify exact fallback sequence with SpyTelemetry
final telemetry = SpyTelemetry();
final service = FireRiskServiceImpl(..., telemetry: telemetry);

await service.getCurrent(lat: lat, lon: lon);

final attempts = telemetry.eventsOfType<AttemptStartEvent>();
expect(attempts.map((e) => e.source), [
  TelemetrySource.effis,
  TelemetrySource.sepa,  // Only if Scotland coordinates
  TelemetrySource.cache, // Only if cache service provided
  TelemetrySource.mock,  // Always final fallback
]);
```

### Privacy-Compliant Logging
Always use coordinate redaction in logs:
```dart
// CORRECT: Privacy-preserving logging
_logger.info('Attempting EFFIS for ${GeographicUtils.logRedact(lat, lon)}');
// Outputs: "Attempting EFFIS for 55.95,-3.19"

// WRONG: Raw coordinates expose PII
_logger.info('Attempting EFFIS for $lat,$lon'); // Violates C2 gate
```

### Geographic Boundary Testing
Test Scotland boundary detection with edge cases:
```dart
// Major cities
expect(GeographicUtils.isInScotland(55.9533, -3.1883), isTrue);  // Edinburgh
expect(GeographicUtils.isInScotland(51.5074, -0.1278), isFalse); // London

// Boundary edge cases  
expect(GeographicUtils.isInScotland(54.6, -4.0), isTrue);   // Exact boundary
expect(GeographicUtils.isInScotland(57.8, -8.6), isTrue);   // St Kilda
expect(GeographicUtils.isInScotland(60.9, -1.0), isTrue);   // Shetland
```

### Stable Dependency Contracts
Define clear interfaces for orchestrated services:
```dart
abstract class EffisService { 
  Future<Either<ApiError, EffisFwiResult>> getFwi({required double lat, required double lon});
}

abstract class SepaService {
  Future<Either<ApiError, FireRisk>> getCurrent({required double lat, required double lon});
}

abstract class CacheService {
  Future<Option<FireRisk>> get({required String key});
  Future<void> set({required String key, required FireRisk value, Duration ttl});
}
```

<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
