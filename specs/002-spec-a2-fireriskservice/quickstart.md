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
        // Live EFFIS data - most authoritative, show confidence
        displayLiveData(fireRisk, confidence: 'High');
        _analytics.recordDataSource('effis', fireRisk.level);
        break;
      case 'sepa':
        // SEPA data for Scotland - regional authority, high trust
        displayRegionalData(fireRisk, authority: 'SEPA');
        _analytics.recordDataSource('sepa', fireRisk.level);
        break;
      case 'cache':
        // Cached data - show age and reduced confidence
        final age = DateTime.now().difference(fireRisk.updatedAt);
        displayCachedData(fireRisk, age: age);
        _analytics.recordDataSource('cache', fireRisk.level, age: age);
        break;
      case 'mock':
        // Mock data - clear fallback indicator
        displayFallbackData(fireRisk, 
          message: 'Using estimated data - services temporarily unavailable');
        _analytics.recordDataSource('mock', fireRisk.level);
        break;
    }
  },
);
```

## Dependency Injection Setup

### Service Registration (GetIt)
```dart
// main.dart
void setupServices() {
  // Register dependencies first
  GetIt.instance.registerSingleton<http.Client>(http.Client());
  GetIt.instance.registerSingleton<EffisService>(
    EffisServiceImpl(), // Already implemented in A1
  );
  
  // Register FireRiskService components
  GetIt.instance.registerSingleton<SepaService>(
    SepaServiceImpl(
      client: GetIt.instance<http.Client>(),
      converter: UkGridConverter(),
    ),
  );
  
  GetIt.instance.registerSingleton<CacheService>(
    CacheServiceImpl(
      storage: await EncryptedStorage.create(),
    ),
  );
  
  GetIt.instance.registerSingleton<MockService>(MockServiceImpl());
  
  GetIt.instance.registerSingleton<TelemetryService>(
    TelemetryServiceImpl(),
  );
  
  // Register main FireRiskService
  GetIt.instance.registerSingleton<FireRiskService>(
    FireRiskServiceImpl(
      effisService: GetIt.instance<EffisService>(),
      sepaService: GetIt.instance<SepaService>(),
      cacheService: GetIt.instance<CacheService>(),
      mockService: GetIt.instance<MockService>(),
      telemetryService: GetIt.instance<TelemetryService>(),
    ),
  );
}
```

### Alternative: Provider Pattern
```dart
// providers.dart
final fireRiskServiceProvider = Provider<FireRiskService>((ref) {
  return FireRiskServiceImpl(
    effisService: ref.read(effisServiceProvider),
    sepaService: ref.read(sepaServiceProvider),
    cacheService: ref.read(cacheServiceProvider),
    mockService: ref.read(mockServiceProvider),
    telemetryService: ref.read(telemetryServiceProvider),
  );
});

// usage in widget
class FireRiskWidget extends ConsumerWidget {
  final double latitude;
  final double longitude;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fireRiskService = ref.read(fireRiskServiceProvider);
    
    return FutureBuilder<Either<ApiError, FireRisk>>(
      future: fireRiskService.getCurrent(
        lat: latitude,
        lon: longitude,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        
        return snapshot.data?.fold(
          (error) => ErrorWidget(error: error),
          (fireRisk) => FireRiskDisplay(fireRisk: fireRisk),
        ) ?? Container();
      },
    );
  }
}
```

## Integration Scenarios

### Real-time Location Monitoring
```dart
class LocationFireRiskMonitor {
  final FireRiskService _fireRiskService;
  final LocationService _locationService;
  StreamSubscription? _locationSubscription;
  
  LocationFireRiskMonitor(this._fireRiskService, this._locationService);
  
  Stream<FireRisk> monitorCurrentLocation() {
    return _locationService.positionStream.asyncMap((position) async {
      final result = await _fireRiskService.getCurrent(
        lat: position.latitude,
        lon: position.longitude,
      );
      
      return result.fold(
        (error) {
          // Log error but continue monitoring
          _logger.warning('Fire risk monitoring error: ${error.message}');
          throw FireRiskMonitoringException(error.message);
        },
        (fireRisk) => fireRisk,
      );
    }).handleError((error) {
      // Provide fallback monitoring behavior
      _logger.error('Location monitoring failed', error);
    });
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

### Integration Testing Examples
```dart
void main() {
  group('FireRiskService Integration', () {
    late MockEffisService mockEffisService;
    late MockSepaService mockSepaService;
    late InMemoryCacheService cacheService;
    late MockService mockService;
    late TestTelemetryService telemetryService;
    late FireRiskService fireRiskService;
    
    setUp(() {
      mockEffisService = MockEffisService();
      mockSepaService = MockSepaService();
      cacheService = InMemoryCacheService();
      mockService = MockServiceImpl();
      telemetryService = TestTelemetryService();
      
      fireRiskService = FireRiskServiceImpl(
        effisService: mockEffisService,
        sepaService: mockSepaService,
        cacheService: cacheService,
        mockService: mockService,
        telemetryService: telemetryService,
      );
    });
    
    test('should use EFFIS for non-Scotland coordinates', () async {
      // Given: Non-Scotland coordinates and successful EFFIS response
      const lat = 40.7128, lon = -74.0060; // New York
      final effisResponse = FireRisk(
        level: 'low',
        fwi: 12.5,
        source: 'effis',
        updatedAt: DateTime.now().toUtc(),
        freshness: 'live',
      );
      when(mockEffisService.getCurrent(lat: lat, lon: lon))
          .thenAnswer((_) async => Right(effisResponse));
      
      // When: Getting fire risk
      final result = await fireRiskService.getCurrent(lat: lat, lon: lon);
      
      // Then: Should use EFFIS data without calling SEPA
      expect(result.isRight(), isTrue);
      expect(result.getOrElse(() => null)?.source, equals('effis'));
      verifyNever(mockSepaService.getCurrent(lat: any, lon: any));
    });
    
    test('should fallback EFFIS → SEPA → Cache → Mock for Scotland', () async {
      // Given: Scotland coordinates, EFFIS fails, SEPA fails, cache empty
      const lat = 55.9533, lon = -3.1883; // Edinburgh
      when(mockEffisService.getCurrent(lat: lat, lon: lon))
          .thenAnswer((_) async => Left(ApiError.serviceUnavailable()));
      when(mockSepaService.getCurrent(lat: lat, lon: lon))
          .thenAnswer((_) async => Left(ApiError.serviceUnavailable()));
      when(cacheService.get(any))
          .thenAnswer((_) async => null);
      
      // When: Getting fire risk
      final result = await fireRiskService.getCurrent(lat: lat, lon: lon);
      
      // Then: Should fallback to mock service
      expect(result.isRight(), isTrue);
      expect(result.getOrElse(() => null)?.source, equals('mock'));
      
      // And: All services should have been attempted
      verify(mockEffisService.getCurrent(lat: lat, lon: lon)).called(1);
      verify(mockSepaService.getCurrent(lat: lat, lon: lon)).called(1);
      verify(cacheService.get(any)).called(1);
    });
    
    test('should use cache when services fail but cache is fresh', () async {
      // Given: Services fail but fresh cache available
      const lat = 55.9533, lon = -3.1883;
      final cachedRisk = FireRisk(
        level: 'moderate',
        fwi: 15.0,
        source: 'effis', // Original source preserved
        updatedAt: DateTime.now().subtract(Duration(minutes: 30)).toUtc(),
        freshness: 'cached',
      );
      
      when(mockEffisService.getCurrent(lat: lat, lon: lon))
          .thenAnswer((_) async => Left(ApiError.serviceUnavailable()));
      when(mockSepaService.getCurrent(lat: lat, lon: lon))
          .thenAnswer((_) async => Left(ApiError.serviceUnavailable()));
      when(cacheService.get(any))
          .thenAnswer((_) async => cachedRisk);
      
      // When: Getting fire risk
      final result = await fireRiskService.getCurrent(lat: lat, lon: lon);
      
      // Then: Should use cached data
      expect(result.isRight(), isTrue);
      final fireRisk = result.getOrElse(() => null)!;
      expect(fireRisk.freshness, equals('cached'));
      expect(fireRisk.source, equals('effis')); // Original source preserved
    });
    
    testWidgets('FireRiskWidget integration test', (tester) async {
      // Given: Widget with mock service
      final mockService = MockFireRiskService.success(
        FireRisk(
          level: 'moderate',
          fwi: 18.7,
          source: 'effis',
          updatedAt: DateTime.now().toUtc(),
          freshness: 'live',
        ),
      );
      
      // When: Building widget
      await tester.pumpWidget(
        MaterialApp(
          home: Provider<FireRiskService>.value(
            value: mockService,
            child: FireRiskWidget(
              latitude: 55.9533,
              longitude: -3.1883,
            ),
          ),
        ),
      );
      
      // Then: Should display loading initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // And: After data loads, should display fire risk
      await tester.pumpAndSettle();
      expect(find.text('Risk Level: Moderate'), findsOneWidget);
      expect(find.text('Source: EFFIS'), findsOneWidget);
    });
  });
}
```

## Best Practices

### Performance Optimization
```dart
class FireRiskCache {
  final Map<String, CacheEntry> _memoryCache = {};
  final Duration _memoryTtl = Duration(minutes: 5);
  
  // Two-tier caching: memory (5min) + persistent (1hr)
  Future<FireRisk?> getOptimized(double lat, double lon) async {
    final key = _generateKey(lat, lon);
    
    // Check memory cache first (fastest)
    final memoryEntry = _memoryCache[key];
    if (memoryEntry != null && !memoryEntry.isExpired(_memoryTtl)) {
      return memoryEntry.data;
    }
    
    // Check persistent cache
    final persistentData = await _persistentCache.get(key);
    if (persistentData != null) {
      // Populate memory cache for next request
      _memoryCache[key] = CacheEntry(persistentData, DateTime.now());
      return persistentData;
    }
    
    return null;
  }
}
```

### Error Monitoring
```dart
class FireRiskTelemetry {
  static void recordServiceHealth(ServiceType service, bool success, Duration responseTime) {
    final metrics = {
      'service': service.toString(),
      'success': success,
      'response_time_ms': responseTime.inMilliseconds,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    // Send to analytics/monitoring service
    Analytics.track('fire_risk_service_call', metrics);
    
    // Alert on repeated failures
    if (!success) {
      _checkServiceHealthAlert(service);
    }
  }
  
  static void recordFallbackUsage(List<ServiceType> attemptedServices, ServiceType successful) {
    Analytics.track('fire_risk_fallback', {
      'attempted_services': attemptedServices.map((s) => s.toString()).toList(),
      'successful_service': successful.toString(),
      'fallback_depth': attemptedServices.indexOf(successful),
    });
  }
}
```

### Privacy Compliance
```dart
class PrivacyCompliantLogger {
  static void logFireRiskRequest(double lat, double lon, String result) {
    // Round coordinates to 2 decimal places for privacy
    final roundedLat = (lat * 100).round() / 100;
    final roundedLon = (lon * 100).round() / 100;
    
    logger.info('Fire risk request completed', {
      'approx_location': '${roundedLat},${roundedLon}',
      'result_source': result,
      'request_id': generateRequestId(), // For debugging correlation
    });
  }
}
```

## Troubleshooting

### Common Issues

**Service Always Returns Mock Data**
- Check network connectivity
- Verify EFFIS service configuration 
- Check telemetry logs for service failure reasons

**Scotland Coordinates Don't Use SEPA**
- Verify coordinate precision (should be within 54.6-60.9°N, 8.2°W-1.0°E)
- Check GeographicUtils.isScotland() boundary logic
- Test with known Scotland coordinates (e.g., Edinburgh: 55.9533, -3.1883)

**Cache Not Working**
- Verify EncryptedStorage permissions
- Check cache TTL configuration (default 1 hour)
- Test cache cleanup functionality

**Performance Issues**
- Monitor service timeout configuration (10s total)
- Check individual service timeouts (EFFIS: 5s, SEPA: 3s)
- Verify cache lookup performance (<100ms)

### Debug Mode
```dart
// Enable debug logging
FireRiskServiceImpl.debugMode = true;

// This will log:
// - Service selection logic
// - Fallback decisions  
// - Cache hit/miss details
// - Response timing information
```
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