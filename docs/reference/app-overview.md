---
title: WildFire MVP v3 — App Overview
status: active
version: 1.0.0+1
doc_version: 1.0
created: 2026-02-11
last_updated: 2026-02-11
author: Liz Stevenson
category: reference
subcategory: architecture
branch: 024-map-ui-enhancements
commit: ac639e1
flutter_sdk: 3.35.5 (stable)
dart_sdk: 3.9.2 (stable)
platforms:
  - android
  - ios
  - web
  - macos
related:
  - ../guides/development/new-feature-workflow.md
  - ../explanation/architecture-decisions.md
changelog:
  - date: 2026-02-11
    change: Initial document creation — use case, architecture, tech stack
---

# WildFire MVP v3 — App Overview

| | |
|---|---|
| **App Version** | 1.0.0+1 |
| **Doc Version** | 1.0 |
| **Author** | Liz Stevenson |
| **Created** | 2026-02-11 |
| **Last Updated** | 2026-02-11 |
| **Branch** | `024-map-ui-enhancements` |
| **Commit** | `ac639e1` |
| **Flutter SDK** | 3.35.5 (stable) |
| **Dart SDK** | 3.9.2 (stable) |
| **Platforms** | Android · iOS · Web · macOS |
| **Status** | Active |

## Use Case

### The Problem

Scotland faces an increasing risk of wildfires, particularly during dry spring and summer months. Hillwalkers, landowners, farmers, gamekeepers, and rural communities often lack accessible, real-time information about wildfire risk in their area. When fires do occur, they can spread rapidly through dry heather, peatland, and grassland — threatening lives, property, livestock, and ecologically sensitive habitats.

Existing fire risk information is fragmented across multiple European and UK agency websites (EFFIS, SEPA, NASA FIRMS), presented in technical formats designed for professional fire managers rather than the general public. There is no single, mobile-friendly tool that brings this data together for people on the ground in Scotland.

### The Solution

WildFire is a **mobile-first wildfire risk assessment app for Scotland** that provides:

- **Personal fire risk at your location** — Translates the Fire Weather Index (FWI) from European satellite data into plain-language risk levels (Very Low → Extreme) with actionable safety guidance tailored to each level.
- **Live fire detection map** — Shows active fire hotspots detected by NASA VIIRS satellites, updated multiple times daily, so users can see where fires are burning right now.
- **Historical burnt area mapping** — Displays burnt area polygons from MODIS satellite data, helping users understand fire history and seasonal patterns in their area.
- **Emergency fire reporting** — One-tap access to 999 with automatic location sharing via What3Words addresses, reducing response times for rural fires where traditional addresses don't exist.
- **Offline resilience** — Every data source has fallback chains ensuring the app always shows something useful, even with poor rural connectivity.

### Target Users

| User Group | Primary Need |
|-----------|-------------|
| Hillwalkers & outdoor enthusiasts | Check fire risk before heading out; see if fires are burning near planned routes |
| Landowners & estate managers | Monitor fire risk on their land; track burnt areas across seasons |
| Farmers & crofters | Assess muirburn conditions; protect livestock and property |
| Rural communities | Awareness of nearby fire activity; quick emergency reporting |
| Emergency responders (secondary) | Situational awareness tool for fire location data |

### How It Differs

Unlike professional fire management tools, WildFire is designed for **non-expert users**:
- Risk levels are presented with **traffic-light colours and plain language**, not raw FWI numbers
- Location is resolved **automatically** (GPS → cached → manual → default) so users don't need to enter coordinates
- **Every service has a never-fail fallback**, so the app always works — critical in rural Scotland where connectivity is unreliable
- **Accessibility-first**: WCAG 2.1 AA compliant, ≥44dp touch targets, screen reader support, high-contrast risk palette

---

## Technical Overview

### What It Is

WildFire MVP v3 is built with **Flutter 3.35.5 / Dart 3.9.2**. It runs on **Android, iOS, Web, and macOS desktop** (desktop has limited map support — no Google Maps native plugin). The web build is deployed via **Firebase Hosting** with GitHub Actions CI/CD.

**Codebase size**: 152 source files in `lib/`, 145 test files in `test/`, 1,939 tests passing.

### What It Does (User-Facing Features)

The app has **4 main screens** via bottom navigation (`go_router` with `ShellRoute`):

#### 1. Fire Risk (Home)

Shows the Fire Weather Index (FWI) risk level for the user's location. Displays a colour-coded `RiskBanner` (Very Low → Extreme, 6 levels), a `LocationCard` with source attribution (GPS/manual/cached/default), a `RiskGuidanceCard` with safety advice, and a `RiskScale` visualisation. Data comes from the European Forest Fire Information System (EFFIS) with SEPA as a Scotland-specific fallback.

#### 2. Map

Interactive Google Maps (`google_maps_flutter ^2.5.0`) showing:
- **Hotspots**: Live VIIRS satellite fire detections from NASA FIRMS, with GWIS WMS as fallback, clustered at low zoom and shown as individual squares at zoom ≥10
- **Burnt Areas**: Historical MODIS burnt area polygons from EFFIS, with intensity-based colouring (via `PolygonStyleHelper` using `RiskPalette`), visible at zoom ≥8.0
- Toggle between Hotspots/Burnt Areas via `FireDataModeToggle` (SegmentedButton)
- Time filters: today/this week for hotspots; this season/last season for burnt areas
- Risk check: tap any location to get its FWI risk level
- Map type selector (normal/satellite/terrain)

#### 3. Report Fire

Guides users to report fires via 999 emergency call. Shows the user's current location with What3Words address for precise rural location sharing. Integrates with the phone's dialer via `url_launcher`.

#### 4. Onboarding

Multi-page consent flow shown on first launch. Stores consent version in `SharedPreferences`. Includes legal document screens (Terms, Privacy, Disclaimer, Data Sources).

#### Additional Screens

- **Settings** — Notifications, about/legal documents, advanced/developer options
- **Help & Info** — Fire safety guides, FWI explanation, about the app
- **Location Picker** — Full-screen location selection with What3Words grid overlay, geocoding search, manual coordinate entry

---

## Architecture

### Layered Architecture

- **UI Layer**: Screens + reusable widgets in `lib/screens/`, `lib/widgets/`, and `lib/features/*/screens/` + `widgets/`
- **Controller Layer**: `ChangeNotifier`-based state management (`HomeController`, `MapController`, `ReportFireController`). Controllers expose sealed state classes (`HomeState`, `MapState` with Loading/Success/Error variants).
- **Service Layer**: Business logic with resilient fallback chains. Services use `dartz Either<L,R>` for error handling — **UI never imports dartz**; controllers unwrap `Either` to plain states.
- **Model Layer**: Domain models (`FireRisk`, `FireIncident`, `Hotspot`, `BurntArea`, `LatLng`, `RiskLevel`) and state models. Use `equatable` for value equality and `const` constructors.

**Dependency injection** is manual — services are created in `main.dart` and `app.dart`, passed down via constructors. No DI framework.

### Service Fallback Chains (Constitution C5 — Resilience)

Every data path has a never-fail fallback:

| Service | Tier 1 | Tier 2 | Tier 3 | Tier 4 |
|---------|--------|--------|--------|--------|
| **LocationResolver** | GPS (2s timeout) | SharedPreferences cache | Manual entry dialog | Scotland centroid |
| **FireRiskService** | EFFIS (3s timeout) | SEPA (2s, Scotland only) | Cache (6hr TTL, geohash-keyed) | Mock data |
| **HotspotOrchestrator** | FIRMS (NASA, API key) | GWIS WMS (JRC, no key) | Mock from assets | — |
| **BurntAreaService** | Live EFFIS | Cached asset bundle | — | — |

### Project Structure

```
lib/
├── main.dart              # Entry point, service creation
├── app.dart               # MaterialApp.router, GoRouter config, DI wiring
├── config/                # FeatureFlags (dart-define), UIConstants
├── content/               # Legal content (terms, privacy, disclaimer)
├── controllers/           # HomeController (ChangeNotifier)
├── features/
│   ├── map/               # MapScreen, MapController, map widgets, utils
│   ├── report/            # ReportFireScreen, ReportFireController
│   ├── onboarding/        # Multi-page consent flow
│   ├── location_picker/   # Full-screen location picker + What3Words
│   ├── settings/          # Settings hub + sub-screens
│   └── help/              # Help content + document viewer
├── models/                # Domain models (FireRisk, Hotspot, BurntArea, etc.)
├── screens/               # HomeScreen, AboutScreen, LegalDocumentScreen
├── services/              # All services + service models + telemetry
├── theme/                 # BrandPalette, RiskPalette, WildfireA11yTheme
├── utils/                 # LocationUtils, GeohashUtils
└── widgets/               # Shared widgets (RiskBanner, LocationCard, chips, etc.)
```

---

## Tech Stack & Dependencies

| Category | Technology |
|----------|-----------|
| Framework | Flutter 3.35.5 / Dart 3.9.2 |
| State Management | ChangeNotifier (no Bloc/Riverpod) |
| Routing | go_router ^14.2.7 |
| Maps | google_maps_flutter ^2.5.0 (Android/iOS/Web) |
| HTTP | http ^1.1.0, xml ^6.6.1 (WMS parsing) |
| Error Handling | dartz ^0.10.1 (Either type, services only) |
| Location | geolocator ^9.0.2, permission_handler ^11.0.1 |
| Storage | shared_preferences ^2.2.2 |
| Testing | flutter_test, mockito ^5.4.2, build_runner |
| Theme | Material 3, custom BrandPalette + RiskPalette, WCAG 2.1 AA |
| Deployment | Firebase Hosting (web), GitHub Actions CI/CD |

---

## Configuration & Secrets

API keys are injected via `--dart-define-from-file=env/dev.env.json` (never committed). Keys used:

- `GOOGLE_MAPS_API_KEY_WEB` / `_ANDROID` / `_IOS`
- `FIRMS_API_KEY` (NASA satellite data)
- `WHAT3WORDS_API_KEY` (location addressing)

Feature flags (`FeatureFlags` class) read these at runtime via `String.fromEnvironment`. The `env/dev.env.json.template` file shows the expected structure.

---

## Constitutional Gates (Project Rules)

The project enforces 5 "constitutional gates" (C1–C5):

| Gate | Rule | Enforcement |
|------|------|-------------|
| **C1** | Clean architecture | No circular dependencies |
| **C2** | Privacy | Coordinates logged at 2-decimal precision only (`logRedact()`) |
| **C3** | Accessibility | ≥44dp touch targets, WCAG AA contrast, Semantics widgets |
| **C4** | Transparency | Data source attribution on all displayed data |
| **C5** | Resilience | Every service chain has a never-fail fallback |

---

## Data Sources

| Source | Data | Update Frequency |
|--------|------|-----------------|
| **EFFIS** (JRC, EU) | Fire Weather Index (FWI) | Daily |
| **NASA FIRMS** | VIIRS satellite hotspot detections | Multiple times daily |
| **GWIS WMS** (JRC, EU) | Hotspot fallback layer | Daily |
| **EFFIS Burnt Areas** | MODIS burnt area polygons | Seasonal |
| **SEPA** (Scotland) | Scotland-specific FWI | Daily |
| **What3Words** | 3-word location addresses | Real-time |

---

## Test Coverage

1,939 tests passing (28 skipped, 8 pre-existing failures in timing-sensitive integration tests). Tests organised as:

| Category | Location | Purpose |
|----------|----------|---------|
| Unit | `test/unit/` | Model and utility tests |
| Widget | `test/widget/` | Widget tests with mocked dependencies |
| Integration | `test/integration/` | Service orchestration and flow tests |
| Contract | `test/contract/` | API response format validation |
| Performance | `test/performance/` | Clustering and polygon generation benchmarks |
| Accessibility | `test/accessibility/` | WCAG compliance validation |

---

## Key Commands

```bash
# Run on platforms
flutter run -d chrome --dart-define-from-file=env/dev.env.json  # Web
flutter run -d macos --dart-define-from-file=env/dev.env.json   # macOS
./scripts/run_android.sh                                         # Android
./scripts/run_ios.sh                                             # iOS

# Quality checks
flutter test                    # All tests
flutter analyze                 # Lint (0 issues)
dart format lib/ test/          # Format code

# Build & deploy
./scripts/build_web.sh          # Web build with API key injection
./scripts/build_web_ci.sh       # CI build
```

---

## Current State (February 2026)

The app is fully functional on all platforms. Recent work (branch `024-map-ui-enhancements`) included a 3-phase codebase audit:

1. **Phase 1** (`21a7572`) — Removed `dart:io` from production code, added security redaction
2. **Phase 2** (`fbf5d27`) — Reorganised all documentation into Divio categories
3. **Phase 3** (`ac639e1`) — Removed 2,068 lines of dead code (orphaned `FireLocationService` chain and legacy artifacts)

The codebase is clean — `flutter analyze` returns 0 issues.
