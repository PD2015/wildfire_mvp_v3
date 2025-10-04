# Tasks: CacheService (6h TTL)

**Input**: Design documents from `/specs/005-a5-cacheservice-6h/`
**Prerequisites**: plan.md, research.md, data-model.md, contracts/, quickstart.md

## Execution Flow (main)
```
1. Load plan.md: Dart 3.0+ Flutter SDK, shared_preferences, dartz, equatable, crypto
2. Load design documents:
   → data-model.md: CacheEntry<T>, CacheMetadata, GeohashKey entities
   → contracts/: CacheService<T> interface, GeohashUtils specification
   → quickstart.md: TDD approach with 4-phase implementation
3. Generate 4 atomic tasks per user constraints:
   → T001: Core interfaces and geohash utilities
   → T002: TTL enforcement and size management
   → T003: Comprehensive test coverage
   → T004: Documentation and CI validation
4. Constitutional compliance integrated (C1, C2, C5)
5. TDD approach: Contract tests before implementation
```

## Labels Applied
- **spec:A5**: CacheService with 6h TTL and geohash spatial keying
- **gate:C1**: Code quality with comprehensive tests and flutter analyze
- **gate:C2**: Privacy-compliant coordinate logging via geohash keys
- **gate:C5**: Resilience with graceful corruption handling and cache miss fallback

---

## T001: Core Interfaces & Geohash Implementation [P] ✅
**Files**: `lib/utils/geohash_utils.dart`, `lib/models/cache_entry.dart`, `lib/services/cache_service.dart`
**Labels**: spec:A5, gate:C1, gate:C2

Implement core cache infrastructure with geohash spatial keying and generic interfaces:

1. **Create GeohashUtils** in `lib/utils/geohash_utils.dart`:
   ```dart
   class GeohashUtils {
     /// Encode coordinates to geohash string at precision 5 (~4.9km)
     static String encode(double lat, double lon, {int precision = 5}) {
       // Standard geohash algorithm implementation
       // Edinburgh (55.9533, -3.1883) → "gcvwr"
     }
     
     /// Validate geohash format (base32, valid characters only)
     static bool isValid(String geohash) {
       return RegExp(r'^[0-9bcdefghjkmnpqrstuvwxyz]+$').hasMatch(geohash);
     }
   }
   ```

2. **Create Clock interface and CacheEntry model**:
   
   `lib/utils/clock.dart`:
   ```dart
   abstract class Clock {
     DateTime nowUtc();
   }
   
   class SystemClock implements Clock {
     @override
     DateTime nowUtc() => DateTime.now().toUtc();
   }
   ```
   
   `lib/models/cache_entry.dart`:
   ```dart
   class CacheEntry<T> extends Equatable {
     const CacheEntry({
       required this.data,
       required this.timestamp,
       required this.geohash,
       this.version = '1.0',
     });
     
     final T data;
     final DateTime timestamp; // Always UTC
     final String geohash;
     final String version;
     
     Duration age(Clock clock) {
       assert(timestamp.isUtc, 'Timestamp must be UTC');
       return clock.nowUtc().difference(timestamp);
     }
     
     bool isExpired(Clock clock) => age(clock) > const Duration(hours: 6);
     
     // JSON serialization with version field and version checking
     Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJsonT);
     factory CacheEntry.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
       final version = json['version'] as String? ?? '1.0';
       if (version != '1.0') {
         throw UnsupportedVersionError(version);
       }
       // ... rest of deserialization
     }
   }
   ```

3. **Create CacheService interface** in `lib/services/cache_service.dart`:
   ```dart
3. **Create CacheError taxonomy and CacheService interface**:
   
   `lib/services/cache/cache_error.dart`:
   ```dart
   sealed class CacheError extends Equatable {
     const CacheError();
   }
   
   class StorageError extends CacheError {
     const StorageError(this.message, [this.cause]);
     final String message;
     final Object? cause;
     
     @override
     List<Object?> get props => [message, cause];
   }
   
   class SerializationError extends CacheError {
     const SerializationError(this.message, [this.cause]);
     final String message;
     final Object? cause;
     
     @override
     List<Object?> get props => [message, cause];
   }
   
   class UnsupportedVersionError extends CacheError {
     const UnsupportedVersionError(this.version);
     final String version;
     
     @override
     List<Object?> get props => [version];
   }
   ```
   
   `lib/services/cache_service.dart`:
   ```dart
   abstract class CacheService<T> {
     Future<Option<T>> get(String geohashKey);
     Future<Either<CacheError, void>> set({required double lat, required double lon, required T data});
     Future<Either<CacheError, void>> setWithKey({required String geohashKey, required T data});
     Future<bool> remove(String geohashKey);
     Future<void> clear();
     
     // Metadata and maintenance
     Future<CacheMetadata> getMetadata();
     Future<int> cleanup(); // LRU eviction
   }   abstract class FireRiskCache extends CacheService<FireRisk> {
     // FireRisk-specific convenience methods
     Future<Option<FireRisk>> getForCoordinates(double lat, double lon);
   }
   ```

4. **Contract tests** for all interfaces:
   - GeohashUtils.encode() deterministic output for same coordinates
   - CacheEntry TTL checking (fresh vs expired entries)
   - CacheService interface contract compliance
   - JSON round-trip serialization integrity

**Acceptance Criteria**:
- [ ] GeohashUtils.encode(55.9533, -3.1883, precision: 5) returns "gcpue"
- [ ] CacheEntry.isExpired correctly identifies entries older than 6 hours
- [ ] JSON serialization includes version field and handles corruption gracefully
- [ ] All interfaces defined with proper Either/Option return types
- [ ] Contract tests pass for all core components

---

## T002: TTL Enforcement & Size Management
**Files**: `lib/services/fire_risk_cache_impl.dart`, `lib/models/cache_metadata.dart`
**Labels**: spec:A5, gate:C1, gate:C5

Implement FireRiskCache with TTL enforcement, LRU eviction, and SharedPreferences storage:

1. **Create CacheMetadata** in `lib/models/cache_metadata.dart`:
   ```dart
   class CacheMetadata extends Equatable {
     const CacheMetadata({
       required this.totalEntries,
       required this.lastCleanup,
       this.accessLog = const {},
     });
     
     final int totalEntries;
     final DateTime lastCleanup;
     final Map<String, DateTime> accessLog;
     
     bool get isFull => totalEntries >= 100;
     String? get lruKey {
       if (accessLog.isEmpty) return null;
       return accessLog.entries
         .reduce((a, b) => a.value.isBefore(b.value) ? a : b).key;
     }
   }
   ```

2. **Implement FireRiskCacheImpl** in `lib/services/fire_risk_cache_impl.dart`:
   ```dart
   class FireRiskCacheImpl implements FireRiskCache {
     final SharedPreferences _prefs;
     final Clock _clock;
     static const String _metadataKey = 'cache_metadata';
     static const String _entryKeyPrefix = 'cache_entry_';
     
     FireRiskCacheImpl({required SharedPreferences prefs, Clock? clock})
       : _prefs = prefs,
         _clock = clock ?? SystemClock();
     
     @override
     Future<Option<FireRisk>> get(String geohashKey) async {
       try {
         final jsonStr = _prefs.getString('$_entryKeyPrefix$geohashKey');
         if (jsonStr == null) return none();
         
         final entry = CacheEntry.fromJson(jsonDecode(jsonStr), FireRisk.fromJson);
         if (entry.isExpired(_clock)) {
           await remove(geohashKey); // Cleanup expired entry
           return none();
         }
         
         await _updateAccessTime(geohashKey); // LRU tracking
         final cachedRisk = entry.data.copyWith(freshness: Freshness.cached);
         return some(cachedRisk);
       } catch (e) {
         // Corruption handling: log error, treat as cache miss (C5)
         _logger.warning('Cache corruption for key $geohashKey: $e');
         return none();
       }
     }
     
     @override
     Future<Either<CacheError, void>> set({required double lat, required double lon, required FireRisk data}) async {
       final geohash = GeohashUtils.encode(lat, lon, precision: 5);
       return await setWithKey(geohash, data);
     }
   }
   ```

3. **TTL and size management**:
   - Lazy expiration: check TTL on read, remove expired entries
   - LRU eviction when cache reaches 100 entries
   - Metadata tracking with access timestamps
   - SharedPreferences atomic operations for corruption safety

4. **Privacy compliance** (C2):
   - Use geohash keys for storage (inherent 4.9km privacy)
   - Log operations with LocationUtils.logRedact for coordinates
   - No raw coordinates in SharedPreferences keys

**Acceptance Criteria**:
- [ ] Expired entries (>6h) return cache miss and are removed on read
- [ ] Cache enforces 100 entry limit with LRU eviction
- [ ] Successful reads mark FireRisk with freshness=cached
- [ ] Corruption-safe JSON parsing with graceful degradation (C5)
- [ ] Privacy-compliant logging via geohash keys (C2)
- [ ] SharedPreferences operations are atomic and non-blocking

---

## T003: Comprehensive Test Coverage [P]
**Files**: `test/unit/utils/geohash_utils_test.dart`, `test/unit/services/fire_risk_cache_test.dart`, `test/integration/cache_persistence_test.dart`
**Labels**: spec:A5, gate:C1, gate:C5

Create comprehensive test suite covering TTL expiry, corruption handling, and size limits:

1. **Unit tests** in `test/unit/utils/geohash_utils_test.dart`:
   ```dart
   group('GeohashUtils', () {
     test('encode generates consistent geohash for same coordinates', () {
       final hash1 = GeohashUtils.encode(55.9533, -3.1883);
       final hash2 = GeohashUtils.encode(55.9533, -3.1883);
       expect(hash1, equals(hash2));
       expect(hash1, equals('gcpue')); // Known reference value
     });
     
     test('encode handles edge cases correctly', () {
       // Test poles, meridian crossing, equator
       expect(GeohashUtils.encode(90.0, 0.0), isNotEmpty);
       expect(GeohashUtils.encode(-90.0, 180.0), isNotEmpty);
       expect(GeohashUtils.encode(0.0, 0.0), isNotEmpty);
     });
   });
   ```

2. **Cache service tests** in `test/unit/services/fire_risk_cache_test.dart`:
   ```dart
   group('FireRiskCache TTL and Size Management', () {
     test('expired entries return cache miss', () async {
       // Store entry, mock time +7 hours, verify cache miss
       await cache.set(lat: 55.9533, lon: -3.1883, data: testFireRisk);
       
       // Mock time 7 hours later
       when(mockClock.nowUtc()).thenReturn(DateTime.now().toUtc().add(Duration(hours: 7)));
       
       final result = await cache.get('gcpue');
       expect(result.isNone(), true);
     });
     
     test('LRU eviction removes oldest accessed entry', () async {
       // Fill cache to 100 entries
       for (int i = 0; i < 100; i++) {
         await cache.set(lat: 55.0 + i * 0.01, lon: -3.0, data: testFireRisk);
       }
       
       // Access first entry to make it recent
       await cache.get(GeohashUtils.encode(55.0, -3.0));
       
       // Add 101st entry, verify LRU victim removed
       await cache.set(lat: 56.0, lon: -3.0, data: testFireRisk);
       
       final metadata = await cache.getMetadata();
       expect(metadata.totalEntries, equals(100));
     });
     
     test('unsupported version throws UnsupportedVersionError', () async {
       // Store malformed JSON with unsupported version
       final badJson = '{"version":"2.0","timestamp":1234567890,"geohash":"gcvwr","data":{}}';
       await mockPrefs.setString('cache_entry_gcvwr', badJson);
       
       expect(() => cache.get('gcvwr'), throwsA(isA<UnsupportedVersionError>()));
     });
     
     test('corrupted JSON handled gracefully', () async {
       // Manually corrupt SharedPreferences entry
       await mockPrefs.setString('cache_entry_gcpue', 'invalid json');
       
       final result = await cache.get('gcpue');
       expect(result.isNone(), true); // Graceful degradation
     });
   });
   ```

3. **Integration tests** in `test/integration/cache_persistence_test.dart`:
   ```dart
   group('Cache Persistence Integration', () {
     test('cache survives app restart', () async {
       // Store data, create new cache instance, verify persistence
       await cache.set(lat: 55.9533, lon: -3.1883, data: testFireRisk);
       
       // Simulate app restart with new cache instance
       final newCache = FireRiskCacheImpl(SharedPreferences.getInstance());
       final result = await newCache.get('gcpue');
       
       expect(result.isSome(), true);
       expect(result.value.freshness, equals(Freshness.cached));
     });
   });
   ```

4. **Test scenarios from quickstart.md**:
   - Geohash determinism and edge cases
   - TTL expiration with controlled time mocking
   - Size limit enforcement and LRU eviction
   - JSON corruption recovery
   - SharedPreferences persistence across sessions

**Acceptance Criteria**:
- [ ] Unit test coverage >95% for all cache components
- [ ] TTL expiry tests use controlled time mocking
- [ ] LRU eviction correctness verified with access pattern tracking
- [ ] Corruption handling tests verify graceful degradation (C5)
- [ ] Integration tests use real SharedPreferences instances
- [ ] Performance tests validate <200ms read, <100ms write targets
- [ ] All tests run without external dependencies

---

## T004: Documentation & CI Validation [P]
**Files**: `docs/CONTEXT.md`, `lib/services/fire_risk_cache_impl.dart` (inline docs)
**Labels**: spec:A5, gate:C1, gate:C2

Complete implementation with comprehensive documentation and CI validation:

1. **Update documentation** in `docs/CONTEXT.md`:
   ```markdown
   ## CacheService (A5)
   
   Local cache for FireRisk data with 6-hour TTL and geohash spatial keying.
   
   ### Architecture
   - **Storage**: SharedPreferences with JSON serialization
   - **Keying**: Geohash precision 5 (~4.9km spatial resolution)
   - **TTL**: 6-hour expiration with lazy cleanup
   - **Size**: Max 100 entries with LRU eviction
   - **Privacy**: Geohash keys provide inherent coordinate obfuscation
   
   ### Integration
   ```dart
   // FireRiskService integration (tier 3 fallback)
   final cached = await cacheService.get(geohash);
   if (cached.isSome()) {
     return cached.value; // Already marked freshness=cached
   }
   ```
   
   ### Performance
   - Read operations: <200ms target
   - Write operations: <100ms target
   - Non-blocking UI thread operations
   ```

2. **Comprehensive inline documentation**:
   - Class-level documentation for CacheService interface
   - Method-level documentation with examples
   - Performance characteristics and limitations
   - Constitutional compliance notes (C1, C2, C5)

3. **CI validation** in existing `.github/workflows/flutter.yml`:
   ```yaml
   # Verify new cache service passes all checks
   - name: Analyze code
     run: flutter analyze --no-pub
   - name: Run tests
     run: flutter test
   - name: Format check
     run: dart format --set-exit-if-changed .
   ```

4. **Usage examples and integration patterns**:
   ```dart
   // CORRECT: Privacy-compliant cache logging
   final geohash = GeohashUtils.encode(lat, lon);
   _logger.debug('Cache lookup for ${LocationUtils.logRedact(lat, lon)} → $geohash');
   
   // CORRECT: Graceful cache miss handling
   final cached = await cacheService.get(geohash);
   return cached.fold(
     () => await fetchFreshData(), // Cache miss fallback
     (data) => data,               // Cache hit with freshness=cached
   );
   
   // WRONG: Raw coordinates in logs
   _logger.info('Caching data for $lat, $lon'); // Violates C2 gate
   ```

**Acceptance Criteria**:
- [ ] CI pipeline passes: flutter analyze, flutter test, dart format
- [ ] Documentation includes architecture overview and integration examples
- [ ] Inline code documentation covers all public APIs
- [ ] Privacy regex testing: `/\d{2}\.\d{4,}/` must never match log output
- [ ] Performance characteristics documented with targets
- [ ] Usage examples show proper error handling and fallback patterns
- [ ] Constitutional compliance (C1, C2, C5) documented with concrete examples
- [ ] Concurrency safety: document SharedPreferences atomicity assumptions
- [ ] Version field validation in JSON parsing prevents deserialization errors

---

## Dependencies
- **T001 and T003 can run in parallel** [P] - Different file sets, no shared dependencies
- **T002 depends on T001** - Requires interfaces and models from T001
- **T003 requires T001-T002** - Tests need implementation to validate
- **T004 can run in parallel with T003** [P] - Documentation independent of test execution

## Parallel Execution Example
```bash
# Phase 1: Foundation (can run in parallel)
Task T001: Core Interfaces & Geohash Implementation [P]
Task T003: Unit test structure and contract tests [P]

# Phase 2: Implementation (sequential dependency)
Task T002: TTL Enforcement & Size Management (requires T001)

# Phase 3: Validation (can run in parallel)  
Task T003: Complete test implementation (requires T001-T002)
Task T004: Documentation & CI Validation [P]
```

## Validation Commands
```bash
# Run all CacheService tests
flutter test test/unit/utils/geohash_utils_test.dart
flutter test test/unit/services/fire_risk_cache_test.dart
flutter test test/integration/cache_persistence_test.dart

# Verify code quality
flutter analyze --no-pub
dart format --set-exit-if-changed .

# Manual testing scenarios
# 1. Store FireRisk → wait 6+ hours → verify cache miss
# 2. Fill cache to 100 entries → add one more → verify LRU eviction
# 3. Corrupt SharedPreferences → verify graceful recovery
```

---

**Total**: 4 atomic tasks implementing A5 CacheService with constitutional compliance (C1, C2, C5) and comprehensive test coverage including TTL enforcement, corruption handling, and privacy-compliant geohash spatial keying.