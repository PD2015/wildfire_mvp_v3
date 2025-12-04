import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/features/report/widgets/report_fire_location_card.dart';
import 'package:wildfire_mvp_v3/models/location_display_state.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';

void main() {
  // Required for Clipboard operations
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReportFireLocationCard', () {
    const testCoordinates = LatLng(57.04850, -3.59620);
    const testWhat3words = '///filled.count.soap';
    const testPlaceName = 'Aviemore';

    Widget buildWidget({
      required LocationDisplayState locationState,
      VoidCallback? onChangeLocation,
      VoidCallback? onUseGps,
    }) {
      return MaterialApp(
        theme: ThemeData.light(useMaterial3: true),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReportFireLocationCard(
              locationState: locationState,
              onChangeLocation: onChangeLocation ?? () {},
              onUseGps: onUseGps,
            ),
          ),
        ),
      );
    }

    group('Header content', () {
      testWidgets('displays fire-specific header text', (tester) async {
        await tester.pumpWidget(buildWidget(
          locationState: const LocationDisplayInitial(),
        ));

        expect(find.text('Location to give when you call'), findsOneWidget);
        expect(
          find.text('Helps you tell 999 where the fire is.'),
          findsOneWidget,
        );
      });

      testWidgets('has my_location icon in header', (tester) async {
        await tester.pumpWidget(buildWidget(
          locationState: const LocationDisplayInitial(),
        ));

        expect(find.byIcon(Icons.my_location), findsOneWidget);
      });
    });

    group('Initial state', () {
      testWidgets('shows empty state message', (tester) async {
        await tester.pumpWidget(buildWidget(
          locationState: const LocationDisplayInitial(),
        ));

        expect(
          find.textContaining('Use the map to pick where the fire is'),
          findsOneWidget,
        );
      });

      testWidgets('shows "Open map to set location" button', (tester) async {
        await tester.pumpWidget(buildWidget(
          locationState: const LocationDisplayInitial(),
        ));

        expect(find.text('Open map to set location'), findsOneWidget);
      });

      testWidgets('button triggers onChangeLocation', (tester) async {
        var tapped = false;

        await tester.pumpWidget(buildWidget(
          locationState: const LocationDisplayInitial(),
          onChangeLocation: () => tapped = true,
        ));

        await tester.tap(find.text('Open map to set location'));
        expect(tapped, isTrue);
      });
    });

    group('Loading state', () {
      testWidgets('shows loading indicator', (tester) async {
        await tester.pumpWidget(buildWidget(
          locationState: const LocationDisplayLoading(),
        ));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Getting your location...'), findsOneWidget);
      });

      testWidgets('shows last known location if available', (tester) async {
        await tester.pumpWidget(buildWidget(
          locationState: const LocationDisplayLoading(
            lastKnownLocation: testCoordinates,
          ),
        ));

        // Should show 5dp formatted coordinates
        expect(find.textContaining('57.04850'), findsOneWidget);
        expect(find.textContaining('-3.59620'), findsOneWidget);
      });
    });

    group('Success state', () {
      testWidgets('displays 5dp precision coordinates', (tester) async {
        await tester.pumpWidget(buildWidget(
          locationState: LocationDisplaySuccess(
            coordinates: testCoordinates,
            source: LocationSource.gps,
            lastUpdated: DateTime.now(),
          ),
        ));

        // Should show precise coordinates with separate Latitude / Longitude labels
        expect(find.text('Latitude'), findsOneWidget);
        expect(find.text('Longitude'), findsOneWidget);
        expect(find.textContaining('57.04850'), findsOneWidget);
        expect(find.textContaining('-3.59620'), findsOneWidget);
      });

      testWidgets('shows helper text for fire service', (tester) async {
        await tester.pumpWidget(buildWidget(
          locationState: LocationDisplaySuccess(
            coordinates: testCoordinates,
            source: LocationSource.gps,
            lastUpdated: DateTime.now(),
          ),
        ));

        expect(
          find.text('Exact coordinates recommended for fire service'),
          findsOneWidget,
        );
      });

      testWidgets('displays what3words when available', (tester) async {
        await tester.pumpWidget(buildWidget(
          locationState: LocationDisplaySuccess(
            coordinates: testCoordinates,
            source: LocationSource.gps,
            lastUpdated: DateTime.now(),
            what3words: testWhat3words,
          ),
        ));

        expect(find.text('what3words'), findsOneWidget);
        expect(find.text(testWhat3words), findsOneWidget);
      });

      testWidgets('shows "Unavailable" when what3words is null',
          (tester) async {
        await tester.pumpWidget(buildWidget(
          locationState: LocationDisplaySuccess(
            coordinates: testCoordinates,
            source: LocationSource.gps,
            lastUpdated: DateTime.now(),
            what3words: null,
          ),
        ));

        expect(find.text('/// Unavailable'), findsOneWidget);
      });

      testWidgets('shows loading indicator for what3words', (tester) async {
        await tester.pumpWidget(buildWidget(
          locationState: LocationDisplaySuccess(
            coordinates: testCoordinates,
            source: LocationSource.gps,
            lastUpdated: DateTime.now(),
            isWhat3wordsLoading: true,
          ),
        ));

        // Should show multiple loading indicators (w3w + potentially geocoding)
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });

      testWidgets('shows place name when geocoding complete', (tester) async {
        await tester.pumpWidget(buildWidget(
          locationState: LocationDisplaySuccess(
            coordinates: testCoordinates,
            source: LocationSource.gps,
            lastUpdated: DateTime.now(),
            formattedLocation: testPlaceName,
          ),
        ));

        expect(find.text('Nearest place'), findsOneWidget);
        expect(find.text(testPlaceName), findsOneWidget);
      });

      testWidgets('shows Copy details button', (tester) async {
        await tester.pumpWidget(buildWidget(
          locationState: LocationDisplaySuccess(
            coordinates: testCoordinates,
            source: LocationSource.gps,
            lastUpdated: DateTime.now(),
          ),
        ));

        expect(find.text('Copy location for your call'), findsOneWidget);
      });

      testWidgets('Copy details copies coordinates and w3w', (tester) async {
        // Set up clipboard mock
        String? clipboardContent;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (MethodCall methodCall) async {
            if (methodCall.method == 'Clipboard.setData') {
              clipboardContent = (methodCall.arguments as Map)['text'];
            }
            return null;
          },
        );

        await tester.pumpWidget(buildWidget(
          locationState: LocationDisplaySuccess(
            coordinates: testCoordinates,
            source: LocationSource.gps,
            lastUpdated: DateTime.now(),
            what3words: testWhat3words,
          ),
        ));

        await tester.tap(find.text('Copy location for your call'));
        // Use pump() instead of pumpAndSettle() because SnackBar has ongoing animations
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(clipboardContent, contains('57.04850'));
        expect(clipboardContent, contains('-3.59620'));
        expect(clipboardContent, contains(testWhat3words));

        // Verify snackbar shows
        expect(
          find.textContaining('Location copied'),
          findsOneWidget,
        );
      });

      testWidgets('Copy details includes "Unavailable" when no w3w',
          (tester) async {
        String? clipboardContent;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (MethodCall methodCall) async {
            if (methodCall.method == 'Clipboard.setData') {
              clipboardContent = (methodCall.arguments as Map)['text'];
            }
            return null;
          },
        );

        await tester.pumpWidget(buildWidget(
          locationState: LocationDisplaySuccess(
            coordinates: testCoordinates,
            source: LocationSource.gps,
            lastUpdated: DateTime.now(),
            what3words: null,
          ),
        ));

        await tester.tap(find.text('Copy location for your call'));
        // Use pump() instead of pumpAndSettle() because SnackBar has ongoing animations
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(clipboardContent, contains('Unavailable'));
      });
    });

    group('Manual location handling', () {
      testWidgets('shows Use GPS button for manual locations', (tester) async {
        await tester.pumpWidget(buildWidget(
          locationState: LocationDisplaySuccess(
            coordinates: testCoordinates,
            source: LocationSource.manual,
            lastUpdated: DateTime.now(),
          ),
          onUseGps: () {},
        ));

        expect(find.text('Use GPS'), findsOneWidget);
        expect(find.text('Change'), findsOneWidget);
      });

      testWidgets('Use GPS button triggers callback', (tester) async {
        var tapped = false;

        await tester.pumpWidget(buildWidget(
          locationState: LocationDisplaySuccess(
            coordinates: testCoordinates,
            source: LocationSource.manual,
            lastUpdated: DateTime.now(),
          ),
          onUseGps: () => tapped = true,
        ));

        await tester.tap(find.text('Use GPS'));
        expect(tapped, isTrue);
      });

      testWidgets('shows Update location for GPS source', (tester) async {
        await tester.pumpWidget(buildWidget(
          locationState: LocationDisplaySuccess(
            coordinates: testCoordinates,
            source: LocationSource.gps,
            lastUpdated: DateTime.now(),
          ),
        ));

        expect(find.text('Update location'), findsOneWidget);
        expect(find.text('Use GPS'), findsNothing);
      });
    });

    group('Error state', () {
      testWidgets('shows error message', (tester) async {
        await tester.pumpWidget(buildWidget(
          locationState: const LocationDisplayError(
            message: 'GPS unavailable',
          ),
        ));

        expect(find.text('Could not get location'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('shows set location button', (tester) async {
        await tester.pumpWidget(buildWidget(
          locationState: const LocationDisplayError(
            message: 'GPS unavailable',
          ),
        ));

        expect(find.text('Open map to set location'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('has proper semantic labels', (tester) async {
        await tester.pumpWidget(buildWidget(
          locationState: const LocationDisplayInitial(),
        ));

        // Main container semantic label
        final semantics =
            tester.getSemantics(find.byType(ReportFireLocationCard));
        expect(semantics.label, contains('Location helper'));
      });

      testWidgets('buttons have minimum 48dp height', (tester) async {
        await tester.pumpWidget(buildWidget(
          locationState: const LocationDisplayInitial(),
        ));

        // Find the set location button by its text
        final buttonText = find.text('Open map to set location');
        expect(buttonText, findsOneWidget);

        // Get the SizedBox parent which has the height constraint
        // The button is wrapped in: SizedBox > Semantics > OutlinedButton.icon
        final sizedBox = find
            .ancestor(
              of: buttonText,
              matching: find.byType(SizedBox),
            )
            .first;

        final size = tester.getSize(sizedBox);
        expect(size.height, greaterThanOrEqualTo(48));
      });
    });
  });
}
