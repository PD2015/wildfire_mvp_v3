# Research: CacheService (6h TTL)

**Feature**: A5 CacheService with 6-hour TTL and geohash-based spatial keying  
**Research Date**: 2025-10-04  
**Context**: FireRisk data caching for offline resilience and performance

---

## Technology Decisions

### Cache Storage Backend
**Decision**: SharedPreferences  
**Rationale**: 
- Native platform key-value store available across Flutter platforms
- Persistent across app restarts and device reboots  
- Atomic read/write operations prevent corruption
- Already used successfully in A4 LocationResolver for manual location persistence
- No additional dependencies required

**Alternatives Considered**:
- SQLite: Overkill for simple key-value operations, adds complexity
- File system: Manual corruption handling, platform path differences
- In-memory only: Lost on app restart, defeats offline resilience goal

### Geohash Implementation
**Decision**: Custom implementation using crypto package  
**Rationale**:
- Deterministic spatial hashing at precision 5 (~4.9km resolution)
- Efficient string-based cache keys for SharedPreferences
- Standard geohash algorithm ensures compatibility
- Precision 5 balances cache efficiency with spatial accuracy

**Alternatives Considered**:
- External geohash package: Additional dependency, version management
- Coordinate rounding: Less efficient spatial clustering
- Raw lat/lon keys: No spatial locality, cache misses for nearby locations

### Serialization Format
**Decision**: JSON with version field  
**Rationale**:
- Human-readable format for debugging
- Built-in Dart JSON support with jsonEncode/jsonDecode
- Version field enables future format migrations
- Easy corruption detection with try/catch parsing

**Schema**:
```json
{
  "version": "1.0",
  "timestamp": 1696435200000,
  "geohash": "gcpue",
  "data": {
    "level": "moderate",
    "source": "effis",
    "freshness": "live",
    "observedAt": "2025-10-04T14:00:00Z",
    "fwi": 18.5
  }
}
```

**Alternatives Considered**:
- Binary serialization: Faster but harder to debug, no built-in Dart support
- Protocol Buffers: Overkill for simple data structures
- Raw object serialization: No version control, fragile to model changes

### TTL Enforcement Strategy
**Decision**: Lazy expiration on read  
**Rationale**:
- Simple implementation: check timestamp during get() operation
- No background cleanup processes needed
- Expired entries automatically ignored
- Consistent with cache miss behavior

**Implementation**:
```dart
Future<Option<FireRisk>> get(String key) async {
  final entry = await _loadFromPrefs(key);
  if (entry.isEmpty) return none();
  
  final age = DateTime.now().difference(entry.timestamp);
  if (age > Duration(hours: 6)) {
    _logger.debug('Cache entry expired for $key');
    return none(); // Treat as cache miss
  }
  
  return some(entry.data.copyWith(freshness: Freshness.cached));
}
```

**Alternatives Considered**:
- Eager expiration: Background cleanup complexity, battery drain
- TTL extension on read: Violates 6h absolute limit requirement
- Gradual degradation: Adds complexity without clear user benefit

### Size Management Strategy
**Decision**: Simple LRU eviction with access tracking  
**Rationale**:
- Maintains most recently accessed entries (better cache hit rate)
- Simple implementation with access timestamp updates
- Prevents unbounded cache growth (constitutional C5 requirement)
- Predictable behavior for testing

**Implementation Approach**:
- Track last access time for each cache entry
- On write when cache full (100 entries): remove oldest accessed entry
- Update access time on successful reads
- Single cleanup pass during write operations

**Alternatives Considered**:
- FIFO eviction: Simpler but poorer cache performance
- Size-based eviction: Complex size calculation, varies by data content
- Random eviction: Unpredictable, harder to test
- External LRU library: Additional dependency, overkill for simple use case

### Error Handling Approach
**Decision**: Graceful degradation with logging  
**Rationale**:
- Cache failures should never prevent fresh data retrieval (constitutional C5)
- Clear error visibility through logging (constitutional principle)
- Option/Either types make cache miss explicit to callers
- Corruption recovery by ignoring bad entries

**Error Scenarios**:
1. **JSON Parse Error**: Log warning, treat as cache miss, continue
2. **SharedPreferences Write Failure**: Log error, return success (non-blocking)
3. **SharedPreferences Read Failure**: Log error, return cache miss
4. **Version Mismatch**: Log info, treat as cache miss, eventual overwrite
5. **Storage Full**: Log warning, attempt LRU eviction, fallback to cache miss

---

## Integration Patterns

### FireRiskService Integration
**Pattern**: Optional dependency injection  
**Current A2 Architecture**:
```dart
FireRiskServiceImpl({
  required EffisService effisService,
  SepaService? sepaService,
  CacheService? cacheService,  // ← A5 integration point
  required MockService mockService,
  OrchestratorTelemetry? telemetry,
});
```

**Fallback Chain Integration**:
```
getCurrent(lat, lon) → FireRisk
    ↓
[1. EFFIS] (3s timeout) → Success? → FireRisk{freshness: live}
    ↓ Fail
[2. SEPA] (2s timeout, Scotland only) → Success? → FireRisk{freshness: live}  
    ↓ Fail
[3. Cache] (200ms timeout) → Hit? → FireRisk{freshness: cached}  ← A5 integration
    ↓ Miss
[4. Mock] (<100ms, never fails) → FireRisk{freshness: mock}
```

### Privacy Compliance Integration
**Approach**: Use existing A4 LocationUtils.logRedact  
**Implementation**:
```dart
// Cache key generation with privacy-compliant logging
final geohash = GeohashUtils.encode(lat, lon, precision: 5);
_logger.debug('Cache lookup for ${LocationUtils.logRedact(lat, lon)} → $geohash');
```

**Benefits**:
- Consistent with A4 LocationResolver privacy patterns
- Geohash keys inherently privacy-preserving (4.9km resolution)
- No raw coordinates in cache storage or logs

---

## Performance Characteristics

### Cache Hit Scenarios
- **Read Operation**: <200ms target (SharedPreferences + JSON decode)
- **Write Operation**: <100ms target (JSON encode + SharedPreferences)
- **Cache Hit Rate**: ~80% expected for typical user movement patterns
- **Storage Overhead**: ~500 bytes per cache entry (JSON format)

### Spatial Efficiency
- **Geohash Precision 5**: 4.9km × 4.9km spatial resolution
- **Cache Coverage**: Single entry covers ~24 km² area
- **Urban Movement**: Multiple locations likely share geohash keys
- **Rural Coverage**: Single key covers wide geographic areas

### Memory Usage
- **Max Entries**: 100 × 500 bytes = ~50KB total cache storage
- **Runtime Memory**: Minimal (lazy loading, no in-memory cache)
- **Platform Storage**: Uses native SharedPreferences limits

---

## Testing Strategy

### Unit Test Coverage
1. **Geohash Generation**: Precision 5 accuracy, edge cases (poles, meridian)
2. **TTL Enforcement**: Expired entries return cache miss
3. **JSON Serialization**: Round-trip integrity, version compatibility
4. **LRU Eviction**: Correct victim selection, access time updates
5. **Corruption Handling**: Malformed JSON ignored gracefully

### Integration Test Scenarios  
1. **Cache Lifecycle**: Write → Read → TTL expiry → Miss
2. **Storage Persistence**: Write → App restart → Read
3. **Size Management**: Fill cache → Trigger eviction → Verify LRU
4. **Error Recovery**: Corrupt entry → Graceful degradation
5. **Spatial Clustering**: Nearby coordinates → Same geohash key

### Contract Test Requirements
1. **CacheService<T> Interface**: Generic type safety
2. **FireRiskCache Compliance**: Specific FireRisk integration
3. **Freshness Marking**: cached freshness on successful reads
4. **Error Handling**: Option/Either return types

---

## Constitutional Compliance

### C1 (Code Quality & Tests)
- Comprehensive unit tests for all cache operations  
- Integration tests for TTL and eviction scenarios
- Contract tests for interface compliance
- Flutter analyze and dart format compliance

### C2 (Secrets & Logging)
- No secrets involved in cache implementation
- Uses LocationUtils.logRedact for coordinate privacy
- Geohash keys provide inherent privacy protection
- No PII stored in cache (coordinates already aggregated)

### C5 (Resilience & Test Coverage)
- Graceful degradation: cache failures don't block fresh data
- Corruption recovery: malformed entries ignored
- Clear error states: Option/Either types for cache operations
- Comprehensive error scenario testing

---

## Implementation Phases

### Phase 1: Core Infrastructure
- GeohashUtils implementation and testing
- CacheService<T> generic interface
- Basic JSON serialization with versioning

### Phase 2: FireRiskCache Implementation  
- FireRisk-specific cache implementation
- TTL enforcement and freshness marking
- SharedPreferences integration

### Phase 3: Size Management
- LRU eviction policy implementation
- Access tracking and cleanup
- Performance optimization

### Phase 4: Integration & Testing
- FireRiskService integration point
- Comprehensive test suite
- Performance validation and optimization