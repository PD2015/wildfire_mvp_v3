import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/features/report/widgets/collapsible_location_card.dart';
import 'package:wildfire_mvp_v3/models/location_display_state.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';

/// Widget tests for CollapsibleLocationCard
///
/// Tests cover:
/// - Header display
/// - Location states (initial, loading, success, error)
/// - Expand/collapse functionality
/// - Action buttons (Copy, Update, Use GPS)
/// - Accessibility (C3 compliance)
void main() {
  group('CollapsibleLocationCard', () {
    const testCoordinates = LatLng(55.9533, -3.1883);
    final successState = LocationDisplaySuccess(
      coordinates: testCoordinates,
      source: LocationSource.gps,
      placeName: 'Edinburgh',
      what3words: '///word.word.word',
      lastUpdated: DateTime(2025, 1, 1),
    );

    Widget buildTestWidget({
      LocationDisplayState locationState = const LocationDisplayInitial(),
      VoidCallback? onCopyForCall,
      VoidCallback? onUpdateLocation,
      VoidCallback? onUseGps,
    }) {
      return MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CollapsibleLocationCard(
                locationState: locationState,
                onCopyForCall: onCopyForCall,
                onUpdateLocation: onUpdateLocation,
                onUseGps: onUseGps,
              ),
            ),
          ),
        ),
      );
    }

    group('Header display', () {
      testWidgets('shows location icon', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
      });

      testWidgets('shows correct header text', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.text('Your location for the call'), findsOneWidget);
      });

      testWidgets('has header semantic', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        // Find text with header semantic
        final header = find.text('Your location for the call');
        expect(header, findsOneWidget);

        final semanticsWidget = find.ancestor(
          of: header,
          matching: find.byType(Semantics),
        );
        expect(semanticsWidget, findsWidgets);
      });
    });

    group('Initial state', () {
      testWidgets('shows "No location set" message', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.text('No location set'), findsOneWidget);
      });

      testWidgets('shows "Set location" button', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.text('Set location'), findsOneWidget);
      });

      testWidgets('does not show expand button', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
      });
    });

    group('Loading state', () {
      testWidgets('shows loading indicator', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          locationState: const LocationDisplayLoading(),
        ));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('shows loading message', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          locationState: const LocationDisplayLoading(),
        ));

        expect(find.text('Finding your location...'), findsOneWidget);
      });

      testWidgets('shows last known location when available', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          locationState: const LocationDisplayLoading(
            lastKnownLocation: testCoordinates,
          ),
        ));

        expect(find.textContaining('Last known:'), findsOneWidget);
      });
    });

    group('Success state', () {
      testWidgets('shows place name with source in combined format',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(
          locationState: successState,
        ));

        // New format: "Edinburgh · GPS"
        expect(find.text('Edinburgh · GPS'), findsOneWidget);
      });

      testWidgets('shows location icon in header', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          locationState: successState,
        ));

        // Header uses location_on_outlined icon (no separate source icons)
        expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
      });

      testWidgets('shows Manual source in combined format', (tester) async {
        final manualState = LocationDisplaySuccess(
          coordinates: testCoordinates,
          source: LocationSource.manual,
          placeName: 'Test Place',
          lastUpdated: DateTime(2025, 1, 1),
        );

        await tester.pumpWidget(buildTestWidget(
          locationState: manualState,
        ));

        // New format: "Test Place · Manual"
        expect(find.text('Test Place · Manual'), findsOneWidget);
      });
    });

    group('Error state', () {
      testWidgets('shows error icon', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          locationState: const LocationDisplayError(message: 'GPS failed'),
        ));

        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('shows error message', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          locationState: const LocationDisplayError(message: 'GPS failed'),
        ));

        expect(find.text('GPS failed'), findsOneWidget);
      });
    });

    group('Action buttons', () {
      testWidgets('shows "Copy for your call" button when location available',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(
          locationState: successState,
          onCopyForCall: () {},
        ));

        expect(find.text('Copy for your call'), findsOneWidget);
      });

      testWidgets('calls onCopyForCall when tapped', (tester) async {
        bool called = false;
        await tester.pumpWidget(buildTestWidget(
          locationState: successState,
          onCopyForCall: () => called = true,
        ));

        await tester.tap(find.text('Copy for your call'));
        await tester.pump();

        expect(called, isTrue);
      });

      testWidgets(
          'copies location to clipboard when no callback provided (internal copy)',
          (tester) async {
        // Setup clipboard mock
        String? clipboardData;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (methodCall) async {
            if (methodCall.method == 'Clipboard.setData') {
              final args = methodCall.arguments as Map<dynamic, dynamic>;
              clipboardData = args['text'] as String?;
            }
            return null;
          },
        );

        await tester.pumpWidget(buildTestWidget(
          locationState: successState,
          // No onCopyForCall provided - uses internal copy
        ));

        await tester.tap(find.text('Copy for your call'));
        await tester.pumpAndSettle();

        // Verify clipboard contains location data
        expect(clipboardData, isNotNull);
        expect(clipboardData, contains('Edinburgh'));
        expect(clipboardData, contains('55.95330'));
        expect(clipboardData, contains('-3.18830'));
        expect(clipboardData, contains('word.word.word'));

        // Verify snackbar appears
        expect(find.text('Location copied to clipboard'), findsOneWidget);
      });

      testWidgets('shows "Change location" button when location available',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(
          locationState: successState,
          onUpdateLocation: () {},
        ));

        expect(find.text('Change location'), findsOneWidget);
      });

      testWidgets('calls onUpdateLocation when tapped', (tester) async {
        bool called = false;
        await tester.pumpWidget(buildTestWidget(
          locationState: successState,
          onUpdateLocation: () => called = true,
        ));

        await tester.tap(find.text('Change location'));
        await tester.pump();

        expect(called, isTrue);
      });

      // Note: 'Use GPS' button was removed from this widget in the redesign.
      // GPS functionality is now handled at the screen level.
    });

    group('Always visible content', () {
      testWidgets('shows what3words when location available', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          locationState: successState,
        ));

        expect(find.text('what3words'), findsOneWidget);
        expect(find.text('///word.word.word'), findsOneWidget);
      });

      testWidgets('shows coordinates with 5dp precision', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          locationState: successState,
        ));

        // Latitude and Longitude labels should be visible
        expect(find.text('Latitude'), findsOneWidget);
        expect(find.text('Longitude'), findsOneWidget);

        // 55.9533, -3.1883 with 5dp precision in separate boxes
        expect(find.text('55.95330'), findsOneWidget); // Latitude value
        expect(find.text('-3.18830'), findsOneWidget); // Longitude value
      });
    });

    group('Accessibility (C3)', () {
      testWidgets('has container semantic label', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        final semantics =
            tester.getSemantics(find.byType(CollapsibleLocationCard));
        expect(semantics.label, contains('Location'));
      });

      testWidgets('action buttons have minimum touch target', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          locationState: successState,
          onCopyForCall: () {},
          onUpdateLocation: () {},
        ));

        // Find "Copy for your call" text, then check its wrapping SizedBox has height 48
        final copyText = find.text('Copy for your call');
        expect(copyText, findsOneWidget);

        // The button should be wrapped in a SizedBox with height 48
        final sizedBoxAncestor = find.ancestor(
          of: copyText,
          matching: find.byWidgetPredicate(
            (widget) => widget is SizedBox && widget.height == 48,
          ),
        );
        expect(sizedBoxAncestor, findsOneWidget);
      });
    });
  });
}
