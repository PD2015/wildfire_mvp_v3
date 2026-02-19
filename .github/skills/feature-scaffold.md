# Skill: Feature Scaffold — WildFire MVP

> Teaches the agent how features are structured in this project so every new feature follows the established architecture.

## Feature Directory Structure

New features live under `lib/features/<feature_name>/` with this layout:

```
lib/features/<feature_name>/
├── controllers/
│   └── <feature_name>_controller.dart    # ChangeNotifier controller
├── models/
│   └── <feature_name>_state.dart         # Sealed state hierarchy (Equatable)
├── screens/
│   └── <feature_name>_screen.dart        # Top-level route widget
└── widgets/
    └── <widget_name>.dart                # Feature-specific widgets
```

Shared code lives in top-level directories:

```
lib/services/          # Shared services (API clients, caches, resolvers)
lib/models/            # Shared data models (LatLng, FireRisk, ApiError, etc.)
lib/widgets/           # Shared widgets (RiskBanner, LocationCard, etc.)
lib/controllers/       # Shared controllers (HomeController)
lib/config/            # Feature flags, constants
lib/theme/             # BrandPalette, RiskPalette, WildfireA11yTheme
lib/utils/             # App-level utilities (LocationUtils, GeohashUtils)
lib/services/utils/    # Service-level utilities (GeographicUtils)
```

## Controller Pattern

Controllers extend `ChangeNotifier` with dependency injection:

```dart
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class FeatureController extends ChangeNotifier {
  final SomeService _service;

  FeatureState _state = const FeatureLoading();
  FeatureState get state => _state;

  FeatureController({required SomeService service}) : _service = service {
    developer.log('FeatureController initialized', name: 'Feature');
  }

  void _updateState(FeatureState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> initialize() async {
    // Load initial data
  }
}
```

**Rules**:
- Use `developer.log()` with a `name:` tag for structured logging
- Use `debugPrint()` for quick debug output (not `print()`)
- Never import `dartz` in controllers — unwrap `Either` results to plain states
- Dependencies injected via constructor (no singletons, no global state)
- Expose state via getter, mutate only via `_updateState()`

## State Pattern

States use `sealed class` + `Equatable`:

```dart
import 'package:equatable/equatable.dart';

sealed class FeatureState extends Equatable {
  const FeatureState();
}

class FeatureLoading extends FeatureState {
  const FeatureLoading();

  @override
  List<Object?> get props => [];
}

class FeatureSuccess extends FeatureState {
  final SomeData data;
  final DateTime lastUpdated;

  const FeatureSuccess({required this.data, required this.lastUpdated});

  @override
  List<Object?> get props => [data, lastUpdated];
}

class FeatureError extends FeatureState {
  final String message;

  const FeatureError({required this.message});

  @override
  List<Object?> get props => [message];
}
```

**Rules**:
- Always `sealed` (enables exhaustive `switch`)
- Always `extends Equatable`
- Always `const` constructors
- Include `lastUpdated: DateTime` in success states for C4 timestamp compliance
- Computed properties (`canProceed`, `isStale`) go on state classes, not controllers

## Screen Pattern

Screens are top-level route widgets that wire controller → widgets:

```dart
class FeatureScreen extends StatelessWidget {
  final FeatureController controller;

  const FeatureScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return switch (controller.state) {
          FeatureLoading() => const Center(child: CircularProgressIndicator()),
          FeatureSuccess(:final data) => _buildContent(context, data),
          FeatureError(:final message) => _buildError(context, message),
        };
      },
    );
  }
}
```

**Rules**:
- Controller injected via constructor (set up in `app.dart` router)
- Use `ListenableBuilder` to react to `ChangeNotifier`
- Use exhaustive `switch` on sealed state
- Wrap content in `Scaffold` with appropriate `AppBar`

## Service Pattern

Services use `dartz Either<ApiError, T>` for error handling:

```dart
import 'package:dartz/dartz.dart';
import 'package:wildfire_mvp_v3/models/api_error.dart';

abstract class FeatureService {
  Future<Either<ApiError, FeatureData>> getData({
    required double lat,
    required double lon,
    Duration? deadline,
  });
}
```

**Rules**:
- `dartz` is for services ONLY — never in controllers, widgets, or models
- Abstract interface + `Impl` class separation
- Always include timeout/deadline parameters on network calls
- Use `GeographicUtils.logRedact(lat, lon)` for coordinate logging in services
- Use `LocationUtils.logRedact(lat, lon)` for coordinate logging in app layer

## Routing (go_router)

Routes are defined in `lib/app.dart`. New features need:
1. A `GoRoute` entry in the router
2. Controller instantiation in the route builder
3. Service wiring with dependency injection

```dart
GoRoute(
  path: '/feature',
  name: 'feature',
  builder: (context, state) {
    final controller = FeatureController(service: featureService);
    return FeatureScreen(controller: controller);
  },
),
```

## Test Structure

Mirror the source path in tests:

```
test/unit/features/<feature_name>/         # Unit tests (models, controllers)
test/widget/<feature_name>/                # Widget tests (screens, widgets)
test/integration/<feature_name>/           # Integration tests (full flows)
```

## Checklist for New Features

- [ ] `lib/features/<name>/controllers/` — controller with ChangeNotifier
- [ ] `lib/features/<name>/models/` — sealed state with Equatable
- [ ] `lib/features/<name>/screens/` — screen wired to controller
- [ ] `lib/features/<name>/widgets/` — feature-specific widgets
- [ ] `lib/app.dart` — route added
- [ ] `test/unit/features/<name>/` — state + controller tests
- [ ] `test/widget/<name>/` — widget render tests
- [ ] No `dartz` in controllers or widgets
- [ ] No `print()` — use `debugPrint()` or `developer.log()`
- [ ] `const` constructors wherever possible
- [ ] C4: timestamps and source labels on data displays
