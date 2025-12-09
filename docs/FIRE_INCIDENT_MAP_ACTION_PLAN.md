---
title: Fire Incident Map - Action Plan
status: active
last_updated: 2025-12-09
category: explanation
subcategory: planning
related:
  - reference/EFFIS_API_ENDPOINTS.md
  - DATA-SOURCES.md
  - ../lib/models/fire_incident.dart
  - ../lib/features/map/screens/map_screen.dart
changelog:
  - 2025-12-09: Revised with architectural decisions, clustering rules, user settings, phase details
  - 2025-12-09: Initial draft with two-layer approach
---

# Fire Incident Map - Action Plan

This document outlines what we should show users on the fire incident map to add value for live fire tracking and educate them about wildfires in Scotland.

---

## Executive Summary

Based on research into EFFIS, GWIS, NASA FIRMS, and the Strathclyde tracker, we implement a **two-layer approach**:

| Layer | Data Source | Display | User Value |
|-------|-------------|---------|------------|
| **Active Hotspots** | GWIS `viirs.hs.today` | 375m semi-transparent squares | "Where fires are burning NOW" |
| **Burnt Areas** | EFFIS `modis.ba.poly.season` | Simplified polygons (Douglas-Peucker 100m) | Verified fire damage with authoritative size |

---

## Current Architecture Review

### ✅ What's Already Built (Phase 1 Complete)

| Component | Location | Status |
|-----------|----------|--------|
| **MapScreen** | `lib/features/map/screens/map_screen.dart` | ✅ 784 lines, Google Maps integration |
| **MapController** | `lib/features/map/controllers/map_controller.dart` | ✅ ChangeNotifier state management |
| **FireIncident Model** | `lib/models/fire_incident.dart` | ✅ 387 lines, sensor fields, polygon support |
| **Fire Details Bottom Sheet** | `lib/widgets/fire_details_bottom_sheet.dart` | ✅ 604 lines, distance/bearing display |
| **Polygon Support** | `lib/features/map/utils/polygon_style_helper.dart` | ✅ Intensity-based styling |
| **Marker Icons** | `lib/features/map/utils/marker_icon_helper.dart` | ✅ Custom flame icons |
| **UI Widgets** | `lib/features/map/widgets/` | ✅ Source chip, timestamp chip, polygon toggle |
| **Home Screen** | `lib/screens/home_screen.dart` | ✅ Risk banner, location card |
| **Mock Data** | `assets/mock/active_fires.json` | ⚠️ Needs restructuring (see below) |

### 🔧 What Needs Refactoring

| Item | Current State | Target State |
|------|---------------|--------------|
| `FireIncident` model | Single type | Add `enum FireDataType { hotspot, burntArea }` |
| `FireIncident` model | No simplification flag | Add `isSimplified: bool` for UI messaging |
| Mock data | Polygons only | Separate hotspot points + burnt area polygons |
| Bottom Sheet | Generic display | Contextual labels per `dataType` |

---

## What We Should Show Users

### 1. Active Fire Hotspots (Real-Time Layer)

**Data Source:** GWIS WMS - `viirs.hs.today` (rolling 24h) or `viirs.hs.week` (rolling 7 days)

**Display as:** 375m × 375m semi-transparent squares (not pin markers)

This matches how FIRMS, EFFIS, and other viewers display hotspots - as coloured grid cells representing the satellite detection pixel. Each square shows the actual detection area.

#### Hotspot Clustering Rules

When multiple hotspots are close together, they need to be clustered for usability:

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| **Clustering zoom threshold** | Zoom < 10 | At zoom 10+, individual 375m squares are visible and tappable |
| **Clustering distance** | 750m (2× pixel size) | Detections within 750m are likely the same fire event |
| **Minimum tap target** | 44dp | Constitutional C3 accessibility requirement |

**Clustering behaviour:**

| Zoom Level | Display | Interaction |
|------------|---------|-------------|
| < 8 | Clustered circles with count badge ("5 detections") | Tap zooms to cluster extent |
| 8-10 | Merged polygon outline around nearby hotspots | Tap shows summary: "5 detections, strongest: 45 MW" |
| ≥ 10 | Individual 375m squares | Tap any square for that hotspot's details |

**On tap (individual hotspot):** Show bottom sheet with:
- Detection time (relative: "2 hours ago")
- Satellite sensor (e.g., "VIIRS on NOAA-21")
- Confidence level (e.g., "High 95%")
- FRP intensity (e.g., "Strong - 45 MW")
- Educational label: "Active Hotspot"

**On tap (cluster):** Show list bottom sheet with all detections, sorted by FRP (strongest first).

**Educational label in details sheet:**
> 🔥 **Active Hotspot** - Satellite-detected thermal anomaly in the last 24 hours. Location accurate to ~375 metres. The actual fire may be smaller or larger than this square suggests.

---

### 2. Burnt Areas (Verified Layer)

**Data Source:** EFFIS WFS - `modis.ba.poly.season`

**Display as:** Semi-transparent polygons (35% opacity) using RiskPalette colours, simplified for display

#### Polygon Simplification

EFFIS burnt area polygons can have 22,000+ coordinate points (e.g., Dava Moor fire). These are simplified for rendering performance.

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| **Algorithm** | Douglas-Peucker | Industry standard, predictable behaviour |
| **Tolerance** | 100m | Balance between accuracy and performance |
| **Point limit** | 500 points max | Prevents rendering lag on mobile |
| **Original available?** | No (performance) | 100m tolerance is sufficient for visual display |

**Simplification notice in UI:**
> ⚠️ Boundary simplified for display. Official size: [AREA_HA] hectares.

The `AREA_HA` from EFFIS is **always** the authoritative figure, regardless of how the polygon appears on screen.

**Properties to show:**
| Property | Display Label | Example |
|----------|---------------|---------|
| `AREA_HA` | "Burnt Area" | "9,809 hectares" |
| `FIREDATE` | "First Detected" | "28 June 2025" |
| `LASTUPDATE` | "Last Updated" | "9 July 2025" |
| Land cover breakdown | "Affected Terrain" | Horizontal bar chart |

**Educational label in details sheet:**
> 🗺️ **Verified Burnt Area** - Confirmed fire perimeter mapped by EFFIS after the fire was contained. Boundary simplified for display; official size is satellite-verified.

---

### 3. User Location Context (Phase 4)

**Location:** Expanded Risk Banner on Home Screen

The current Risk Banner will be enhanced to include fire proximity context:

| Feature | Display Location | Implementation |
|---------|------------------|----------------|
| **Active fires count** | Risk Banner subtitle | "2 active fires within [X] km" |
| **Distance to nearest fire** | Risk Banner or tap for details | "Nearest: 45 km NW" |
| **Distance/Bearing** | Fire Details Bottom Sheet | Already implemented ✅ |
| **Wind direction/strength** | Risk Banner expansion (future) | Weather data integration (separate feature) |

**Note:** Direction indicator (compass arrow) **removed** from scope - the current distance + bearing text display (e.g., "45 km NW") is clearer and doesn't require device orientation tracking.

#### User Distance Preference

The "near me" distance threshold is configurable by the user:

| Setting | Default | Storage | UI Location |
|---------|---------|---------|-------------|
| **Alert distance** | 25 km | `SharedPreferences: alert_distance_km` | First-run prompt + Settings |
| **Options** | 10 km, 25 km, 50 km, 100 km | Dropdown/Slider | Settings screen |

**First-run flow:**
1. User opens app for first time
2. After location permission, show: "Alert me when fires are detected within: [25 km ▼]"
3. User selects preference, stored for future sessions
4. Can be changed in Settings > Notifications

**Future:** Push notifications when fire detected within user's chosen distance (requires Firebase, out of MVP scope).

---

### 4. Time-Based Filtering

**Location:** Horizontal filter chips below map controls (top-right area)

| Filter | Data Shown | Default? |
|--------|------------|----------|
| "Today" | Hotspots from last 24h | ✅ Yes |
| "This Week" | Hotspots from last 7 days | No |
| "This Season" | Burnt areas from current fire season (Mar-Sep) | No |
| "Last Season" | Previous year's burnt areas (educational) | No |

**Season logic:**
- **Current season:** March 1 → September 30 of current year
- **Last Season toggle:** Shows previous year's burnt areas alongside current data
- **Season reset:** On March 1, "Last Season" switches to show the just-ended season

**Why "Last Season"?**
- Educational value: Users can see extent of previous fires
- Context: "This area burned last year" helps understanding
- Visual distinction: Last season polygons use dashed outlines + muted colours

---

## What NOT to Show (Avoid Confusion)

### ❌ Don't: Calculate "fire area" from hotspot pixels

**Why:** NASA explicitly warns: "It is not recommended to use active fire locations to estimate burned area"

### ❌ Don't: Mix hotspots and burnt areas without visual distinction

**Instead:** 
- Hotspots: 375m orange/red squares (solid edges)
- Burnt areas current: Polygons with solid edges
- Burnt areas last season: Polygons with dashed edges + muted colours

### ❌ Don't: Use stale EFFIS hotspot endpoint

**Why:** `/effis` hotspots stopped syncing October 2021. Always use GWIS `/gwis`.

---

## Implementation Phases

### Phase 1: Foundation ✅ COMPLETE
- [x] Map with Google Maps integration
- [x] FireIncident model with sensor fields
- [x] Fire details bottom sheet with distance/bearing
- [x] Mock data with polygons
- [x] Polygon visibility toggle
- [x] Custom flame marker icons

### Phase 2: Live GWIS Hotspots
**Goal:** Display real-time fire detections as 375m squares with clustering

| Task | Component | Acceptance Criteria |
|------|-----------|---------------------|
| 2.1 | `GwisHotspotService` | Fetches `viirs.hs.today` via WMS GetFeatureInfo |
| 2.2 | `HotspotSquareBuilder` | Converts point to 375m polygon around centroid |
| 2.3 | `HotspotClusterer` | Groups hotspots within 750m at zoom < 10 |
| 2.4 | Time filter chips | Today / This Week toggle |
| 2.5 | Bottom sheet labels | "Active Hotspot" educational text |
| 2.6 | Tests | Unit tests for clustering logic, widget tests for display |

### Phase 3: EFFIS Burnt Areas
**Goal:** Display verified fire perimeters with simplification

| Task | Component | Acceptance Criteria |
|------|-----------|---------------------|
| 3.1 | `EffisBurntAreaService` | Fetches `modis.ba.poly.season` via WFS |
| 3.2 | `PolygonSimplifier` | Douglas-Peucker at 100m tolerance, max 500 points |
| 3.3 | `FireIncident.isSimplified` | Flag for UI messaging |
| 3.4 | Land cover display | Horizontal bar chart in bottom sheet |
| 3.5 | Bottom sheet labels | "Verified Burnt Area" + simplification notice |
| 3.6 | Tests | Simplification accuracy tests, rendering performance tests |

### Phase 4: User Context
**Goal:** Integrate fire proximity into Home Screen Risk Banner

| Task | Component | Acceptance Criteria |
|------|-----------|---------------------|
| 4.1 | `FireProximityService` | Calculates nearest fire + count within radius |
| 4.2 | Risk Banner expansion | Shows "2 fires within 25 km" when applicable |
| 4.3 | User distance preference | First-run prompt + Settings storage |
| 4.4 | Settings screen | Distance threshold dropdown (10/25/50/100 km) |
| 4.5 | Tests | Distance calculation tests, preference persistence tests |

### Phase 5: Historical & Education
**Goal:** Educational features for fire awareness

| Task | Component | Location | Acceptance Criteria |
|------|-----------|----------|---------------------|
| 5.1 | `MapLegendSheet` | FAB on MapScreen → bottom sheet | Shows symbol meanings |
| 5.2 | `FireDataInfoSheet` | ℹ️ icon in MapScreen AppBar → modal | Global explanation |
| 5.3 | Last Season filter | Time filter chips | Dashed polygons for previous year |
| 5.4 | First-time tooltip | MapScreen overlay | "Tap a fire to see details" |
| 5.5 | `hasSeenMapOnboarding` | SharedPreferences | Tooltip shown once only |
| 5.6 | Tests | Widget tests for info sheets, tooltip visibility tests |

---

## UI Component Specifications

### 5.1 MapLegendSheet

**Trigger:** Floating action button (bottom-right, above zoom controls)
**Icon:** `Icons.layers` or custom legend icon
**Type:** Modal bottom sheet

**Content:**
```
┌─────────────────────────────────────┐
│  Map Legend                      ✕  │
├─────────────────────────────────────┤
│  🟧 Active Hotspot (last 24h)       │
│     Satellite-detected fire         │
│                                     │
│  🟫 Verified Burnt Area             │
│     Confirmed fire perimeter        │
│                                     │
│  ┄┄ Last Season Fire                │
│     Previous year's burnt area      │
│                                     │
│  Intensity Scale:                   │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━     │
│  Low      Moderate      High        │
└─────────────────────────────────────┘
```

### 5.2 FireDataInfoSheet

**Trigger:** ℹ️ icon button in MapScreen AppBar
**Type:** Modal bottom sheet (scrollable)

**Content:**
```
┌─────────────────────────────────────┐
│  Understanding Fire Data         ✕  │
├─────────────────────────────────────┤
│  How satellite detection works      │
│  ────────────────────────────────   │
│  Satellites pass over Scotland      │
│  6-8 times daily, detecting heat    │
│  signatures from fires.             │
│                                     │
│  What is a hotspot?                 │
│  ────────────────────────────────   │
│  A 375m × 375m area where fire      │
│  was detected. The actual fire may  │
│  be smaller or larger.              │
│                                     │
│  What is a burnt area?              │
│  ────────────────────────────────   │
│  After a fire is contained, EFFIS   │
│  maps the verified damage extent.   │
│  This is more accurate than         │
│  hotspot detection.                 │
│                                     │
│  Data sources                       │
│  ────────────────────────────────   │
│  • NASA VIIRS via GWIS              │
│  • EFFIS Burnt Area Product         │
│  (Copernicus Emergency Management)  │
└─────────────────────────────────────┘
```

### 5.3 First-Time Tooltip

**Trigger:** First MapScreen load where `hasSeenMapOnboarding = false`
**Type:** Overlay tooltip pointing at a fire marker (or center of map if no fires)
**Duration:** Dismisses on tap anywhere, or after 5 seconds

**Content:**
> "Tap a fire to see details. Use filters to show recent activity."

---

## Mock Data Restructure

Current `assets/mock/active_fires.json` has combined incident+polygon data. Restructure to:

### New Structure: `assets/mock/fire_data.json`

```json
{
  "hotspots": [
    {
      "id": "hs_001",
      "type": "hotspot",
      "location": { "lat": 57.2, "lon": -3.8 },
      "detectedAt": "2025-12-09T10:30:00Z",
      "sensor": "VIIRS",
      "satellite": "NOAA-21",
      "confidence": 92,
      "frp": 45.2
    }
  ],
  "burntAreas": [
    {
      "id": "ba_273772",
      "type": "burntArea",
      "fireDate": "2025-06-28T11:53:00Z",
      "lastUpdate": "2025-07-09T13:28:59Z",
      "areaHectares": 9809.46,
      "boundary": [...],
      "isSimplified": true,
      "landCover": {
        "moorland": 93.24,
        "transitional": 4.24,
        "other": 2.52
      }
    }
  ],
  "lastSeasonBurntAreas": [
    {
      "id": "ba_2024_001",
      "type": "burntArea",
      "season": 2024,
      ...
    }
  ]
}
```

---

## Constitutional Compliance

| Gate | Requirement | How We Meet It |
|------|-------------|----------------|
| **C1** | Tests pass | Unit tests for clustering, simplification, services |
| **C2** | No secrets, safe logging | Coordinate redaction at 2dp in logs |
| **C3** | ≥44dp touch targets | Minimum cluster/square tap area enforced |
| **C4** | Timestamp + source visible | Bottom sheet shows detection time + "NASA VIIRS via GWIS" |
| **C5** | Error handling + fallbacks | Mock data fallback if GWIS/EFFIS unavailable |

---

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Data freshness | Hotspots < 4 hours old | Check against satellite pass times |
| Coverage | All Scottish fires > 10 ha | Compare against SFRS reports |
| User understanding | 80% distinguish hotspot vs burnt area | In-app survey |
| Load performance | Map tiles + data < 3s | Performance monitoring |
| Cluster tap accuracy | 95% successful taps on clusters | Analytics |

---

## References

- [EFFIS API Endpoints Reference](reference/EFFIS_API_ENDPOINTS.md)
- [NASA FIRMS FAQ](https://www.earthdata.nasa.gov/learn/find-data/near-real-time/firms/mcd14dl-nrt#ed-firms-faq)
- [VIIRS Active Fire Product](https://www.earthdata.nasa.gov/learn/find-data/near-real-time/firms/vnp14imgtdlnrt)
- [Google Maps Marker Clustering](https://developers.google.com/maps/documentation/javascript/marker-clustering)
- [Douglas-Peucker Algorithm](https://en.wikipedia.org/wiki/Ramer%E2%80%93Douglas%E2%80%93Peucker_algorithm)
