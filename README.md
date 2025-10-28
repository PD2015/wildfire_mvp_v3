# wildfire_mvp_v3

Scottish wildfire risk assessment mobile app with EFFIS integration

## Overview

A Flutter mobile application that provides real-time wildfire risk assessment using data from the European Forest Fire Information System (EFFIS). The app delivers fire weather index (FWI) data with risk categorization for Scottish locations.

## 🚀 Features

- **Real-time FWI Data**: Integration with EFFIS WMS GetFeatureInfo API
- **Risk Assessment**: Automatic risk level categorization (low, moderate, high, very high, extreme)
- **Interactive Maps**: Google Maps integration with fire incident markers (iOS crash-free ✅)
  - **iOS Integration**: Complete crash-free solution with automated API key injection
  - **Cross-Platform Support**: Works on iOS, Android, and web platforms
- **Robust Error Handling**: Comprehensive error management with retry logic
- **Offline Resilience**: Graceful handling of network issues with exponential backoff
- **Demo Mode Transparency**: Prominent "DEMO DATA" chip when using mock data (C4 compliance)
- **Production Ready**: 84.3% test coverage with 56/56 tests passing

## 🏗️ Architecture

### Models Layer
- **RiskLevel**: Enum for wildfire risk categories with FWI thresholds
- **ApiError**: Structured error handling with reason categorization
- **EffisFwiResult**: Fire weather index data with location and temporal information

### Services Layer  
- **EffisService**: Abstract interface for FWI data retrieval
- **EffisServiceImpl**: Production implementation with EFFIS WMS integration
  - WMS GetFeatureInfo API integration
  - Exponential backoff retry logic
  - Coordinate validation and transformation
  - Comprehensive error mapping

## 🧪 Testing

### Test Coverage: **84.3%** ✅
- **56 tests passing** (100% success rate)
- **36 model tests** - Complete unit testing
- **13 service tests** - Integration testing with mocked HTTP client
- **6 contract tests** - Real fixture validation
- **1 fixture test** - File integrity validation

### Coverage by Component
| Component | Coverage | Status |
|-----------|----------|--------|
| Models | 94.2% | ✅ Excellent |
| Services | 84.7% | ✅ Good |
| Overall | 84.3% | ✅ Production Ready |

📊 **Detailed Coverage Report**: [docs/TEST_COVERAGE.md](docs/TEST_COVERAGE.md)

### Running Tests
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# View coverage summary
lcov --summary coverage/lcov.info

# Generate HTML coverage report
genhtml coverage/lcov.info -o coverage/html
```

### 🛠️ Coverage Analysis Tools

#### Required Tools Installation
```bash
# macOS (using Homebrew)
brew install lcov

# Ubuntu/Debian
sudo apt-get install lcov

# CentOS/RHEL
sudo yum install lcov
```

#### Coverage Workflow
1. **Generate Coverage Data**
   ```bash
   flutter test --coverage
   ```
   - Creates `coverage/lcov.info` with detailed line coverage data
   - Includes all Dart files in `lib/` directory
   - Excludes generated files and test files

2. **View Coverage Summary**
   ```bash
   lcov --summary coverage/lcov.info
   ```
   - Displays overall coverage percentage
   - Shows total lines found vs. hit
   - Quick validation of coverage levels

3. **Generate HTML Report**
   ```bash
   genhtml coverage/lcov.info -o coverage/html
   ```
   - Creates browsable HTML report in `coverage/html/`
   - File-by-file coverage visualization
   - Line-by-line coverage highlighting
   - Access via `open coverage/html/index.html`

4. **List Detailed Coverage**
   ```bash
   lcov --list coverage/lcov.info
   ```
   - File-by-file coverage breakdown
   - Individual file coverage percentages
   - Useful for identifying low-coverage files

#### Coverage Standards
- **Production Ready**: ≥80% overall coverage ✅
- **Excellent**: ≥90% coverage
- **Models**: Target 95%+ (simple value objects)
- **Services**: Target 85%+ (complex business logic)

#### HTML Report Features
- **Interactive Navigation**: Click through directories and files
- **Color-Coded Lines**: Green (covered), Red (uncovered), Orange (partially covered)
- **Function Coverage**: Method-level coverage statistics
- **Branch Coverage**: Conditional logic coverage analysis
- **Sortable Tables**: Sort by coverage percentage, lines, functions

## 🛠️ Development Setup

### Prerequisites
- Flutter SDK 3.0+
- Dart 3.0+
- iOS/Android development environment

### Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0          # HTTP client for API requests
  dartz: ^0.10.1        # Functional programming (Either type)
  equatable: ^2.0.5     # Value object equality

dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.2       # Mocking for unit tests
  build_runner: ^2.4.7  # Code generation for mocks
```

### Installation
```bash
# Clone the repository
git clone <repository-url>
cd wildfire_mvp_v3

# Install dependencies
flutter pub get

# Generate mock files
dart run build_runner build

# Run tests
flutter test

# Run the app (standard Flutter commands work automatically)
flutter run

# iOS with API keys (uses automatic injection via Xcode Build Phase)
flutter run -d ios --dart-define-from-file=env/dev.env.json
```

**📱 iOS Setup**: For iOS Google Maps integration, see **[iOS Google Maps Integration Guide](docs/IOS_GOOGLE_MAPS_INTEGRATION.md)** for complete setup instructions including API key configuration and crash-free deployment.

### Feature Flags

#### MAP_LIVE_DATA
Controls whether the app uses live EFFIS data or mock data for testing.

**Usage**:
```bash
# Demo mode (default) - uses mock data, shows "DEMO DATA" chip
flutter run --dart-define=MAP_LIVE_DATA=false

# Production mode - uses live EFFIS data
flutter run --dart-define=MAP_LIVE_DATA=true

# Environment file approach
flutter run --dart-define-from-file=env/dev.env.json
```

**Behavior**:
- **false** (default): Uses mock data, displays prominent amber "DEMO DATA" chip on map
- **true**: Uses live EFFIS WFS data, displays standard green/orange/blue source chip

**CI Configuration**:
The `env/ci.env.json` file defaults to `MAP_LIVE_DATA=false` to ensure tests run predictably with mock data.

**Constitutional Compliance**: This feature supports C4 (Trust & Transparency) by clearly indicating when demo/mock data is being used.

## 🌐 API Integration

### EFFIS WMS Service
- **Endpoint**: `https://ies-ows.jrc.ec.europa.eu/gwis`
- **Service**: WMS GetFeatureInfo
- **Layer**: `ecmwf.fwi` (ECMWF Fire Weather Index)
- **Coordinate System**: EPSG:3857 (Web Mercator)
- **Format**: GeoJSON FeatureCollection

### Request Configuration
- **User-Agent**: `WildFire/0.1 (prototype)`
- **Accept**: `application/json,*/*;q=0.8`
- **Timeout**: 30 seconds (configurable)
- **Retry Logic**: Exponential backoff with jitter (max 10 retries)

## 📂 Project Structure

```
lib/
├── models/
│   ├── api_error.dart           # Error handling structures
│   ├── effis_fwi_result.dart    # FWI data model
│   └── risk_level.dart          # Risk categorization enum
├── services/
│   ├── effis_service.dart       # Abstract service interface
│   └── effis_service_impl.dart  # Production implementation
├── theme/
│   └── risk_palette.dart        # UI color themes
└── main.dart                    # App entry point

test/
├── unit/
│   ├── models/                  # Model unit tests
│   └── services/                # Service integration tests
├── contract/                    # Contract tests with fixtures
└── fixtures/effis/              # JSON test fixtures
```

## 🚀 Getting Started

### Quick Start
```bash
# Install dependencies
flutter pub get

# Run tests to verify setup
flutter test

# Start the application
flutter run
```

### Development Workflow
1. **Make changes** to models or services
2. **Run tests** to verify functionality: `flutter test`
3. **Check coverage** if needed: `flutter test --coverage`

### Testing with Different Regions

The app defaults to Scotland (low wildfire activity). To test with regions that typically have more fires:

```bash
# Test with Portugal (high summer fire activity)
flutter run -d android \
  --dart-define=TEST_REGION=portugal \
  --dart-define=MAP_LIVE_DATA=true

# Test with California
flutter run -d ios \
  --dart-define=TEST_REGION=california \
  --dart-define=MAP_LIVE_DATA=true
```

**Available test regions**: `portugal`, `spain`, `greece`, `california`, `australia`

📖 **See [docs/TEST_REGIONS.md](docs/TEST_REGIONS.md) for complete documentation** including fire seasons, coordinates, and troubleshooting.
4. **Commit changes** with descriptive messages
5. **Generate coverage reports** for documentation

## 📋 API Usage Example

```dart
import 'package:wildfire_mvp_v3/services/effis_service_impl.dart';
import 'package:http/http.dart' as http;

// Initialize service
final httpClient = http.Client();
final effisService = EffisServiceImpl(httpClient: httpClient);

// Get FWI data for Edinburgh
final result = await effisService.getFwi(
  lat: 55.9533,
  lon: -3.1883,
  timeout: Duration(seconds: 30),
  maxRetries: 3,
);

// Handle result
result.fold(
  (error) => print('Error: ${error.message}'),
  (fwiResult) => print('FWI: ${fwiResult.fwi}, Risk: ${fwiResult.riskLevel}'),
);
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make changes and add tests
4. Ensure tests pass: `flutter test`
5. Commit changes: `git commit -m 'Add amazing feature'`
6. Push to branch: `git push origin feature/amazing-feature`
7. Open a Pull Request

## 📄 Documentation

*Documentation Consolidation Complete (Oct 28, 2025): Reduced from 30+ files to 26 comprehensive guides*

### 🎯 Essential Setup Guides
- **[Google Maps API Setup](docs/GOOGLE_MAPS_API_SETUP.md)** ⭐ - **Comprehensive setup guide** (iOS/Android/Web, API keys, cost controls, EFFIS integration)
- **[iOS Google Maps Integration](docs/IOS_GOOGLE_MAPS_INTEGRATION.md)** - Complete iOS setup, crash fixes, and best practices
- **[Cross-Platform Testing](docs/CROSS_PLATFORM_TESTING.md)** - Testing strategies across iOS, Android, and web

### 🧪 Testing Documentation  
- **[Test Coverage Report](docs/TEST_COVERAGE.md)** - **Comprehensive coverage analysis** (executive summary, detailed analysis, debugging impact, roadmap)
- **[Integration Testing](docs/INTEGRATION_TESTING.md)** - **Comprehensive testing methodology** (strategies, GoogleMap limitations, CI/CD integration)
- **[Integration Test Results](docs/INTEGRATION_TEST_RESULTS.md)** - **Current status and manual procedures** (test results, checklists, troubleshooting)

### 🛡️ Security & Compliance
- **[Privacy Compliance](docs/privacy-compliance.md)** - Constitutional gate compliance (C2, C3, C4)
- **[Security Audit](docs/SECURITY_AUDIT.md)** - Security review and recommendations
- **[Web API Security](docs/WEB_API_KEY_SECURITY.md)** - Secure API key management for web deployments

### 🚀 Platform-Specific Guides
- **[macOS Web Support](docs/MACOS_WEB_SUPPORT.md)** - Running on macOS with Google Maps via web
- **[Test Regions](docs/TEST_REGIONS.md)** - Geographic testing regions and fire seasons

### 📚 Additional Resources
- **[UX Cues](docs/ux_cues.md)** - User experience design guidelines
- **[Accessibility Statement](docs/accessibility-statement.md)** - WCAG compliance and accessibility features
- **[Flutter Documentation](https://docs.flutter.dev/)** - Official Flutter development guides

---
**Documentation Quality**: ✅ **Production Ready** - All essential workflows documented with comprehensive guides

## 📊 Project Status

- **Version**: MVP v3
- **Status**: ✅ Production Ready
- **Test Coverage**: 84.3% (56/56 tests passing)
- **Last Updated**: October 2, 2025
- **Branch**: `001-spec-a1-effisservice`
