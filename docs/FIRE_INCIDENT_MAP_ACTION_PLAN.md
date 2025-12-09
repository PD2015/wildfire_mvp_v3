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
---

# Fire Incident Map - Action Plan

This document outlines what we should show users on the fire incident map to add value for live fire tracking and educate them about wildfires in Scotland.

## Executive Summary

Based on research into EFFIS, GWIS, NASA FIRMS, and the Strathclyde tracker, we recommend a **two-layer approach**:

| Layer | Data Source | Purpose | User Value |
|-------|-------------|---------|------------|
| **Active Hotspots** | GWIS `viirs.hs.today` | "Where fires are burning NOW" | Real-time situational awareness |
| **Burnt Areas** | EFFIS `modis.ba.poly.season` | "Verified fire damage" | Accurate size, historical context |

---

## What We Should Show Users

### 1. Active Fire Hotspots (Real-Time Layer)

**Data Source:** GWIS WMS - `viirs.hs.today` (rolling 24h) or `viirs.hs.week` (rolling 7 days)

**Display as:** Orange/red markers with pulsing animation

**Properties to show:**
| Property | Display Label | Example |
|----------|---------------|---------|
| Detection time | "Detected" | "2 hours ago" |
| Satellite | "Sensor" | "VIIRS (NOAA-21)" |
| Confidence | "Confidence" | "High (95%)" |
| FRP | "Fire Intensity" | "Strong (45 MW)" |

**Educational label:**
> 🔥 **Active Hotspot** - Satellite-detected thermal anomaly in the last 24 hours. Location accurate to ~375m.

**Why show this:**
- Users want to know "is there a fire near me RIGHT NOW?"
- Real-time awareness for outdoor activities
- 6-8 satellite passes per day at Scottish latitudes

**Important caveat to display:**
> ⚠️ Hotspots show where fires are detected, not exact fire boundaries. A single fire may appear as multiple hotspots.

---

### 2. Burnt Areas (Verified Layer)

**Data Source:** EFFIS WFS - `modis.ba.poly.season`

**Display as:** Semi-transparent polygons (35% opacity) using RiskPalette colours

**Properties to show:**
| Property | Display Label | Example |
|----------|---------------|---------|
| `AREA_HA` | "Burnt Area" | "9,809 hectares" |
| `FIREDATE` | "First Detected" | "28 June 2025" |
| `LASTUPDATE` | "Last Updated" | "9 July 2025" |
| Land cover breakdown | "Affected Terrain" | Pie chart or list |

**Educational label:**
> 🗺️ **Verified Burnt Area** - Confirmed fire perimeter mapped by EFFIS after the fire was contained. Area is satellite-verified.

**Why show this:**
- Authoritative fire size (not estimated from hotspot pixels)
- Shows actual fire footprint, not detection points
- Land cover breakdown helps users understand what burned

**Land cover display suggestion:**
```
Affected Terrain:
━━━━━━━━━━━━━━━━━━━━ 93% Moorland/Heath
━━ 4% Transitional Woodland
━ 3% Other
```

---

### 3. User Location Context

**Already implemented via A4 LocationResolver**

**Enhancements to add:**
| Feature | Value |
|---------|-------|
| Distance to nearest fire | "Nearest active fire: 45 km NW" |
| Direction indicator | Compass bearing icon |
| Risk zone awareness | "You are in a HIGH fire risk area today" |

---

### 4. Time-Based Filtering

**Recommended filter chips:**

| Filter | Data Shown | Use Case |
|--------|------------|----------|
| "Today" | Hotspots from last 24h | "What's burning now?" |
| "This Week" | Hotspots from last 7 days | Recent activity overview |
| "This Season" | Burnt areas from current fire season | Historical context |
| "All Time" | Archive (2012+) | Research/education |

---

## What NOT to Show (Avoid Confusion)

### ❌ Don't: Show "fire area" calculated from hotspot pixels

**Why:** NASA explicitly warns against this:
> "It is not recommended to use active fire locations to estimate burned area"

The Strathclyde tracker does this (clusters pixels at 375m), but it's fundamentally inaccurate because:
- Same fire gets re-detected on multiple passes
- Pixel centres shift ~200m between passes
- Edge pixels inflate from 375m to ~800m (bow-tie effect)

**Instead:** Use EFFIS `AREA_HA` which is verified post-fire.

### ❌ Don't: Mix hotspots and burnt areas without clear distinction

**Why:** Users will confuse "active" with "historical"

**Instead:** Use clearly different visual styles:
- Hotspots: Markers with pulse animation
- Burnt areas: Static polygons with lower opacity

### ❌ Don't: Show stale hotspot data from EFFIS `/effis` endpoint

**Why:** That database stopped syncing in October 2021

**Instead:** Always use GWIS `/gwis` endpoint for hotspots.

---

## Implementation Phases

### Phase 1: Foundation (Current State)
- [x] Map with Google Maps integration
- [x] FireIncident model with sensor fields
- [x] Fire details bottom sheet
- [x] Mock data with polygons
- [x] Polygon visibility toggle

### Phase 2: Live GWIS Hotspots
- [ ] Add GWIS WMS service for `viirs.hs.today`
- [ ] Create hotspot markers with pulse animation
- [ ] Add time filter chips (Today / This Week)
- [ ] Display hotspot properties in details sheet
- [ ] Add "Active Hotspot" educational label

### Phase 3: EFFIS Burnt Areas
- [ ] Add EFFIS WFS service for burnt areas
- [ ] Parse GML response to FireIncident model
- [ ] Display burnt area polygons (separate from hotspots)
- [ ] Show land cover breakdown
- [ ] Add "Verified Burnt Area" educational label

### Phase 4: User Context
- [ ] Calculate distance to nearest fire
- [ ] Show direction indicator
- [ ] Integrate with fire risk banner (FWI)
- [ ] Add "fires near you" notification option

### Phase 5: Historical & Education
- [ ] Add season/archive time filters
- [ ] Create "Understanding Fire Data" info sheet
- [ ] Add legend explaining symbols
- [ ] Consider seasonal comparison view

---

## Technical Architecture

### Service Layer

```dart
// Hotspot service (GWIS)
abstract class HotspotService {
  Future<Either<ApiError, List<Hotspot>>> getActive({
    required LatLngBounds bounds,
    TimeWindow window = TimeWindow.today,
  });
}

// Burnt area service (EFFIS)
abstract class BurntAreaService {
  Future<Either<ApiError, List<BurntArea>>> getSeason({
    required LatLngBounds bounds,
    int? year,
  });
}
```

### Model Separation

```dart
// Active hotspot (real-time, point-based)
class Hotspot extends Equatable {
  final String id;
  final LatLng location;
  final DateTime detectedAt;
  final String sensor;        // "VIIRS", "MODIS"
  final String satellite;     // "NOAA-21", "Aqua"
  final double confidence;    // 0-100
  final double? frp;          // Fire Radiative Power (MW)
}

// Verified burnt area (post-fire, polygon-based)
class BurntArea extends Equatable {
  final int id;
  final DateTime fireDate;     // First detection
  final DateTime lastUpdate;   // Polygon refinement
  final double areaHectares;   // Verified size
  final List<LatLng> boundary; // Polygon points
  final LandCover landCover;   // Breakdown %
  final String country;
  final String province;
  final String commune;
}
```

### UI Components

```dart
// Active hotspot marker
class HotspotMarker extends StatelessWidget {
  // Pulsing orange/red marker
  // Tap shows details sheet with "Active Hotspot" label
}

// Burnt area polygon
class BurntAreaPolygon extends StatelessWidget {
  // Static semi-transparent polygon
  // Tap shows details sheet with "Verified Burnt Area" label
}

// Time filter chips
class TimeFilterChips extends StatelessWidget {
  // Today | This Week | This Season | All Time
}

// Educational info sheet
class FireDataInfoSheet extends StatelessWidget {
  // Explains difference between hotspots and burnt areas
  // Shows satellite resolution caveats
}
```

---

## Educational Content for Users

### In-App Explanations

**On first viewing the map:**
> This map shows two types of fire data:
> 
> 🔥 **Active Hotspots** - Fires detected by satellites in the last 24 hours
> 
> 🗺️ **Burnt Areas** - Verified fire damage mapped after fires are contained

**When tapping a hotspot:**
> This thermal hotspot was detected by [VIIRS on NOAA-21] at [time].
> 
> Satellite detection is accurate to ~375 metres. The actual fire may be smaller or larger than this point suggests.

**When tapping a burnt area:**
> This fire was first detected on [date] and burned [area] hectares of [terrain type].
> 
> The boundary shown is the verified extent of fire damage, mapped by the European Forest Fire Information System (EFFIS).

---

## Data Source Attribution

All fire data must include proper attribution:

**Active Hotspots:**
> Data: NASA VIIRS via GWIS (Copernicus Emergency Management Service)

**Burnt Areas:**
> Data: EFFIS Burnt Area Product (Copernicus Emergency Management Service)

---

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Data freshness | Hotspots < 4 hours old | Check against satellite pass times |
| Coverage | All Scottish fires > 10 ha | Compare against SFRS reports |
| User understanding | 80% distinguish hotspot vs burnt area | In-app survey |
| Load performance | Map tiles + data < 3s | Performance monitoring |

---

## References

- [EFFIS API Endpoints Reference](reference/EFFIS_API_ENDPOINTS.md)
- [NASA FIRMS FAQ](https://www.earthdata.nasa.gov/learn/find-data/near-real-time/firms/mcd14dl-nrt#ed-firms-faq)
- [VIIRS Active Fire Product User Guide](https://www.earthdata.nasa.gov/learn/find-data/near-real-time/firms/vnp14imgtdlnrt)
- [Strathclyde Scotland Wildfire Tracker](https://geetest4firescot-lxz4iyld3a-ew.a.run.app/)
