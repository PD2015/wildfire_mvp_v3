import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wildfire_mvp_v3/screens/home_screen.dart';
import 'package:wildfire_mvp_v3/controllers/home_controller.dart';
import 'package:wildfire_mvp_v3/models/home_state.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';
import 'package:wildfire_mvp_v3/models/risk_level.dart';
import 'package:wildfire_mvp_v3/widgets/manual_location_dialog.dart';

/// Mock HomeController for testing UI interactions
class MockHomeController extends ChangeNotifier implements HomeController {
  HomeState _state = HomeStateLoading(startTime: DateTime.now());
  bool _isLoading = false;

  @override
  HomeState get state => _state;

  @override
  bool get isLoading => _isLoading;

  int loadCallCount = 0;
  int retryCallCount = 0;
  int setManualLocationCallCount = 0;
  LatLng? lastManualLocation;

  void setState(HomeState newState, {bool loading = false}) {
    _state = newState;
    _isLoading = loading;
    notifyListeners();
  }

  @override
  Future<void> load() async {
    loadCallCount++;
    // Immediate completion for testing
  }

  @override
  Future<void> retry() async {
    retryCallCount++;
    // Immediate completion for testing
  }

  @override
  Future<void> setManualLocation(LatLng location, {String? placeName}) async {
    setManualLocationCallCount++;
    lastManualLocation = location;
    // Immediate completion for testing
  }

  @override
  Future<void> refresh() async {
    // Mock implementation
  }
}

/// Test data factory
class TestData {
  static const edinburgh = LatLng(55.9533, -3.1883);
  static const glasgow = LatLng(55.8642, -4.2518);

  static FireRisk createFireRisk({
    RiskLevel level = RiskLevel.moderate,
    DataSource source = DataSource.effis,
    Freshness freshness = Freshness.live,
  }) {
    return FireRisk(
      level: level,
      fwi: 5.0,
      source: source,
      observedAt: DateTime.now().toUtc(),
      freshness: freshness,
    );
  }
}

void main() {
  group('HomeScreen Widget Tests', () {
    late MockHomeController mockController;

    setUp(() {
      mockController = MockHomeController();
    });

    tearDown(() {
      mockController.dispose();
    });

    /// Helper to build HomeScreen with test setup
    Widget buildHomeScreen() {
      return MaterialApp(home: HomeScreen(controller: mockController));
    }

    group('Initial State and Loading', () {
      testWidgets('renders loading state initially', (tester) async {
        // Arrange
        mockController.setState(
          HomeStateLoading(startTime: DateTime.now()),
          loading: true,
        );

        // Act
        await tester.pumpWidget(buildHomeScreen());

        // Assert
        expect(find.text('Wildfire Risk'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsWidgets);
        expect(find.textContaining('Loading fire risk data'), findsOneWidget);
      });

      testWidgets('calls load() on initialization', (tester) async {
        // Act
        await tester.pumpWidget(buildHomeScreen());
        await tester.pump(); // Trigger post-frame callback

        // Assert
        expect(mockController.loadCallCount, equals(1));
      });

      testWidgets('retry button shows loading state when loading', (
        tester,
      ) async {
        // Arrange - Set error state first
        mockController.setState(
          const HomeStateError(errorMessage: 'Test error', canRetry: true),
        );
        await tester.pumpWidget(buildHomeScreen());

        // Verify retry button exists
        expect(find.text('Retry'), findsOneWidget);

        // Change to loading state
        mockController.setState(
          HomeStateLoading(startTime: DateTime.now()),
          loading: true,
        );
        await tester.pump();

        // Assert - Retry button should not be visible in loading state
        expect(find.text('Retry'), findsNothing);
        expect(
          find.text('Set Location'),
          findsOneWidget,
        ); // This should still be present
      });
    });

    group('Success State', () {
      testWidgets('renders success state with risk banner and timestamp', (
        tester,
      ) async {
        // Arrange
        final testRisk = TestData.createFireRisk(
          level: RiskLevel.high,
          source: DataSource.effis,
        );
        final lastUpdated = DateTime.now().subtract(const Duration(minutes: 5));

        mockController.setState(
          HomeStateSuccess(
            riskData: testRisk,
            location: TestData.edinburgh,
            lastUpdated: lastUpdated,
          ),
        );

        // Act
        await tester.pumpWidget(buildHomeScreen());

        // Assert
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(
          find.textContaining('Updated'),
          findsAtLeastNWidgets(1),
        ); // May appear in RiskBanner and timestamp
        expect(
          find.textContaining('Data Source: EFFIS'),
          findsAtLeastNWidgets(1),
        ); // Source label in RiskBanner
      });

      testWidgets('displays correct source chips', (tester) async {
        final testCases = [
          (DataSource.effis, 'Data Source: EFFIS'),
          (DataSource.sepa, 'Data Source: SEPA'),
          (DataSource.cache, 'Data Source: Cache'),
          (DataSource.mock, 'Data Source: Mock'),
        ];

        for (final (source, expectedText) in testCases) {
          // Arrange
          final testRisk = TestData.createFireRisk(source: source);
          mockController.setState(
            HomeStateSuccess(
              riskData: testRisk,
              location: TestData.edinburgh,
              lastUpdated: DateTime.now(),
            ),
          );

          // Act
          await tester.pumpWidget(buildHomeScreen());
          await tester.pump(); // Allow state change to settle

          // Assert - Should find source label in RiskBanner
          expect(
            find.textContaining(expectedText),
            findsAtLeastNWidgets(1),
            reason: 'Should display $expectedText for source $source',
          );
        }
      });
    });

    group('Error State', () {
      testWidgets('renders error state with retry button', (tester) async {
        // Arrange
        mockController.setState(
          const HomeStateError(errorMessage: 'Network error', canRetry: true),
        );

        // Act
        await tester.pumpWidget(buildHomeScreen());

        // Assert
        expect(find.text('Unable to load current data'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('shows cached data when available', (tester) async {
        // Arrange
        final cachedRisk = TestData.createFireRisk(
          level: RiskLevel.low,
          source: DataSource.cache,
          freshness: Freshness.cached,
        );

        mockController.setState(
          HomeStateError(
            errorMessage: 'Network error',
            cachedData: cachedRisk,
            cachedLocation: TestData.edinburgh,
            canRetry: true,
          ),
        );

        // Act
        await tester.pumpWidget(buildHomeScreen());

        // Assert
        expect(find.text('Showing cached data'), findsOneWidget);
        expect(find.text('Cached'), findsAtLeastNWidgets(1)); // Cached chip
      });

      testWidgets('retry button calls controller.retry()', (tester) async {
        // Arrange
        mockController.setState(
          const HomeStateError(errorMessage: 'Test error', canRetry: true),
        );

        await tester.pumpWidget(buildHomeScreen());

        // Act
        await tester.tap(find.text('Retry'));
        await tester.pump();

        // Assert
        expect(mockController.retryCallCount, equals(1));
      });
    });

    group('Manual Location Functionality', () {
      testWidgets('set location button is always present', (tester) async {
        // Test with different states
        final states = [
          HomeStateLoading(startTime: DateTime.now()),
          HomeStateSuccess(
            riskData: TestData.createFireRisk(),
            location: TestData.edinburgh,
            lastUpdated: DateTime.now(),
          ),
          const HomeStateError(errorMessage: 'Test error'),
        ];

        for (final state in states) {
          mockController.setState(state);
          await tester.pumpWidget(buildHomeScreen());

          expect(
            find.text('Set Location'),
            findsOneWidget,
            reason: 'Set Location button should be present in all states',
          );
        }
      });

      testWidgets('set location button is present during loading', (
        tester,
      ) async {
        // Arrange
        mockController.setState(
          HomeStateLoading(startTime: DateTime.now()),
          loading: true,
        );

        await tester.pumpWidget(buildHomeScreen());

        // Act & Assert - Button should be present (but disabled)
        expect(find.text('Set Location'), findsOneWidget);

        // Try to tap it - should not trigger any action when disabled
        await tester.tap(find.text('Set Location'));
        await tester.pump();

        // Manual location call count should remain 0 since button is disabled
        expect(mockController.setManualLocationCallCount, equals(0));
      });

      testWidgets('tapping set location opens manual location dialog', (
        tester,
      ) async {
        // Arrange
        mockController.setState(
          HomeStateSuccess(
            riskData: TestData.createFireRisk(),
            location: TestData.edinburgh,
            lastUpdated: DateTime.now(),
          ),
        );

        await tester.pumpWidget(buildHomeScreen());

        // Act
        await tester.tap(find.text('Set Location'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(ManualLocationDialog), findsOneWidget);
      });
    });

    group('Accessibility (C3 Compliance)', () {
      testWidgets('buttons meet 44dp minimum touch target', (tester) async {
        // Arrange
        mockController.setState(
          const HomeStateError(errorMessage: 'Test error', canRetry: true),
        );

        await tester.pumpWidget(buildHomeScreen());

        // Assert - Check retry button
        final retryButton = find.byType(ElevatedButton);
        if (retryButton.evaluate().isNotEmpty) {
          final retrySize = tester.getSize(retryButton);
          expect(retrySize.height, greaterThanOrEqualTo(44.0));
        }

        // Assert - Check set location button (should always be present)
        final setLocationButton = find.byType(OutlinedButton);
        if (setLocationButton.evaluate().isNotEmpty) {
          final setLocationSize = tester.getSize(setLocationButton);
          expect(setLocationSize.height, greaterThanOrEqualTo(44.0));
        }
      });

      testWidgets('has proper semantic labels for retry button', (
        tester,
      ) async {
        // Arrange
        mockController.setState(
          const HomeStateError(errorMessage: 'Test error', canRetry: true),
        );

        await tester.pumpWidget(buildHomeScreen());

        // Act & Assert
        final retrySemantics = find.bySemanticsLabel(
          'Retry loading fire risk data',
        );
        expect(retrySemantics, findsOneWidget);
      });

      testWidgets('has proper semantic labels for set location button', (
        tester,
      ) async {
        // Arrange
        mockController.setState(
          HomeStateSuccess(
            riskData: TestData.createFireRisk(),
            location: TestData.edinburgh,
            lastUpdated: DateTime.now(),
          ),
        );

        await tester.pumpWidget(buildHomeScreen());

        // Act & Assert
        final setLocationSemantics = find.bySemanticsLabel(
          'Set manual location for fire risk assessment',
        );
        expect(setLocationSemantics, findsOneWidget);
      });

      testWidgets('timestamp has semantic label with source info', (
        tester,
      ) async {
        // Arrange
        final testRisk = TestData.createFireRisk(source: DataSource.effis);
        mockController.setState(
          HomeStateSuccess(
            riskData: testRisk,
            location: TestData.edinburgh,
            lastUpdated: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
        );

        await tester.pumpWidget(buildHomeScreen());

        // Act & Assert
        final timestampSemantics = find.bySemanticsLabel(
          RegExp(r'Current wildfire risk .*, .*, data from EFFIS'),
        );
        expect(timestampSemantics, findsOneWidget);
      });

      testWidgets('loading and error states have live region announcements', (
        tester,
      ) async {
        // Test loading state
        mockController.setState(HomeStateLoading(startTime: DateTime.now()));
        await tester.pumpWidget(buildHomeScreen());

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics && widget.properties.liveRegion == true,
          ),
          findsOneWidget,
        );

        // Test error state
        mockController.setState(
          const HomeStateError(errorMessage: 'Test error'),
        );
        await tester.pump();

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics && widget.properties.liveRegion == true,
          ),
          findsOneWidget,
        );
      });
    });

    group('C4 Transparency Compliance', () {
      testWidgets('success state shows timestamp and source information', (
        tester,
      ) async {
        // Arrange
        final testRisk = TestData.createFireRisk(source: DataSource.sepa);
        mockController.setState(
          HomeStateSuccess(
            riskData: testRisk,
            location: TestData.edinburgh,
            lastUpdated: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        );

        await tester.pumpWidget(buildHomeScreen());

        // Assert
        expect(find.textContaining('Updated'), findsAtLeastNWidgets(1));
        expect(
          find.textContaining('Data Source: SEPA'),
          findsAtLeastNWidgets(1),
        ); // Source label in RiskBanner
        // Icon assertions removed - RiskBanner displays location_on, not access_time
      });

      testWidgets('cached error state shows cached badge', (tester) async {
        // Arrange
        final cachedRisk = TestData.createFireRisk(
          source: DataSource.cache,
          freshness: Freshness.cached,
        );

        mockController.setState(
          HomeStateError(
            errorMessage: 'Network error',
            cachedData: cachedRisk,
            cachedLocation: TestData.edinburgh,
          ),
        );

        await tester.pumpWidget(buildHomeScreen());

        // Assert
        expect(find.text('Cached'), findsAtLeastNWidgets(1));
        expect(find.byIcon(Icons.cached), findsOneWidget);
      });
    });

    group('Edge Cases and Error Handling', () {
      testWidgets('handles rapid state changes gracefully', (tester) async {
        await tester.pumpWidget(buildHomeScreen());

        // Rapid state changes
        mockController.setState(HomeStateLoading(startTime: DateTime.now()));
        await tester.pump();

        mockController.setState(const HomeStateError(errorMessage: 'Error'));
        await tester.pump();

        mockController.setState(
          HomeStateSuccess(
            riskData: TestData.createFireRisk(),
            location: TestData.edinburgh,
            lastUpdated: DateTime.now(),
          ),
        );
        await tester.pump();

        // Should render final state without errors
        expect(find.textContaining('Updated'), findsAtLeastNWidgets(1));
      });

      testWidgets('does not show retry button when canRetry is false', (
        tester,
      ) async {
        // Arrange
        mockController.setState(
          const HomeStateError(
            errorMessage: 'Permanent error',
            canRetry: false,
          ),
        );

        await tester.pumpWidget(buildHomeScreen());

        // Assert
        expect(find.text('Retry'), findsNothing);
        expect(
          find.text('Set Location'),
          findsOneWidget,
        ); // Should still show this
      });
    });
  });
}
