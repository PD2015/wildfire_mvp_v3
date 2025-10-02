# Data Model: RiskBanner Widget

## Core Entities

### RiskBannerState
**Purpose**: Represents the current state of the RiskBanner widget

```dart
sealed class RiskBannerState extends Equatable {
  const RiskBannerState();
  
  @override
  List<Object?> get props => [];
}

class RiskBannerInitial extends RiskBannerState {
  const RiskBannerInitial();
}

class RiskBannerLoading extends RiskBannerState {
  const RiskBannerLoading();
}

class RiskBannerLoaded extends RiskBannerState {
  final FireRisk riskData;
  final bool isFromCache;
  final DateTime lastUpdated;
  
  const RiskBannerLoaded({
    required this.riskData,
    required this.isFromCache,
    required this.lastUpdated,
  });
  
  @override
  List<Object?> get props => [riskData, isFromCache, lastUpdated];
}

class RiskBannerError extends RiskBannerState {
  final String message;
  final FireRisk? cachedData;
  final DateTime? lastUpdated;
  
  const RiskBannerError({
    required this.message,
    this.cachedData,
    this.lastUpdated,
  });
  
  @override
  List<Object?> get props => [message, cachedData, lastUpdated];
}
```

**Validation Rules**:
- `RiskBannerLoaded.riskData` must not be null
- `RiskBannerLoaded.lastUpdated` must be valid DateTime
- `RiskBannerError.message` must be non-empty string

### WildfireRiskLevel (from A2)
**Purpose**: Enum representing Scottish Government wildfire risk levels

```dart
enum WildfireRiskLevel {
  veryLow,
  low, 
  moderate,
  high,
  veryHigh
}
```

### FireRisk (from A2 - reference)
**Purpose**: Data structure containing wildfire risk information

```dart
class FireRisk extends Equatable {
  final WildfireRiskLevel level;
  final double fwiValue;
  final String source; // 'EFFIS', 'SEPA', 'Cache', 'Mock'
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  
  const FireRisk({
    required this.level,
    required this.fwiValue,
    required this.source,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
  });
  
  @override
  List<Object> get props => [level, fwiValue, source, timestamp, latitude, longitude];
}
```

## UI Data Structures

### WildfireColors
**Purpose**: Constants for official Scottish Government wildfire risk colors

```dart
class WildfireColors {
  static const Color veryLow = Color(0xFF00FF00);   // Green
  static const Color low = Color(0xFFFFFF00);       // Yellow  
  static const Color moderate = Color(0xFFFFA500);  // Orange
  static const Color high = Color(0xFFFF0000);      // Red
  static const Color veryHigh = Color(0xFF800080);  // Purple
  
  static Color getColorForLevel(WildfireRiskLevel level) {
    switch (level) {
      case WildfireRiskLevel.veryLow:
        return veryLow;
      case WildfireRiskLevel.low:
        return low;
      case WildfireRiskLevel.moderate:
        return moderate; 
      case WildfireRiskLevel.high:
        return high;
      case WildfireRiskLevel.veryHigh:
        return veryHigh;
    }
  }
}
```

**Validation Rules**:
- All color values must match official Scottish Government standards
- `getColorForLevel` must handle all enum cases
- Colors must provide sufficient contrast for accessibility

### RiskBannerConfig
**Purpose**: Configuration for widget appearance and behavior

```dart
class RiskBannerConfig {
  final double minHeight;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final Duration animationDuration;
  
  const RiskBannerConfig({
    this.minHeight = 64.0,  // Ensures 44dp+ touch target
    this.padding = const EdgeInsets.all(16.0),
    this.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
    this.animationDuration = const Duration(milliseconds: 300),
  });
}
```

## State Transitions

### Loading Flow
```
RiskBannerInitial → RiskBannerLoading → RiskBannerLoaded
                                    ↘ RiskBannerError
```

### Refresh Flow  
```
RiskBannerLoaded → RiskBannerLoading → RiskBannerLoaded
                                   ↘ RiskBannerError (with cached data)
```

### Error Recovery Flow
```
RiskBannerError → RiskBannerLoading → RiskBannerLoaded
                                  ↘ RiskBannerError
```

## Relationships

### Widget → BLoC → Service
```
RiskBannerWidget
  ↓ (dispatches events)
RiskBannerCubit
  ↓ (calls methods)
FireRiskRepository
  ↓ (delegates to)
FireRiskService (A2)
```

### Data Flow
```
User coordinates → FireRiskService → FireRisk → RiskBannerState → UI
```

## Accessibility Data

### Semantic Labels
```dart
class RiskBannerSemantics {
  static String getLevelLabel(WildfireRiskLevel level) {
    switch (level) {
      case WildfireRiskLevel.veryLow:
        return 'Very low wildfire risk';
      case WildfireRiskLevel.low:
        return 'Low wildfire risk';
      case WildfireRiskLevel.moderate:
        return 'Moderate wildfire risk';
      case WildfireRiskLevel.high:
        return 'High wildfire risk';
      case WildfireRiskLevel.veryHigh:
        return 'Very high wildfire risk';
    }
  }
  
  static String getSourceLabel(String source) {
    switch (source.toLowerCase()) {
      case 'effis':
        return 'Data from European Forest Fire Information System';
      case 'sepa':
        return 'Data from Scottish Environment Protection Agency';
      case 'cache':
        return 'Cached data from previous update';
      case 'mock':
        return 'Mock data for testing';
      default:
        return 'Data from $source';
    }
  }
}
```

**Validation Rules**:
- All semantic labels must be descriptive for screen readers
- Labels must clearly indicate data source and age
- Touch targets must be minimum 44dp for accessibility compliance