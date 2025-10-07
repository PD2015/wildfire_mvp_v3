# Integration Testing Contract

**Contract Type**: Integration Test Interface  
**Target**: End-to-end debugging scenarios with LocationResolver, FireRiskService, and CacheService  
**Coverage Requirement**: 90%

## Integration Flow Contracts

### Complete Debugging Scenario
**Contract**: Full debugging flow from GPS bypass to fire risk display
```dart
// GIVEN: App in debugging mode with GPS bypass active
// WHEN: User opens app and requests location-based fire risk
// THEN: GPS bypass provides Aviemore coordinates (57.2, -3.8)
// AND: FireRiskService processes coordinates successfully
// AND: Valid fire risk data is displayed
// AND: Source labeling shows appropriate debugging indicators
```

### Cache Integration Scenario
**Contract**: Debugging modifications work with cache service
```dart
// GIVEN: GPS bypass active and cache service enabled
// WHEN: Location is resolved and fire risk is fetched
// THEN: Cache service processes bypass coordinates correctly
// AND: Geohash generation works for Aviemore coordinates
// AND: Cache storage/retrieval operations succeed
// AND: No cache corruption occurs from debugging coordinates
```

### Service Orchestration Contract
**Contract**: All services work together during debugging session
```dart
// GIVEN: LocationResolver with GPS bypass, FireRiskService, CacheService
// WHEN: Complete service orchestration is executed
// THEN: LocationResolver provides bypass coordinates
// AND: FireRiskService accepts coordinates and returns risk data
// AND: CacheService handles coordinate caching appropriately
// AND: All services maintain error handling contracts
```

## Error Integration Contracts  

### GPS Bypass Failure Recovery
**Contract**: System recovers gracefully when GPS bypass fails
```dart
// GIVEN: GPS bypass is configured but fails to provide coordinates
// WHEN: LocationResolver fallback chain executes
// THEN: System falls back to cache, then manual entry, then Scotland centroid
// AND: Error handling maintains debugging context
// AND: User receives appropriate debugging error messages
```

### Service Chain Error Propagation
**Contract**: Errors propagate correctly through service chain during debugging
```dart
// GIVEN: GPS bypass provides coordinates but FireRiskService fails
// WHEN: Service error occurs during debugging session
// THEN: Error includes debugging context information
// AND: Error recovery maintains bypass coordinate context
// AND: Fallback services receive correct coordinate context
```

## Performance Integration Contracts

### End-to-End Response Time
- GPS bypass to fire risk display: <2 seconds
- Cache integration operations: <500ms additional overhead
- Error recovery scenarios: <3 seconds total

### Resource Efficiency
- Memory usage during debugging: <10MB additional overhead
- CPU usage: <5% additional during bypass operations
- Network calls: Reduced due to hardcoded coordinates (no GPS API calls)

## Cross-Service Data Flow Contracts

### LocationResolver → FireRiskService
**Contract**: Bypass coordinates integrate seamlessly with fire risk service
```dart
// GIVEN: LocationResolver provides Aviemore coordinates (57.2, -3.8)
// WHEN: FireRiskService.getCurrent() is called
// THEN: Coordinates are within Scotland boundaries
// AND: SEPA service is triggered (Scotland-specific)
// AND: Fire risk data is successfully retrieved
// AND: No geographic boundary validation errors
```

### FireRiskService → CacheService
**Contract**: Fire risk data caching works with bypass coordinates
```dart
// GIVEN: FireRiskService returns fire risk for Aviemore
// WHEN: CacheService stores the result
// THEN: Geohash key is generated correctly for (57.2, -3.8)
// AND: TTL and spatial caching work normally
// AND: Cache retrieval works for subsequent requests
```

### CacheService → LocationResolver
**Contract**: Cache interactions preserve debugging context
```dart
// GIVEN: Cache contains data for bypass coordinates
// WHEN: LocationResolver checks cache during fallback
// THEN: Cache provides valid data for bypass coordinates
// AND: Cache miss scenarios work correctly
// AND: Manual cache clearing maintains bypass coordinate context
```

## State Management Integration

### Debugging State Persistence
**Contract**: Debugging state is maintained across service interactions
```dart
// GIVEN: GPS bypass is active with debugging state
// WHEN: Services interact throughout application lifecycle
// THEN: Debugging context is preserved across all service calls
// AND: Debugging indicators remain visible in UI
// AND: Service logs maintain debugging context markers
```

### State Transition Validation
**Contract**: State transitions work correctly during debugging
```dart
// GIVEN: App transitions between different states during debugging
// WHEN: Services need to adapt to state changes
// THEN: GPS bypass state transitions work correctly
// AND: Cache state changes are handled appropriately
// AND: Fire risk service maintains debugging awareness
```

## UI Integration Contracts

### Home Screen Integration
**Contract**: Home screen displays debugging information correctly
```dart
// GIVEN: GPS bypass active with fire risk data loaded
// WHEN: Home screen is displayed
// THEN: Bypass coordinates are reflected in location display
// AND: Fire risk banner shows data for Aviemore coordinates
// AND: Debugging indicators are visible to user
// AND: Cache clear functionality works from home screen
```

### Error State Display
**Contract**: Error states are displayed correctly during debugging
```dart
// GIVEN: Service error occurs during debugging session
// WHEN: Error state needs to be displayed
// THEN: Error message includes debugging context
// AND: Error recovery options are appropriate for debugging mode
// AND: User can distinguish debugging errors from production errors
```

## Logging Integration Contracts

### Cross-Service Logging
**Contract**: Debugging logs are coordinated across services
```dart
// GIVEN: Multiple services active during debugging session
// WHEN: Operations are performed across service boundaries
// THEN: Log entries include consistent debugging markers
// AND: Coordinate redaction works consistently (LocationUtils.logRedact)
// AND: Log correlation IDs connect related operations
// AND: Debugging session boundaries are clear in logs
```

### Privacy-Compliant Integration Logging
**Contract**: All integrated logging respects coordinate redaction requirements
```dart
// GIVEN: Services log coordinate-related information during debugging
// WHEN: Cross-service operations occur
// THEN: All coordinate logging uses 2-decimal precision
// AND: No service logs full-precision coordinates
// AND: Geohash keys are used where appropriate for privacy
```

---
*Contract defines behavioral requirements for comprehensive integration testing of debugging modifications*