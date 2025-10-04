# WildFire Prototype — Context Pack

## What We’re Building
WildFire MVP prototype for Scotland. **Phase-0 goal**: display current wildfire risk on the Home screen.
- Primary data: EFFIS Fire Weather Index (FWI)
- Fallbacks: SEPA (Scotland only) → Cache → Mock
- Focus: proving data feeds + hooks, not emergency-grade reliability yet.

## Scope for Phase-0
- Risk data service + simple Home screen banner
- No notifications, authentication, or advanced map features
- Map overlays and reporting deferred to later phases

## Guardrails (from Constitution)
- No secrets in repo; env/runtime config only
- All data must show **Last updated** timestamp + source label
- Use official wildfire risk color scale only
- A11y: semantic labels + ≥44dp targets
- Clear offline/error/cached states (no silent fails)

## Data Chain (for Phase-0)
**FireRiskService Fallback Decision Tree**:
```
getCurrent(lat, lon) → FireRisk
    ↓
[Validate coordinates] → Left(ApiError) if invalid
    ↓
[1. EFFIS] (3s timeout) → Success? → FireRisk{source: effis, freshness: live}
    ↓ Fail
[2. SEPA] (2s timeout, Scotland only) → Success? → FireRisk{source: sepa, freshness: live}  
    ↓ Fail
[3. Cache] (1s timeout) → Hit? → FireRisk{source: original, freshness: cached}
    ↓ Miss
[4. Mock] (<100ms, never fails) → FireRisk{source: mock, freshness: mock}
```

**Service Details**:
1. **EFFIS** — Fire Weather Index via WMS GetFeatureInfo (A1 implementation)
   - Global coverage, primary data source
   - Returns EffisFwiResult → converted to FireRisk
   - 3-second timeout within 8-second total budget
2. **SEPA** — Scotland Environment Protection Agency fallback
   - **Geographic bounds**: 54.6-60.9°N, -9.0-1.0°E (includes St Kilda, Orkney, Shetland)
   - Only attempted when `isInScotland(lat, lon) == true` AND EFFIS fails
   - 2-second timeout for Scottish-specific fire risk data
3. **Cache** — TTL 6h for resilience
   - Preserves original source attribution in cached FireRisk
   - 1-second timeout for cache lookups
4. **Mock** — clearly tagged as fallback when no data available
   - **Never-fail guarantee**: Always succeeds within 100ms
   - Uses deterministic geohash-based risk levels for consistency

**Privacy Compliance (C2)**:
- All logging uses `GeographicUtils.logRedact(lat, lon)` → rounds to 2dp
- No raw coordinates or place names in logs or telemetry
- Geographic resolution ~1.1km prevents exact location identification

## LocationResolver Service (A4)
**Headless Location Architecture** — service provides coordinates, UI handles prompts:

**5-Tier Fallback Chain** (2.5s total budget):
```
getLatLon(allowDefault) → Either<LocationError, LatLng>
    ↓
[1. Last Known Position] (<100ms) → Available? → Return immediately
    ↓ Unavailable
[2. GPS Fix] (2s timeout) → Permission granted? → GPS coordinates
    ↓ Denied/Failed
[3. SharedPreferences Cache] (<100ms) → Manual location cached? → Return cached
    ↓ No cache
[4. Manual Entry] → allowDefault=false? → Left(LocationError) → Caller opens dialog
    ↓ allowDefault=true
[5. Scotland Centroid] → LatLng(56.5, -4.2) [rural/central bias avoidance]
```

**Scotland Centroid Choice**: `LatLng(56.5, -4.2)` represents central rural location, avoiding urban bias toward Edinburgh/Glasgow while remaining within Scotland's geographic center for representative wildfire risk data.

**Privacy & Logging (C2)**:
```dart
// CORRECT: Privacy-preserving coordinate logging
_logger.info('Location resolved: ${LocationUtils.logRedact(lat, lon)}');
// Outputs: "Location resolved: 56.50,-4.20"

// WRONG: Raw coordinates expose PII - violates C2 gate
_logger.info('Location: $lat,$lon'); // NEVER do this
```

**Integration Pattern** (A6/Home responsibility):
- LocationResolver returns `Left(LocationError)` when manual entry needed
- A6/Home opens `ManualLocationDialog` on receiving `Left(...)`
- User enters coordinates → A6/Home calls `saveManual(LatLng, placeName?)`
- Subsequent calls use cached coordinates from tier 3

**Persistence & Resilience (C5)**:
- SharedPreferences with version compatibility (`manual_location_version: '1.0'`)
- Graceful corruption handling → never crash, fallback to Scotland centroid
- Web/emulator platform detection → skip GPS attempts, use cache/manual/default

## CacheService (A5)

Local cache for FireRisk data with 6-hour TTL and geohash spatial keying.

**Architecture**:
- **Storage**: SharedPreferences with JSON serialization
- **Keying**: Geohash precision 5 (~4.9km spatial resolution)
- **TTL**: 6-hour expiration with lazy cleanup
- **Size**: Max 100 entries with LRU eviction
- **Timestamps**: UTC discipline prevents timezone corruption
- **Privacy**: Geohash keys provide inherent coordinate obfuscation

**Integration** (FireRiskService fallback tier 3):
```dart
// Cache lookup in fallback chain
final geohash = GeohashUtils.encode(lat, lon, precision: 5);
final cached = await cacheService.get(geohash);
if (cached.isSome()) {
  return cached.value; // Already marked freshness=cached
}
// Continue to mock fallback...
```

**Performance Targets**:
- Read operations: <200ms target
- Write operations: <100ms target
- Non-blocking UI thread operations

**Privacy Compliance (C2)**:
- Geohash keys in SharedPreferences (no raw coordinates)
- ~4.9km spatial resolution prevents precise location identification
- All cache operations use geohash logging instead of raw lat/lon

**Resilience (C5)**:
- Corruption-safe JSON parsing with graceful cache miss fallback
- Version field in stored entries prevents deserialization errors
- Clock injection enables deterministic TTL testing

## Non-Goals
- Emergency compliance or alert certification
- Push notifications
- Fire polygon rendering
- Multi-user accounts

## References
- Constitution v1.0 (root)
- `docs/DATA-SOURCES.md`
- `scripts/allowed_colors.txt` (palette)
- `lib/theme/risk_palette.dart` (when added)

