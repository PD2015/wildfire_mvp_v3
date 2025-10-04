# GeohashUtils Interface Contract

**Feature**: A5 CacheService with 6-hour TTL and geohash-based spatial keying  
**Contract Date**: 2025-10-04  
**Context**: Geospatial utilities for cache key generation and coordinate privacy

---

## Core Interface

```dart
/// Geohash utilities for spatial cache key generation
class GeohashUtils {
  /// Encode coordinates to geohash string
  /// 
  /// Parameters:
  /// - lat: Latitude in decimal degrees (-90 to 90)
  /// - lon: Longitude in decimal degrees (-180 to 180)  
  /// - precision: Geohash character count (default: 5 for ~4.9km)
  /// 
  /// Returns: Geohash string (e.g., "gcpue" for Edinburgh)
  /// 
  /// Performance: <10ms for precision ≤ 12
  static String encode(double lat, double lon, {int precision = 5});

  /// Decode geohash to coordinate bounds
  /// 
  /// Parameters:
  /// - geohash: Geohash string to decode
  /// 
  /// Returns: Bounding box containing all coordinates that encode to this geohash
  /// 
  /// Performance: <5ms for any precision
  static GeohashBounds bounds(String geohash);

  /// Decode geohash to center coordinates
  /// 
  /// Parameters:
  /// - geohash: Geohash string to decode
  /// 
  /// Returns: Center point of geohash bounding box
  /// 
  /// Performance: <5ms for any precision
  static LatLng center(String geohash);

  /// Get neighboring geohashes for spatial queries
  /// 
  /// Parameters:
  /// - geohash: Center geohash
  /// 
  /// Returns: List of 8 neighboring geohashes (N, NE, E, SE, S, SW, W, NW)
  /// 
  /// Use case: Expanding cache search to nearby areas
  static List<String> neighbors(String geohash);

  /// Validate geohash format
  /// 
  /// Parameters:
  /// - geohash: String to validate
  /// 
  /// Returns: true if valid geohash format
  /// 
  /// Validation: Only base32 characters (0-9, b-z excluding a, i, l, o)
  static bool isValid(String geohash);

  /// Calculate resolution of geohash precision
  /// 
  /// Parameters:
  /// - precision: Geohash character count
  /// 
  /// Returns: Approximate resolution in kilometers
  static double resolutionKm(int precision);
}
```

---

## Precision Specifications

### Resolution Table
```dart
/// Geohash precision to resolution mapping
class GeohashPrecisionSpecs {
  static const Map<int, double> resolutionKm = {
    1: 5003.530,  // ±2500km
    2: 625.441,   // ±313km  
    3: 156.360,   // ±78km
    4: 19.545,    // ±10km
    5: 4.886,     // ±2.4km  ← Cache default
    6: 0.611,     // ±305m
    7: 0.153,     // ±76m
    8: 0.019,     // ±10m
    9: 0.005,     // ±2m
    10: 0.0006,   // ±30cm
  };
  
  // Cache service uses precision 5 for optimal spatial clustering
  static const int cacheServicePrecision = 5;
  static const double cacheServiceResolutionKm = 4.886;
}
```

### Character Set Specification
```dart
/// Geohash base32 character set (excludes a, i, l, o to avoid confusion)
class GeohashCharacterSet {
  static const String validChars = '0123456789bcdefghjkmnpqrstuvwxyz';
  static const Set<String> validCharSet = {
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
    'b', 'c', 'd', 'e', 'f', 'g', 'h', 'j', 'k', 'm',
    'n', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
  };
  
  // Invalid characters that may appear in corrupted data
  static const Set<String> invalidChars = {'a', 'i', 'l', 'o'};
}
```

---

## Implementation Contracts

### Encoding Algorithm Contract
```dart
/// Contract for geohash encoding implementation
class GeohashEncodingContract {
  // Must use standard geohash algorithm (Gustavo Niemeyer)
  static const bool useStandardAlgorithm = true;
  
  // Must handle edge cases correctly
  static const bool handlePoleCoordinates = true;  // lat = ±90
  static const bool handleMeridianCrossing = true; // lon = ±180
  static const bool handleEquatorCrossing = true;  // lat = 0
  static const bool handlePrimeMeridian = true;    // lon = 0
  
  // Must maintain precision consistency
  static const bool precisionDeterministic = true;
  static const bool sameInputSameOutput = true;
  
  // Must validate input ranges
  static const bool validateLatitudeRange = true;  // -90 to 90
  static const bool validateLongitudeRange = true; // -180 to 180
  static const bool validatePrecisionRange = true; // 1 to 12
}
```

### Performance Contracts
```dart
/// Performance requirements for geohash operations
class GeohashPerformanceContract {
  // Encoding performance requirements
  static const Duration maxEncodeTime = Duration(milliseconds: 10);
  static const Duration maxDecodeTime = Duration(milliseconds: 5);
  static const Duration maxNeighborsTime = Duration(milliseconds: 15);
  
  // Memory usage constraints
  static const int maxMemoryUsageBytes = 1024; // 1KB per operation
  static const bool noMemoryLeaks = true;
  
  // Batch operation efficiency
  static const int minBatchThroughput = 1000; // operations per second
}
```

### Accuracy Contracts
```dart
/// Accuracy guarantees for geohash operations
class GeohashAccuracyContract {
  // Encoding accuracy requirements
  static const double maxCoordinateError = 0.0001; // ~11 meters at equator
  static const bool roundTripAccuracy = true; // encode → decode → encode stable
  
  // Bounds calculation accuracy
  static const bool boundsContainOriginal = true;
  static const bool centerWithinBounds = true;
  
  // Neighbor calculation accuracy  
  static const bool neighborsAdjacent = true;
  static const int expectedNeighborCount = 8;
}
```

---

## Error Handling Contracts

### Input Validation Errors
```dart
/// Error types for invalid geohash operations
sealed class GeohashError extends Equatable {
  const GeohashError();
}

class InvalidCoordinateError extends GeohashError {
  const InvalidCoordinateError(this.coordinate, this.value, this.validRange);
  
  final String coordinate; // 'latitude' or 'longitude'
  final double value;
  final String validRange;
  
  @override
  String toString() => 'Invalid $coordinate: $value (valid range: $validRange)';
  
  @override
  List<Object?> get props => [coordinate, value, validRange];
}

class InvalidPrecisionError extends GeohashError {
  const InvalidPrecisionError(this.precision);
  
  final int precision;
  
  @override
  String toString() => 'Invalid precision: $precision (valid range: 1-12)';
  
  @override
  List<Object?> get props => [precision];
}

class InvalidGeohashError extends GeohashError {
  const InvalidGeohashError(this.geohash, this.reason);
  
  final String geohash;
  final String reason;
  
  @override
  String toString() => 'Invalid geohash: "$geohash" ($reason)';
  
  @override
  List<Object?> get props => [geohash, reason];
}
```

### Error Handling Requirements
```dart
/// Error handling contracts for geohash utilities
class GeohashErrorHandlingContract {
  // Must validate all inputs before processing
  static const bool inputValidationRequired = true;
  
  // Must provide clear error messages
  static const bool descriptiveErrorMessages = true;
  
  // Must not throw exceptions for expected errors
  static const bool useResultTypes = true; // Either<GeohashError, T>
  
  // Must handle edge cases gracefully
  static const bool gracefulEdgeCaseHandling = true;
}
```

---

## Testing Contracts

### Unit Test Requirements
```dart
/// Unit test requirements for geohash utilities
class GeohashTestContract {
  // Minimum test coverage
  static const double minCoverage = 100.0; // Utility functions must be fully tested
  
  // Required test scenarios
  static const List<String> requiredScenarios = [
    'encode_valid_coordinates',
    'encode_edge_cases_poles',
    'encode_edge_cases_meridian', 
    'encode_precision_consistency',
    'decode_bounds_accuracy',
    'decode_center_accuracy',
    'neighbors_completeness',
    'neighbors_adjacency',
    'validate_format_correctly',
    'round_trip_stability',
    'performance_requirements',
    'invalid_input_handling',
  ];
  
  // Property-based testing requirements
  static const bool propertyBasedTestsRequired = true;
  static const int minPropertyTestCases = 1000;
}
```

### Benchmark Requirements
```dart
/// Performance benchmark requirements
class GeohashBenchmarkContract {
  // Must measure performance across precision levels
  static const List<int> benchmarkPrecisions = [1, 3, 5, 7, 9, 12];
  
  // Must test with realistic coordinate distributions
  static const List<String> coordinateDistributions = [
    'uniform_global',      // Random global coordinates
    'clustered_urban',     // Major city coordinates  
    'scotland_focused',    // Scotland region coordinates
    'edge_cases',          // Poles, meridian, equator
  ];
  
  // Must validate performance regression
  static const bool regressionTestingRequired = true;
  static const double maxPerformanceRegression = 0.10; // 10% slower than baseline
}
```

---

## Integration Contracts

### Cache Service Integration
```dart
/// Contract for CacheService integration
class GeohashCacheIntegrationContract {
  // Must generate deterministic cache keys
  static const bool deterministicKeyGeneration = true;
  
  // Must use consistent precision (5 characters)
  static const int cacheServicePrecision = 5;
  
  // Must handle coordinate privacy requirements
  static const bool coordinatePrivacyCompliant = true;
  
  // Must integrate with LocationUtils.logRedact
  static const bool locationUtilsCompatible = true;
}
```

### Privacy Compliance Integration
```dart
/// Privacy compliance for coordinate handling
class GeohashPrivacyContract {
  // Geohash keys provide inherent privacy (4.9km resolution)
  static const double privacyResolutionKm = 4.9;
  static const bool coordinatesObfuscated = true;
  
  // Must not log raw coordinates
  static const bool rawCoordinateLoggingProhibited = true;
  
  // Must support coordinate redaction in logs
  static const bool logRedactionSupport = true;
  
  // Must handle Scotland boundary detection privacy
  static const bool boundaryDetectionPrivacyCompliant = true;
}
```

---

## Reference Implementation Notes

### Algorithm References
```dart
/// Reference implementations and standards
class GeohashReferences {
  // Original geohash specification
  static const String originalSpecUrl = 'https://en.wikipedia.org/wiki/Geohash';
  static const String gustavorNiemeyerSpec = 'https://github.com/davetroy/geohash-js';
  
  // Test vector sources
  static const String testVectorSource = 'geohash.org';
  static const Map<String, dynamic> referenceVectors = {
    'lat': 57.64911, 'lon': 10.40744,  // Aalborg, Denmark
    'precision5': 'u4pru',
    'precision7': 'u4pruyz',
  };
  
  // Performance comparison targets
  static const String benchmarkReference = 'geohash-js';
  static const String performanceTarget = 'comparable_to_javascript_implementation';
}
```