# Phase-1: Map Screen Enhancement & Google Maps Integration

## Spec Metadata
* **spec_id**: A10 (prospective)
* **depends_on**: [A9, A4, A2, A5]
* **feature**: "Map Screen Enhancement"  
* **goal**: "Enable visualization of active fire incidents using Google Maps SDK"

## Overview

Building on the **completed A9 blank MapScreen foundation**, Phase-1 transforms the placeholder into a **functional Google Maps interface** with wildfire data visualization. The navigation structure and routing are already established via go_router.

## Current Foundation (A9 Complete)
✅ **MapScreen scaffold** (`lib/features/map/screens/map_screen.dart`)  
✅ **Go_router navigation** with `/map` route  
✅ **Home→Map navigation** via `context.go('/map')`  
✅ **Accessibility compliance** with semantic labels  
✅ **Constitutional compliance** (C1, C3, C4)  

## Phase-1 Objectives

* **Replace placeholder** with Google Maps Flutter SDK integration
* **Add MapController** following existing HomeController pattern  
* **Implement ActiveFireService** using existing service architecture (fallback chain like FireRiskService)
* **Display fire incident markers** with source attribution and timestamps
* **Maintain location integration** with existing LocationResolver (A4)

## Scope for Phase-1

### Core Implementation
* **Google Maps Flutter SDK** integration replacing current placeholder
* **MapController** (ChangeNotifier pattern like HomeController)
* **MapState** sealed classes (MapLoading, MapSuccess, MapError)
* **ActiveFireService** with EFFIS→Mock fallback pattern
* **Fire incident markers** with info windows showing source + timestamp
* **Map centering** using existing LocationResolver service
* **Visible region bounds** retrieved from GoogleMapController via `getVisibleRegion()` on camera idle
* **User interaction** - pan/zoom freely with debounced refresh (1s) when camera movement ends

### Enhanced Navigation
* **Existing go_router structure** remains unchanged (`/` and `/map`)
* **Optional bottom navigation** (if desired instead of current button approach)
* **Back navigation** maintains existing behavior

## Architectural Alignment

### Service Pattern (Following FireRiskService A2)
```dart
abstract class ActiveFireService {
  Future<Either<ServiceError, List<FireIncident>>> getActiveFires({
    required LatLngBounds bounds,
    Duration? deadline,
  });
}

// Implementation with fallback chain
class ActiveFireServiceImpl implements ActiveFireService {
  // 1. EFFIS Active Fires → 2. Mock (never fails)
}
```

### State Management (Following HomeController A6)
```dart
sealed class MapState extends Equatable {
  const MapState();
}

class MapLoading extends MapState {}
class MapSuccess extends MapState {
  final List<FireIncident> incidents;
  final LatLng centerLocation;
}
class MapError extends MapState {
  final String message;
  final List<FireIncident>? cachedIncidents;
}

class MapController extends ChangeNotifier {
  // Same dependency injection pattern as HomeController
}
```

### Data Models (Following FireRisk pattern)
```dart
class FireIncident extends Equatable {
  final LatLng location;
  final DataSource source;           // effis, mock (same as FireRisk)
  final Freshness freshness;         // live, cached, mock (same as FireRisk)
  final DateTime timestamp;
  final String intensity;            // "low", "moderate", "high"
  final String? description;
}
```

## Privacy & Compliance (Existing Patterns)

* **C2 Privacy**: Use existing `LocationUtils.logRedact()` for coordinate logging
* **C3 Accessibility**: Marker info windows with semantic labels; map controls (zoom, recenter) accessible via keyboard/VoiceOver navigation
* **C4 Transparency**: Source chips ("EFFIS", "Mock") and "Updated X minutes ago"
* **C5 Resilience**: Never-fail guarantee via mock fallback

## Dependencies & Integration

### Required pubspec.yaml Additions
```yaml
dependencies:
  google_maps_flutter: ^2.5.0  # Google Maps SDK integration
  geojson: ^1.0.0              # EFFIS GeoJSON parsing support
```

### Service Integration
* **LocationResolver (A4)**: Use existing `getLatLng()` for map centering
* **CacheService (A5)**: Optional caching with ≤3h TTL; cached incidents display "Cached" badge with timestamp
* **Existing theme**: Use `WildfireTheme` colors for markers and optional MapStyle JSON for dark/light mode consistency

## Modified Performance Targets

* **Initial map render**: ≤3s (Google Maps loading time)
* **Marker rendering**: ≤50 markers without lag (reduced from your 100)
* **Memory usage**: ≤75MB total (increased from Home-only 50MB)
* **Service timeout**: Follow existing 8s budget pattern

## Implementation Priority

1. **Google Maps integration** (replace placeholder)
2. **MapController + MapState** (mirror HomeController pattern)  
3. **ActiveFireService mock implementation** (test with static data)
4. **EFFIS Active Fires endpoint** (real data integration)
5. **Marker rendering + info windows** (with source attribution)

## Non-Goals (Phase-1)
* No community reporting or polygon drawing (deferred to Phase-2/A10+)
* No route guidance or evacuation mapping  
* No offline map tiles caching
* No push notifications integration
* No fire polygon overlays (deferred to future A-series specifications)

## Data Sources & Integration

### EFFIS Active Fire Endpoint
* **Format**: EFFIS returns GeoJSON; parsing requires converting features to `FireIncident` objects
* **Dependencies**: Consider `http` + `geojson` package for decoding
* **Mock Data**: Static incidents defined in `/assets/mock/active_fires.json`, loaded via rootBundle for deterministic testing

### Map Interaction States
* **Loading**: Display skeleton markers while fetching data
* **Offline fallback**: Show placeholder map state when Google Maps tiles fail (C5 resilience)
* **Marker clustering**: Optional enhancement when incidents >50 for scalability

## Integration Test Coverage

Following existing A-series testing patterns:

1. **EFFIS Success**: Live data visible with correct source labeling  
2. **Mock Fallback**: Map displays mock markers when EFFIS fails  
3. **Privacy Compliance**: No raw lat/lon in logs (`LocationUtils.logRedact()`)  
4. **Accessibility**: All controls ≥44dp, keyboard/VoiceOver navigation  
5. **Performance**: ≤3s render on average devices  
6. **Cache Behavior**: Cached incidents show proper "Cached" badges with timestamps

## Next Steps

1. **Add Google Maps dependency** and platform configuration (API_KEY for Android/iOS)
2. **Configure API_KEY** for Android (`AndroidManifest.xml`) and iOS (`AppDelegate.swift`)
3. **Scaffold MapController** with LocationResolver injection
4. **Create ActiveFireService interface** following A2 pattern
5. **Implement mock fire incidents** from JSON assets for visual testing
6. **Research EFFIS Active Fire GeoJSON** endpoint format and integration

---

**References**
* Constitution v1.0 (root)
* `docs/DATA-SOURCES.md`
* Google Maps Flutter Plugin v2.x documentation
* EFFIS Active Fire Data Service (GeoJSON/WMS)
* A9 MapScreen Foundation (`specs/010-a9-add-blank/`)