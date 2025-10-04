# A5 CacheService Implementation Quickstart

**Feature**: A5 CacheService with 6-hour TTL and geohash-based spatial keying  
**Quickstart Date**: 2025-10-04  
**Context**: Fast-track implementation guide for cache service development

---

## TL;DR Implementation Checklist

### Phase 1: Core Infrastructure ⚡
- [ ] `GeohashUtils.encode()` with precision 5 support
- [ ] `CacheEntry<T>` generic model with TTL checking
- [ ] `CacheService<T>` interface definition
- [ ] Basic JSON serialization/deserialization
- [ ] Unit tests for geohash encoding accuracy

### Phase 2: FireRisk Integration ⚡
- [ ] `FireRiskCache` implementation extending `CacheService<FireRisk>`
- [ ] SharedPreferences storage backend
- [ ] TTL enforcement (6-hour expiration)
- [ ] Freshness marking (`cached` on successful reads)
- [ ] Integration tests with real storage

### Phase 3: Size Management ⚡  
- [ ] LRU eviction policy (100 entry limit)
- [ ] `CacheMetadata` tracking with access timestamps
- [ ] Cleanup process removing expired + least accessed
- [ ] Performance tests validating <200ms reads, <100ms writes

### Phase 4: FireRiskService Integration ⚡
- [ ] Optional dependency injection in `FireRiskServiceImpl`
- [ ] Fallback chain position 3 (after EFFIS/SEPA, before Mock)
- [ ] Privacy-compliant logging with coordinate redaction
- [ ] Integration tests with full fallback chain

---

## Quick Implementation Guide

### 30-Second Architecture
```
User Request → FireRiskService → [EFFIS fail] → [SEPA fail] → CacheService
                                                                    ↓
Geohash Key ← Coordinates                                    SharedPreferences
(precision 5)                                               (JSON storage)
    ↓                                                              ↓
"gcpue" → CacheEntry<FireRisk> → TTL Check → FireRisk{freshness: cached}
```

### 60-Second Data Flow
```dart
// 1. User requests fire risk for coordinates
final fireRisk = await fireRiskService.getCurrent(lat: 55.9533, lon: -3.1883);

// 2. EFFIS/SEPA fail, fallback to cache
final geohash = GeohashUtils.encode(55.9533, -3.1883, precision: 5); // "gcpue"
final cached = await cacheService.get(geohash);

// 3. Cache hit: return with freshness marking
if (cached.isSome()) {
  return cached.value.copyWith(freshness: Freshness.cached);
}

// 4. Cache miss: fallback to Mock service
return await mockService.getCurrent(lat: lat, lon: lon);
```

### 90-Second Testing Strategy
```dart
// Critical test scenarios (implement these first)
test('geohash_precision_5_accuracy', () {
  expect(GeohashUtils.encode(55.9533, -3.1883, precision: 5), 'gcpue');
});

test('ttl_enforcement_6_hours', () async {
  await cache.set(lat: 55.9533, lon: -3.1883, data: fireRisk);
  
  // Mock 7 hours later
  final expired = await cache.get('gcpue');
  expect(expired.isNone(), true);
});

test('lru_eviction_at_100_entries', () async {
  // Fill cache to 100 entries
  // Add 101st entry
  // Verify oldest accessed entry removed
});

test('firerisk_service_integration', () async {
  when(effisService.getFwi()).thenThrow(NetworkException());
  when(sepaService.getCurrent()).thenThrow(NetworkException());
  
  final result = await fireRiskService.getCurrent(lat: 55.9533, lon: -3.1883);
  expect(result.freshness, Freshness.cached);
});
```

---

## Fast-Track File Structure

### Create These Files First
```
lib/utils/geohash_utils.dart              # ← Start here (geohash encoding)
lib/models/cache_entry.dart               # ← Generic cache wrapper
lib/services/cache_service.dart           # ← Abstract interface
lib/services/fire_risk_cache.dart         # ← FireRisk implementation
test/unit/geohash_utils_test.dart         # ← Critical path testing
test/unit/fire_risk_cache_test.dart       # ← Integration validation
```

### Skip These (Lower Priority)
```
lib/models/cache_metadata.dart            # Implement after LRU works
lib/models/geohash_key.dart               # Value object, nice-to-have
lib/utils/cache_constants.dart            # Constants, refactor later
docs/cache_performance_analysis.md       # Documentation, post-implementation
```

---

## Critical Path Dependencies

### Must Have (Blocking)
- `shared_preferences: ^2.2.2` - Storage backend
- `dartz: ^0.10.1` - Option/Either types (already in project)
- `equatable: ^2.0.5` - Value object equality (already in project)
- `crypto: ^3.0.3` - SHA1 for geohash base32 encoding

### Nice to Have (Non-blocking)
- `test: ^1.24.0` - Testing framework (already in project)
- `mockito: ^5.4.0` - Mock generation (already in project)
- `build_runner: ^2.4.0` - Code generation (already in project)

---

## Implementation Time Estimates

### Phase 1: Core Infrastructure (4-6 hours)
- GeohashUtils implementation: 2 hours
- CacheEntry model: 1 hour
- CacheService interface: 1 hour
- Basic unit tests: 2 hours

### Phase 2: FireRisk Integration (3-4 hours)
- FireRiskCache implementation: 2 hours
- SharedPreferences integration: 1 hour
- TTL and freshness logic: 1 hour

### Phase 3: Size Management (3-4 hours)
- CacheMetadata model: 1 hour
- LRU eviction logic: 2 hours
- Performance optimization: 1 hour

### Phase 4: Service Integration (2-3 hours)
- FireRiskService modification: 1 hour
- Integration testing: 1 hour
- Privacy compliance verification: 1 hour

**Total: 12-17 hours** (1.5-2 development days)

---

## Critical Success Metrics

### Must Pass Before Merge
- [ ] All unit tests pass (>95% coverage)
- [ ] GeohashUtils precision 5 accuracy verified
- [ ] TTL enforcement working correctly (6-hour expiration)
- [ ] LRU eviction removes correct entries at 100 limit
- [ ] FireRiskService integration preserves fallback chain
- [ ] Privacy compliance: no raw coordinates in logs
- [ ] Performance: <200ms reads, <100ms writes

### Should Pass for Quality
- [ ] Integration tests with real SharedPreferences
- [ ] Cache hit rate >70% in realistic scenarios
- [ ] Memory usage <50KB for full cache (100 entries)
- [ ] Clean error handling for corruption scenarios
- [ ] Proper logging with coordinate redaction

---

## Common Implementation Pitfalls

### ❌ Don't Do This
```dart
// Raw coordinates in logs (privacy violation)
_logger.info('Caching for coordinates: $lat, $lon');

// Synchronous SharedPreferences calls (blocks UI)
final data = prefs.getString(key);

// Ignoring TTL expiration
return some(cachedEntry.data); // Missing TTL check

// Hard-coded cache keys  
final key = 'fire_risk_${lat}_${lon}'; // No spatial locality
```

### ✅ Do This Instead  
```dart
// Privacy-compliant logging
_logger.info('Caching for ${LocationUtils.logRedact(lat, lon)}');

// Async SharedPreferences
final data = await prefs.getString(key);

// TTL enforcement
if (cachedEntry.isExpired) return none();
return some(cachedEntry.data.copyWith(freshness: Freshness.cached));

// Geohash spatial keys
final key = GeohashUtils.encode(lat, lon, precision: 5);
```

---

## Testing Quick Wins

### Fastest Tests to Implement
```dart
// 1. Geohash determinism (30 seconds)
test('geohash_same_input_same_output', () {
  final hash1 = GeohashUtils.encode(55.9533, -3.1883);
  final hash2 = GeohashUtils.encode(55.9533, -3.1883);
  expect(hash1, hash2);
});

// 2. TTL boolean logic (60 seconds)
test('cache_entry_ttl_detection', () {
  final fresh = CacheEntry.now(data: fireRisk, geohash: 'gcpue');
  final expired = CacheEntry(
    data: fireRisk, 
    geohash: 'gcpue',
    timestamp: DateTime.now().subtract(Duration(hours: 7)),
  );
  
  expect(fresh.isExpired, false);
  expect(expired.isExpired, true);
});

// 3. JSON round-trip (90 seconds)
test('cache_entry_json_round_trip', () {
  final original = CacheEntry.now(data: fireRisk, geohash: 'gcpue');
  final json = original.toJson((data) => data.toJson());
  final restored = CacheEntry.fromJson(json, FireRisk.fromJson);
  
  expect(restored.data, original.data);
  expect(restored.geohash, original.geohash);
});
```

### Hardest Tests (Implement Last)
- LRU eviction correctness (complex state management)
- Concurrent access handling (if needed)
- Performance benchmarks (timing-sensitive)
- SharedPreferences corruption recovery

---

## Debug Commands

### Verify Cache State
```dart
// Check cache contents during development
final metadata = await cacheService.getMetadata();
print('Cache entries: ${metadata.totalEntries}');
print('LRU key: ${metadata.lruKey}');

// Inspect SharedPreferences directly
final prefs = await SharedPreferences.getInstance();
final keys = prefs.getKeys().where((k) => k.startsWith('cache_entry_'));
print('Stored cache keys: $keys');
```

### Test Geohash Generation
```dart
// Validate geohash precision
final coordinates = [
  [55.9533, -3.1883], // Edinburgh
  [55.8642, -4.2518], // Glasgow  
  [57.1497, -2.0943], // Aberdeen
];

for (final coord in coordinates) {
  final hash = GeohashUtils.encode(coord[0], coord[1], precision: 5);
  print('${coord[0]}, ${coord[1]} → $hash');
}
```

### Measure Performance
```dart
// Quick performance validation
final stopwatch = Stopwatch()..start();
await cacheService.get('gcpue');
stopwatch.stop();
print('Cache read took: ${stopwatch.elapsedMilliseconds}ms');
// Should be <200ms
```

---

## Ready to Code? Start Here!

1. **Fork from A5 branch**: `git checkout 005-a5-cacheservice-6h`
2. **Create `GeohashUtils`**: Start with encode() method, precision 5
3. **Test geohash accuracy**: Edinburgh (55.9533, -3.1883) → "gcpue"  
4. **Implement `CacheEntry<T>`**: Generic wrapper with TTL checking
5. **Add SharedPreferences**: Simple get/set with JSON serialization
6. **Integrate with FireRiskService**: Optional cache dependency injection

**First milestone**: Cache hit/miss working with 6-hour TTL enforcement ⚡