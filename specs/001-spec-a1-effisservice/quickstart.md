# Quickstart: EffisService Testing & Integration

**Created**: 2025-10-02  
**Purpose**: Step-by-step validation and integration testing scenarios

## Prerequisites

1. Flutter SDK 3.10+ installed
2. Dependencies added to pubspec.yaml:
   ```yaml
   dependencies:
     http: ^1.1.0
     dartz: ^0.10.1
     equatable: ^2.0.5
   
   dev_dependencies:
     mockito: ^5.4.2
     build_runner: ^2.4.7
   ```
3. Test fixtures available in `test/fixtures/effis/`

## Quick Integration Test

### Step 1: Basic Service Instantiation
```dart
void main() async {
  // Create service instance
  final effisService = EffisServiceImpl(
    httpClient: http.Client(),
  );
  
  // Test coordinates (Edinburgh)
  const lat = 55.953;
  const lon = -3.189;
  
  print('Testing EffisService with Edinburgh coordinates...');
}
```

### Step 2: Successful FWI Retrieval
```dart
// Execute FWI request
final result = await effisService.getFwi(lat: lat, lon: lon);

result.fold(
  // Handle error case
  (error) {
    print('❌ Error: ${error.message}');
    print('   Type: ${error.type}');
    print('   Status: ${error.statusCode}');
    exit(1);
  },
  // Handle success case  
  (fwiResult) {
    print('✅ Success!');
    print('   FWI: ${fwiResult.fwi}');
    print('   Risk Level: ${fwiResult.level}');
    print('   Observed: ${fwiResult.observedAt}');
    print('   Source: ${fwiResult.source}');
  },
);
```

### Step 3: Validation Checks
```dart
// Validate result structure
result.fold(
  (error) => exit(1),
  (fwiResult) {
    // Check FWI value is reasonable
    assert(fwiResult.fwi >= 0, 'FWI should be non-negative');
    assert(fwiResult.fwi < 200, 'FWI should be reasonable (<200)');
    
    // Check timestamp is recent (within 24 hours)
    final now = DateTime.now();
    final age = now.difference(fwiResult.observedAt);
    assert(age.inHours < 24, 'Data should be recent');
    
    // Check risk level mapping is correct
    final expectedLevel = RiskLevel.fromFwi(fwiResult.fwi);
    assert(fwiResult.level == expectedLevel, 'Risk level mapping incorrect');
    
    print('✅ All validations passed');
  },
);
```

## Error Scenario Testing

### Test 1: Invalid Coordinates
```dart
// Test latitude out of bounds
final invalidResult = await effisService.getFwi(lat: 91.0, lon: 0.0);

invalidResult.fold(
  (error) {
    assert(error.type == ApiErrorType.clientError, 'Should be client error');
    print('✅ Invalid coordinates handled correctly');
  },
  (result) {
    print('❌ Should have failed with invalid coordinates');
    exit(1);
  },
);
```

### Test 2: Network Timeout
```dart
// Test with very short timeout
final timeoutResult = await effisService.getFwi(
  lat: 55.953, 
  lon: -3.189,
  timeout: Duration(milliseconds: 1), // Impossibly short
);

timeoutResult.fold(
  (error) {
    assert(error.type == ApiErrorType.networkError, 'Should be network error');
    print('✅ Timeout handled correctly');
  },
  (result) {
    print('❌ Should have timed out');
    exit(1);
  },
);
```

### Test 3: Retry Logic
```dart
// Create service with mock that fails twice then succeeds
final mockClient = MockClient((request) async {
  // Implementation would track call count and fail first 2 attempts
  // then return success on 3rd attempt
});

final retryService = EffisServiceImpl(httpClient: mockClient);
final retryResult = await retryService.getFwi(lat: 55.953, lon: -3.189);

// Should succeed after retries
assert(retryResult.isRight(), 'Should succeed after retries');
print('✅ Retry logic working correctly');
```

## Performance Testing

### Latency Test
```dart
Future<void> testLatency() async {
  final stopwatch = Stopwatch()..start();
  
  final result = await effisService.getFwi(lat: 55.953, lon: -3.189);
  
  stopwatch.stop();
  final elapsedMs = stopwatch.elapsedMilliseconds;
  
  result.fold(
    (error) {
      print('❌ Request failed: ${error.message}');
    },
    (fwiResult) {
      print('⏱️  Request completed in ${elapsedMs}ms');
      
      // Check performance requirement (<3 seconds)
      assert(elapsedMs < 3000, 'Request should complete in <3 seconds');
      print('✅ Performance requirement met');
    },
  );
}
```

### Load Test (Basic)
```dart
Future<void> testConcurrentRequests() async {
  final futures = List.generate(5, (i) => 
    effisService.getFwi(lat: 55.953 + (i * 0.01), lon: -3.189)
  );
  
  final results = await Future.wait(futures);
  
  final successCount = results.where((r) => r.isRight()).length;
  print('✅ $successCount/5 concurrent requests succeeded');
  
  assert(successCount >= 4, 'At least 4/5 requests should succeed');
}
```

## Integration with Test Fixtures

### Golden Test Validation
```dart
Future<void> validateWithFixtures() async {
  // Load golden response from fixtures
  final fixtureJson = await File('test/fixtures/effis/edinburgh_success.json')
    .readAsString();
  
  // Create mock service with fixture data
  final mockClient = MockClient((request) async {
    return http.Response(fixtureJson, 200);
  });
  
  final fixtureService = EffisServiceImpl(httpClient: mockClient);
  final result = await fixtureService.getFwi(lat: 55.953, lon: -3.189);
  
  result.fold(
    (error) {
      print('❌ Fixture test failed: ${error.message}');
      exit(1);
    },
    (fwiResult) {
      // Validate against known fixture values
      assert(fwiResult.fwi == 15.234, 'FWI should match fixture');
      assert(fwiResult.level == RiskLevel.moderate, 'Risk level should be moderate');
      print('✅ Fixture validation passed');
    },
  );
}
```

## Manual QA Checklist

### Functional Testing
- [ ] ✅ Successful FWI retrieval for UK coordinates
- [ ] ✅ Error handling for invalid coordinates  
- [ ] ✅ Timeout behavior with short duration
- [ ] ✅ Retry logic with exponential backoff
- [ ] ✅ FWI to risk level mapping accuracy
- [ ] ✅ JSON parsing with real EFFIS responses

### Non-Functional Testing  
- [ ] ✅ Request latency <3 seconds (normal network)
- [ ] ✅ Memory usage stable during repeated requests
- [ ] ✅ No sensitive data in logs (coordinates rounded)
- [ ] ✅ Concurrent request handling
- [ ] ✅ Graceful degradation when EFFIS unavailable

### Constitutional Compliance
- [ ] ✅ C1: Code passes flutter analyze & format
- [ ] ✅ C2: No hardcoded secrets, safe logging
- [ ] ✅ C5: Timeouts, error handling, retry logic
- [ ] ✅ All unit tests passing
- [ ] ✅ Golden test fixtures validate schema

## Complete Test Execution

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Run performance tests
flutter test test/performance/

# Run golden tests  
flutter test test/golden/

# Validate fixtures are up to date
flutter test test/fixtures/ --update-goldens
```

**Expected Result**: All tests pass, coverage >90%, no constitutional violations.

**Success Criteria**: Service is ready for integration into FireRiskService (A2).