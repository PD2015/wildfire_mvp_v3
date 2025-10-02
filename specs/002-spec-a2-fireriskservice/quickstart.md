# Quick Start: FireRiskService Integration

## Overview
FireRiskService provides a unified interface for fire risk assessment with automatic fallback across multiple data sources. This guide shows how to integrate and use the service effectively.

## Basic Usage

### Simple Fire Risk Query
```dart
// Initialize service with dependencies
final fireRiskService = FireRiskService(
  effisService: effisService,
  sepaService: sepaService, 
  cacheService: cacheService,
);

// Get fire risk for location
final result = await fireRiskService.getCurrent(
  lat: 55.9533,  // Edinburgh
  lon: -3.1883,
);

result.fold(
  (error) => print('Error: ${error.message}'),
  (fireRisk) => print('Risk: ${fireRisk.level} from ${fireRisk.source}'),
);
```

### Handling Different Data Sources
```dart
result.fold(
  (error) => handleError(error),
  (fireRisk) {
    switch (fireRisk.source) {
      case 'effis':
        // Live EFFIS data - most authoritative
        displayLiveData(fireRisk);
        break;
      case 'sepa':
        // SEPA data for Scotland - good quality
        displayRegionalData(fireRisk);
        break;
      case 'cache':
        // Cached data - show freshness warning
        displayCachedData(fireRisk);
        break;
      case 'mock':
        // Mock data - show service unavailable message
        displayFallbackData(fireRisk);
        break;
    }
  },
);
```

## Integration Scenarios

### Mobile App Integration
```dart
class FireRiskWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  
  @override
  _FireRiskWidgetState createState() => _FireRiskWidgetState();
}

class _FireRiskWidgetState extends State<FireRiskWidget> {
  Future<void> _loadFireRisk() async {
    setState(() => _loading = true);
    
    final result = await fireRiskService.getCurrent(
      lat: widget.latitude,
      lon: widget.longitude,
    );
    
    result.fold(
      (error) => setState(() {
        _error = error.message;
        _loading = false;
      }),
      (fireRisk) => setState(() {
        _fireRisk = fireRisk;
        _loading = false;
      }),
    );
  }
}
```

### Background Service Integration
```dart
class LocationMonitoringService {
  Timer? _monitoringTimer;
  
  void startMonitoring(Duration interval) {
    _monitoringTimer = Timer.periodic(interval, (_) async {
      final location = await getCurrentLocation();
      final fireRisk = await fireRiskService.getCurrent(
        lat: location.latitude,
        lon: location.longitude,
      );
      
      fireRisk.fold(
        (error) => logError('Fire risk check failed: ${error.message}'),
        (risk) => {
          if (risk.level == 'high' || risk.level == 'veryHigh' || risk.level == 'extreme') {
            sendRiskAlert(risk);
          }
        },
      );
    });
  }
}
```

## Common Integration Patterns

### User Experience Patterns

#### Progressive Loading
```dart
// Show cached data immediately, then update with live data
void loadFireRiskProgressive() async {
  // First, try to show cached data quickly
  showCachedDataIfAvailable();
  
  // Then fetch live data
  final result = await fireRiskService.getCurrent(lat: lat, lon: lon);
  result.fold(
    (error) => showError(error),
    (fireRisk) => updateDisplay(fireRisk),
  );
}
```

#### Source Attribution Display
```dart
Widget buildSourceIndicator(FireRisk fireRisk) {
  final sourceInfo = {
    'effis': {'label': 'Live EFFIS', 'color': Colors.green},
    'sepa': {'label': 'SEPA Scotland', 'color': Colors.blue},
    'cache': {'label': 'Cached Data', 'color': Colors.orange},
    'mock': {'label': 'Service Offline', 'color': Colors.grey},
  };
  
  final info = sourceInfo[fireRisk.source]!;
  return Chip(
    label: Text(info['label'] as String),
    backgroundColor: info['color'] as Color,
    avatar: Icon(_getSourceIcon(fireRisk.source)),
  );
}
```

### Error Handling Patterns

#### Graceful Degradation
```dart
Future<void> handleFireRiskError(ApiError error) async {
  // Log error for debugging/monitoring
  logger.warning('FireRisk error: ${error.message}', {
    'statusCode': error.statusCode,
    'reason': error.reason?.toString(),
  });
  
  // Show user-friendly message based on error type
  final userMessage = switch (error.reason) {
    ApiErrorReason.networkError => 'Network connection issue. Showing cached data.',
    ApiErrorReason.timeout => 'Service is slow. Please try again.',
    ApiErrorReason.validation => 'Invalid location. Please check coordinates.',
    _ => 'Fire risk data temporarily unavailable.',
  };
  
  showUserMessage(userMessage);
}
```

#### Retry Logic
```dart
Future<Either<ApiError, FireRisk>> getFireRiskWithRetry({
  required double lat,  
  required double lon,
  int maxRetries = 2,
}) async {
  for (int attempt = 0; attempt <= maxRetries; attempt++) {
    final result = await fireRiskService.getCurrent(lat: lat, lon: lon);
    
    if (result.isRight()) return result;
    
    final error = result.fold((l) => l, (r) => throw Exception('Unexpected'));
    
    // Don't retry validation errors
    if (error.reason == ApiErrorReason.validation) return result;
    
    // Wait before retry (exponential backoff)
    if (attempt < maxRetries) {
      await Future.delayed(Duration(seconds: pow(2, attempt).toInt()));
    }
  }
  
  return result; // Return last attempt result
}
```

## Testing Integration

### Mock Service for Testing
```dart
class MockFireRiskService implements FireRiskService {
  final FireRisk _mockResult;
  final ApiError? _mockError;
  
  MockFireRiskService.success(this._mockResult) : _mockError = null;
  MockFireRiskService.failure(this._mockError) : _mockResult = null;
  
  @override
  Future<Either<ApiError, FireRisk>> getCurrent({
    required double lat,
    required double lon,
  }) async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 100));
    
    return _mockError != null 
        ? Left(_mockError!)
        : Right(_mockResult!);
  }
}
```

### Integration Testing
```dart
void main() {
  group('FireRiskService Integration', () {
    testWidgets('should display fire risk data', (tester) async {
      // Setup mock service
      final mockService = MockFireRiskService.success(
        FireRisk(
          level: 'moderate',
          source: 'effis',
          freshness: 'live',
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      
      // Build widget with mock service
      await tester.pumpWidget(
        FireRiskApp(fireRiskService: mockService),
      );
      
      // Verify UI shows fire risk data
      expect(find.text('Moderate Risk'), findsOneWidget);
      expect(find.text('Live EFFIS'), findsOneWidget);
    });
  });
}
```

## Performance Optimization

### Caching Strategy
```dart
// Cache results locally for immediate display
class FireRiskCacheManager {
  final Map<String, FireRisk> _cache = {};
  final Duration _cacheTtl = Duration(minutes: 30);
  
  FireRisk? getCached(double lat, double lon) {
    final key = _generateKey(lat, lon);
    final cached = _cache[key];
    
    if (cached != null && _isStillFresh(cached)) {
      return cached;
    }
    
    _cache.remove(key); // Remove expired entry
    return null;
  }
  
  void cache(double lat, double lon, FireRisk fireRisk) {
    final key = _generateKey(lat, lon);
    _cache[key] = fireRisk;
  }
}
```

### Monitoring & Telemetry
```dart
// Track service performance and usage
class FireRiskTelemetry {
  void trackServiceCall({
    required String source,
    required Duration latency,
    required bool success,
    String? errorReason,
  }) {
    analytics.track('fire_risk_service_call', {
      'source': source,
      'latency_ms': latency.inMilliseconds,
      'success': success,
      'error_reason': errorReason,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
```

## Configuration

### Service Configuration
```dart
final fireRiskService = FireRiskService(
  effisService: effisService,
  sepaService: sepaService,
  cacheService: cacheService,
  config: FireRiskConfig(
    totalTimeout: Duration(seconds: 10),
    cacheTtl: Duration(hours: 6),
    enableTelemetry: true,
    coordinatePrecision: 3, // decimal places for privacy
  ),
);
```

This quickstart guide provides practical examples for integrating FireRiskService into various application scenarios while following best practices for error handling, user experience, and performance.