---
title: DEV_MODE Feature Flag Guide
status: active
last_updated: 2025-12-02
category: guides
subcategory: setup
related:
  - guides/setup/google-maps.md
  - reference/test-regions.md
---

# DEV_MODE Feature Flag

The `DEV_MODE` environment variable controls development-specific behaviors in the WildFire app, primarily the default fallback location used when GPS is unavailable.

## Overview

| Setting | Default Fallback Location | Use Case |
|---------|--------------------------|----------|
| `DEV_MODE=true` | Aviemore (57.2, -3.8) | Development, testing, emulators |
| `DEV_MODE=false` | Scotland Centroid (55.8642, -4.2518) | Production builds |

## Why Aviemore?

Aviemore is located in the Cairngorms National Park and is an area that typically has fire activity data available in the EFFIS database. This makes it ideal for development and testing because:

1. **Fire data availability**: The Cairngorms area frequently has fire incidents in EFFIS
2. **Visual feedback**: Developers can see real marker data on the map
3. **Emulator compatibility**: Works without GPS (emulators often lack GPS support)
4. **Consistent testing**: Same location across all development machines

## Usage

### Development (Default)

By default, `DEV_MODE=true` is set when running without explicit configuration:

```bash
# These all use DEV_MODE=true (Aviemore fallback)
flutter run
flutter run -d chrome
flutter run --dart-define-from-file=env/dev.env.json
```

### Production Build

For production builds, explicitly set `DEV_MODE=false`:

```bash
# Production build with real Scotland centroid
flutter build apk --dart-define=DEV_MODE=false
flutter build ios --dart-define=DEV_MODE=false

# Or use production env file
flutter build apk --dart-define-from-file=env/prod.env.json
```

### Environment Files

**Development** (`env/dev.env.json`):
```json
{
  "DEV_MODE": "true",
  "MAP_LIVE_DATA": "false",
  ...
}
```

**Production** (`env/prod.env.json`):
```json
{
  "DEV_MODE": "false",
  "MAP_LIVE_DATA": "true",
  ...
}
```

## Relationship with Other Flags

### DEV_MODE vs TEST_REGION

These flags serve different purposes:

| Flag | Purpose | Effect |
|------|---------|--------|
| `DEV_MODE` | Controls **fallback** location when GPS fails | Changes default coordinates |
| `TEST_REGION` | Controls **which region's fire data** to fetch | Changes EFFIS query region |

**Example combinations:**

```bash
# Development: Aviemore fallback, Scotland fire data (most common)
flutter run --dart-define=DEV_MODE=true --dart-define=TEST_REGION=scotland

# Testing Portugal fires: Aviemore fallback, Portugal fire data
flutter run --dart-define=DEV_MODE=true --dart-define=TEST_REGION=portugal

# Production: Scotland centroid fallback, Scotland fire data
flutter run --dart-define=DEV_MODE=false --dart-define=TEST_REGION=scotland
```

### DEV_MODE vs MAP_LIVE_DATA

| Flag | Purpose |
|------|---------|
| `DEV_MODE` | Controls fallback location coordinates |
| `MAP_LIVE_DATA` | Controls whether to use live EFFIS API or mock data |

You can use any combination of these flags independently.

## Web Platform GPS

With this update, **web browsers now attempt GPS** via the Geolocation API:

- **Before**: Web always skipped GPS and used fallback
- **After**: Web attempts GPS first (requires HTTPS in production)

This enables PWA installations on mobile phones to use real GPS location.

**Platform behavior:**

| Platform | GPS Attempted? | Fallback Used When? |
|----------|---------------|---------------------|
| Android | ✅ Yes | Permission denied, timeout, or error |
| iOS | ✅ Yes | Permission denied, timeout, or error |
| Web (HTTPS) | ✅ Yes | Permission denied, timeout, or error |
| Web (HTTP) | ⚠️ Limited | Browser may block without HTTPS |
| macOS Desktop | ❌ No | Always uses fallback |
| Windows/Linux | ❌ No | Always uses fallback |

## Startup Logging

When the app starts, it logs the current mode:

```
🔧 DEV_MODE enabled - using Aviemore (57.2, -3.8) as fallback location
```

or

```
🏭 Production mode - using Scotland centroid (55.86, -4.25) as fallback location
```

This helps developers quickly identify which mode is active.

## Implementation Details

The flag is implemented in `lib/config/feature_flags.dart`:

```dart
static const bool devMode = bool.fromEnvironment(
  'DEV_MODE',
  defaultValue: true, // Default true for development convenience
);
```

The fallback location is resolved in `lib/services/location_resolver_impl.dart`:

```dart
static final LatLng _defaultFallbackLocation = FeatureFlags.devMode
    ? _aviemoreLocation    // 57.2, -3.8
    : _scotlandCentroid;   // 55.8642, -4.2518
```

Note: `static final` is used (not `static const`) because the ternary expression creates a runtime-evaluated result even though `devMode` itself is a compile-time constant.

## Testing

Tests run with `DEV_MODE=true` by default. The `TestData` class in `test/support/fakes.dart` provides:

```dart
// Explicit named locations for clarity
static const LatLng aviemore = LatLng(57.2, -3.8);
static const LatLng realScotlandCentroid = LatLng(55.8642, -4.2518);

// Deprecated - use explicit names above
@Deprecated('Use aviemore or realScotlandCentroid explicitly')
static const LatLng scotlandCentroid = aviemore;
```

## Acceptance Criteria

✅ `DEV_MODE=true` uses Aviemore coordinates (57.2, -3.8) as fallback  
✅ `DEV_MODE=false` uses real Scotland centroid (55.8642, -4.2518) as fallback  
✅ Web platform attempts GPS when running on HTTPS  
✅ Desktop platforms (macOS/Windows/Linux) still skip GPS and use fallback  
✅ Existing `TEST_REGION` functionality continues to work  
✅ Startup logging indicates active mode  
