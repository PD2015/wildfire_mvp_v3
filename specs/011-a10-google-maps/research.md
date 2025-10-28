# Phase 0: Research & Design Decisions

**Feature**: A10 – Google Maps MVP Map  
**Date**: October 19, 2025  
**Status**: Complete

## Research Questions Resolved

### 1. Google Maps Flutter SDK Integration

**Decision**: Use `google_maps_flutter: ^2.5.0` package

**Rationale**:
- Official Google plugin with Flutter team support
- Proven stability in production apps (A9 ADR chose Google Maps for MVP speed)
- Native platform views provide 60fps performance
- Existing A9 MapScreen scaffold ready for integration
- Well-documented API key management per platform

**Alternatives Considered**:
- **Mapbox Flutter**: Better offline support, but requires migration effort and subscription costs
- **flutter_map**: Open-source, but lacks native rendering performance for 50+ markers
- **Web-only solutions**: Deferred - A10 targets mobile first

**Implementation Notes**:
- API keys injected via environment variables (never committed)
- Platform-specific configuration: `AndroidManifest.xml` (Android), `AppDelegate.swift` (iOS)
- Key restrictions: SHA-1 fingerprint (Android), bundle ID (iOS)
- Cost monitoring: Free tier 28,000 map loads/month; alarms at 50% (14k) and 80% (22.4k)

---

### 2. EFFIS WFS Integration for Fire Markers

**Decision**: Use EFFIS WFS (Web Feature Service) burnt areas endpoint with bbox queries

**Rationale**:
- Existing EFFIS integration in A2 provides authentication patterns
- WFS returns GeoJSON features (standardized format)
- Bbox queries limit data to visible map region (performance optimization)
- Real-time data from European Forest Fire Information System
- No additional authentication required beyond existing EFFIS setup

**Alternatives Considered**:
- **EFFIS WMS GetMap**: Returns raster images, not suitable for marker extraction
- **SEPA Active Fires API**: Scotland-only, insufficient European coverage
- **NASA FIRMS**: Global coverage, but 3-12 hour data latency vs EFFIS near-real-time

**API Details**:
```
Endpoint: ies-ows.jrc.ec.europa.eu/wfs
Layer: burnt_areas_current_year
Format: GeoJSON
Query params: bbox={minLon},{minLat},{maxLon},{maxLat},EPSG:4326
```

**Implementation Notes**:
- Parse GeoJSON features to `FireIncident` model
- Extract geometry.coordinates for marker lat/lon
- Map properties.intensity → "low"/"moderate"/"high"
- Include properties.timestamp for "Updated X minutes ago" display
- Fallback chain: EFFIS → SEPA (Scotland only) → Cache (A5) → Mock

---

### 3. MapController State Management Pattern

**Decision**: Mirror HomeController architecture from A6 using ChangeNotifier

**Rationale**:
- Consistency with existing codebase (A6 HomeController pattern)
- Proven lifecycle management (initState → loadData → dispose)
- Simple dependency injection via constructor
- No additional state management libraries required
- Widget rebuilds only on notifyListeners() calls (performance)

**Alternatives Considered**:
- **flutter_bloc**: Heavier than needed for single-screen state
- **Riverpod**: Migration effort, inconsistent with A2-A6 patterns
- **StatefulWidget inline**: Poor separation of concerns, harder testing

**State Model**:
```dart
sealed class MapState extends Equatable {
  const MapState();
}

class MapLoading extends MapState {}
class MapSuccess extends MapState {
  final List<FireIncident> incidents;
  final LatLng centerLocation;
  final Freshness freshness;
}
class MapError extends MapState {
  final String message;
  final List<FireIncident>? cachedIncidents;
}
```

**Implementation Notes**:
- MapController injected with: LocationResolver (A4), FireLocationService (new), CacheService (A5)
- `loadMapData()` method: get location → get fires in bbox → update state
- Camera idle debounce (1s) before refreshing markers
- Dispose GoogleMapController on cleanup

---

### 4. Point-Based Risk Assessment ("Check risk here")

**Decision**: Reuse existing FireRiskService with EFFIS WMS GetFeatureInfo

**Rationale**:
- A2 FireRiskService already implements EFFIS WMS queries
- GetFeatureInfo returns FWI value at specific lat/lon
- No new service infrastructure needed
- Existing fallback chain (EFFIS → SEPA → Cache → Mock) applies
- Display as chip only (no overlay in A10)

**Alternatives Considered**:
- **Separate point query service**: Unnecessary duplication of A2
- **Interpolate from marker data**: Inaccurate, markers are historical burnt areas
- **Polygon risk overlays**: Out of scope for A10 (deferred to A11+)

**API Details**:
```
Endpoint: ies-ows.jrc.ec.europa.eu/wms
Request: GetFeatureInfo
Params: LAYERS=nasa_geos5.query, QUERY_LAYERS=nasa_geos5.query, X={pixel}, Y={pixel}, I={lon}, J={lat}
Response: text/plain with FWI value
```

**Implementation Notes**:
- On map long-press → call `FireRiskService.getCurrent(lat, lon)`
- Parse FWI → risk level (Low/Moderate/High/Very High/Extreme)
- Display in `RiskAssessmentChip` with source label and timestamp
- Cache results via A5 CacheService (6h TTL)

---

### 5. Caching Strategy for Fire Locations

**Decision**: Extend A5 CacheService for `List<FireIncident>` with 6h TTL

**Rationale**:
- Existing CacheService infrastructure from A5
- Geohash spatial keying already implemented
- 6h TTL matches fire data update frequency
- LRU eviction prevents unbounded growth
- SharedPreferences persistence across app restarts

**Alternatives Considered**:
- **No caching**: Poor offline experience, unnecessary API calls
- **3h TTL**: Too aggressive, EFFIS updates every 6 hours
- **24h TTL**: Stale data risk for active fire situations
- **SQLite**: Overkill for simple key-value cache

**Cache Key Strategy**:
```dart
// Bbox center + zoom level → geohash key
String cacheKey = GeohashUtils.encode(
  centerLat, 
  centerLon, 
  precision: zoomToGeohashPrecision(zoomLevel)
);
```

**Implementation Notes**:
- Cache bbox queries with geohash key for spatial locality
- On cache hit: display markers with "Cached" badge + timestamp
- On cache miss: fetch from EFFIS → store in cache
- Evict oldest entries when cache size > 100 (LRU)

---

### 6. Feature Flag Strategy (MAP_LIVE_DATA)

**Decision**: Environment-based feature flag, default off for tests

**Rationale**:
- Deterministic testing with mock data
- Gradual rollout to production (staged enablement)
- Prevents accidental EFFIS API quota consumption in CI
- Matches existing test patterns (A2 uses mock by default)

**Implementation**:
```dart
// In FireLocationService
final bool useLiveData = const bool.fromEnvironment('MAP_LIVE_DATA', defaultValue: false);

Future<List<FireIncident>> getActiveFires(LatLngBounds bounds) async {
  if (!useLiveData) {
    return _getMockFireIncidents(bounds);
  }
  // ... EFFIS WFS call
}
```

**Rollout Plan**:
1. **Phase 1**: Internal testing with MAP_LIVE_DATA=true
2. **Phase 2**: Beta users (5% traffic) with live data
3. **Phase 3**: Full rollout after monitoring confirms <5% error rate
4. **Runbook**: Document EFFIS endpoint changes, fallback procedures

---

### 7. Logging & Privacy Compliance

**Decision**: Wrap all logging in ConstitutionLogger, use LocationUtils.logRedact()

**Rationale**:
- C2 constitutional gate: no PII in logs
- Existing LocationUtils.logRedact() from A2 (2dp coordinate precision)
- Structured logging for observability
- Audit trail for constitutional compliance

**Implementation Pattern**:
```dart
class ConstitutionLogger {
  static void logMapEvent(String event, {LatLng? location, Map<String, dynamic>? data}) {
    final redactedLocation = location != null 
      ? LocationUtils.logRedact(location.latitude, location.longitude)
      : 'N/A';
    
    _logger.info('MAP_EVENT: $event | location=$redactedLocation | data=$data');
  }
}
```

**Log Examples**:
- ✅ `MAP_EVENT: marker_tap | location=55.95,-3.19 | source=EFFIS`
- ❌ `Marker at 55.953252,-3.188267` (too precise, violates C2)

---

### 8. Performance Optimization Strategies

**Decision**: Multi-pronged approach to meet ≤3s interactive, ≤50 markers targets

**Strategies**:
1. **Lazy marker rendering**: Only create markers for visible region
2. **Debounced refresh**: 1s delay after camera idle before fetching new data
3. **Bbox optimization**: Query only visible region + 10% padding
4. **Cache-first load**: Show cached markers immediately, refresh in background
5. **Marker clustering**: Deferred to A11 if >50 markers needed

**Rationale**:
- Google Maps native rendering handles 50-100 markers at 60fps
- Network latency is primary bottleneck (addressed by cache-first)
- Debouncing prevents excessive API calls during pan/zoom
- Visible region queries minimize data transfer

**Performance Monitoring**:
- Track map load time: `performance_timer_start('map_load')` → `performance_timer_end('map_load')`
- Alert if >3s on 5 consecutive loads
- Memory profiling in widget tests: assert memory delta ≤75MB

---

## Dependencies Validated

| Dependency | Version | Purpose | Status |
|------------|---------|---------|--------|
| google_maps_flutter | ^2.5.0 | Map rendering | ✅ Stable, production-ready |
| go_router | 14.8.1 | Navigation (A9) | ✅ Already integrated |
| http | latest | EFFIS API calls | ✅ Used in A2 |
| dartz | latest | Either types | ✅ Used in A2 |
| equatable | latest | Value objects | ✅ Used in A2-A6 |
| flutter_bloc | latest | Inherited state | ✅ Used in A2 |
| shared_preferences | latest | Cache storage (A5) | ✅ Already integrated |

**No new dependencies required** beyond google_maps_flutter.

---

## Risk Mitigation Strategies

### Risk 1: Google Maps API Key Misconfiguration
**Impact**: Map fails to load, critical feature blocker  
**Mitigation**:
- Document key setup in quickstart.md
- Add validation step in CI: check keys present in environment
- Provide clear error messages: "Google Maps API key missing"
- Test key restrictions with debug/release builds

### Risk 2: EFFIS WFS Schema Changes
**Impact**: Marker parsing fails, fallback to mock  
**Mitigation**:
- Weekly automated integration test against live EFFIS API
- Schema validation on GeoJSON response
- Graceful degradation to cached/mock data
- Alert on repeated parse failures (Sentry/Firebase Crashlytics)

### Risk 3: Map Quota Exhaustion
**Impact**: Cost overruns, service degradation  
**Mitigation**:
- Set cost alarms at 50% (14k) and 80% (22.4k) of free tier
- Cache-first strategy reduces API calls
- Monitor daily usage via Google Cloud Console
- Implement rate limiting if approaching quota

### Risk 4: Performance Degradation with >50 Markers
**Impact**: Jank, poor UX  
**Mitigation**:
- Bbox queries limit to visible region
- Performance tests in CI: assert <16ms frame time
- Marker clustering deferred to A11 (out of scope for A10)
- Alert if marker count >60 in production

---

## Open Questions & Future Work

### Deferred to A11+:
- Marker clustering for >50 incidents
- Polygon risk overlays (heatmap)
- Offline map tiles
- Route planning / evacuation guidance
- Push notifications for nearby fires

### Requires Clarification (if any):
- None - all technical unknowns resolved

---

**Phase 0 Complete**: All NEEDS CLARIFICATION items resolved. Ready for Phase 1 (data model, contracts, quickstart).
