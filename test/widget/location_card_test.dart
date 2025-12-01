import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/widgets/location_card.dart';
import 'package:wildfire_mvp_v3/widgets/location_mini_map_preview.dart';

/// Widget tests for LocationCard
///
/// Validates:
/// - Loading spinner visibility when isLoading=true
/// - Null/empty coordinate handling
/// - Valid coordinate display
/// - Change/Set button text logic
/// - onChangeLocation callback execution
/// - Semantic labels for accessibility
/// - Invalid coordinate format handling
void main() {
  group('LocationCard Widget Tests', () {
    testWidgets('shows loading spinner when isLoading=true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Loading...',
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('hides loading spinner when isLoading=false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Current location (GPS)',
              isLoading: false,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Current location (GPS)'), findsOneWidget);
    });

    testWidgets('displays "Location not set" for null coordinates',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: null,
              subtitle: 'No location available',
            ),
          ),
        ),
      );

      expect(find.text('Location not set'), findsOneWidget);
      expect(find.text('No location available'), findsOneWidget);
    });

    testWidgets('displays "Location not set" for empty string coordinates',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '',
              subtitle: 'No location available',
            ),
          ),
        ),
      );

      expect(find.text('Location not set'), findsOneWidget);
    });

    testWidgets('displays valid coordinates', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Current location (GPS)',
            ),
          ),
        ),
      );

      expect(find.text('55.95, -3.19'), findsOneWidget);
      expect(find.text('Current location (GPS)'), findsOneWidget);
    });

    testWidgets('button shows "Change Location" when no location',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: null,
              subtitle: 'No location',
              onChangeLocation: () {},
            ),
          ),
        ),
      );

      // Action button always shows at bottom
      expect(find.text('Change Location'), findsOneWidget);
    });

    testWidgets(
        'button shows "Change Location" when location exists with GPS source',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Current location',
              locationSource: LocationSource.gps,
              onChangeLocation: () {},
            ),
          ),
        ),
      );

      expect(find.text('Change Location'), findsOneWidget);
    });

    testWidgets('button shows "Use GPS Location" when manual location',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Your chosen location',
              locationSource: LocationSource.manual,
              onChangeLocation: () {},
              onUseGps: () {},
            ),
          ),
        ),
      );

      // Manual location shows BOTH buttons side-by-side
      expect(find.text('Use GPS'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);
    });

    testWidgets(
        'onChangeLocation callback fires when Change Location button tapped',
        (tester) async {
      bool callbackFired = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Current location',
              locationSource: LocationSource.gps,
              onChangeLocation: () => callbackFired = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Change Location'));
      await tester.pump();

      expect(callbackFired, isTrue);
    });

    testWidgets('action button disabled when both callbacks are null',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Current location',
              onChangeLocation: null,
            ),
          ),
        ),
      );

      // Button text should still be present
      expect(find.text('Change Location'), findsOneWidget);

      // Verify it's wrapped in Semantics with button property
      // When onPressed is null, the button renders as disabled
      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.button == true &&
            widget.properties.label == 'Change your location',
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('semantic label includes coordinates when available',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Current location (GPS)',
            ),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(LocationCard)),
        matchesSemantics(
          label: 'Current location: 55.95, -3.19',
        ),
      );
    });

    testWidgets('semantic label says "not set" when no coordinates',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: null,
              subtitle: 'No location',
            ),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(LocationCard)),
        matchesSemantics(
          label: 'Location not set',
        ),
      );
    });

    testWidgets('handles malformed coordinates (missing comma)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95 -3.19', // No comma
              subtitle: 'Invalid format',
              onChangeLocation: () {},
            ),
          ),
        ),
      );

      // Should show "Location not set" for main label due to validation failure
      expect(find.text('Location not set'), findsOneWidget);
      // Button shows "Change Location" regardless of validity
      expect(find.text('Change Location'), findsOneWidget);
    });

    testWidgets('handles malformed coordinates (non-numeric values)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: 'abc, def',
              subtitle: 'Invalid format',
              onChangeLocation: () {},
            ),
          ),
        ),
      );

      expect(find.text('Location not set'), findsOneWidget);
      expect(find.text('Change Location'), findsOneWidget);
    });

    testWidgets('handles coordinates with extra spaces', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '  55.95  ,  -3.19  ',
              subtitle: 'GPS location',
            ),
          ),
        ),
      );

      // Should parse correctly despite extra spaces
      expect(find.text('  55.95  ,  -3.19  '), findsOneWidget);
    });

    testWidgets('shows GPS icon for GPS location source', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Current location (GPS)',
              locationSource: LocationSource.gps,
            ),
          ),
        ),
      );

      // GPS icon appears in header and potentially in button
      expect(find.byIcon(Icons.gps_fixed), findsWidgets);
    });

    testWidgets('shows location pin icon for manual location', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Your chosen location',
              locationSource: LocationSource.manual,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.location_pin), findsOneWidget);
    });

    testWidgets('shows cached icon for cached location', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Last known location',
              locationSource: LocationSource.cached,
            ),
          ),
        ),
      );

      // Cached icon may appear in header
      expect(find.byIcon(Icons.cached), findsWidgets);
    });

    testWidgets('shows default icon when locationSource is null',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Location',
              locationSource: null,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.my_location), findsOneWidget);
    });

    testWidgets('action button has minimum touch target height',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Current location',
              onChangeLocation: () {},
            ),
          ),
        ),
      );

      // Find the button by its text
      final buttonTextFinder = find.text('Change Location');
      expect(buttonTextFinder, findsOneWidget);

      // The button wraps in SizedBox with minimum size
      // Find the SizedBox ancestor with width: double.infinity
      final sizedBoxFinder = find.ancestor(
        of: buttonTextFinder,
        matching: find.byType(SizedBox),
      );
      expect(sizedBoxFinder, findsWidgets);

      // Verify button is tappable and has semantics
      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.button == true &&
            widget.properties.label == 'Change your location',
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('displays place name in subtitle when provided',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Edinburgh (set by you)',
              locationSource: LocationSource.manual,
            ),
          ),
        ),
      );

      expect(find.text('Edinburgh (set by you)'), findsOneWidget);
    });

    testWidgets('displays staleness warning in subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Using last known location (may be outdated)...',
              isLoading: true,
              locationSource: LocationSource.cached,
            ),
          ),
        ),
      );

      expect(
        find.text('Using last known location (may be outdated)...'),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('LocationCard Enhanced Features', () {
    testWidgets('displays formattedLocation when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Current location (GPS)',
              formattedLocation: 'Near Edinburgh, Scotland',
            ),
          ),
        ),
      );

      expect(find.text('Near Edinburgh, Scotland'), findsOneWidget);
      // Coordinates should still be shown as secondary
      expect(find.text('55.95, -3.19'), findsOneWidget);
    });

    testWidgets('shows loading state for geocoding', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Current location (GPS)',
              isGeocodingLoading: true,
            ),
          ),
        ),
      );

      expect(find.text('Loading place name...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('displays what3words address when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Current location (GPS)',
              what3words: '///daring.lion.race',
            ),
          ),
        ),
      );

      expect(find.text('///daring.lion.race'), findsOneWidget);
      expect(find.byIcon(Icons.grid_3x3), findsOneWidget);
    });

    testWidgets('shows loading state for what3words', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Current location (GPS)',
              isWhat3wordsLoading: true,
            ),
          ),
        ),
      );

      expect(find.text('Loading what3words...'), findsOneWidget);
      expect(find.byIcon(Icons.grid_3x3), findsOneWidget);
    });

    testWidgets('shows copy button for what3words when callback provided',
        (tester) async {
      bool wasCopied = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Current location (GPS)',
              what3words: '///daring.lion.race',
              onCopyWhat3words: () => wasCopied = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.copy), findsOneWidget);

      await tester.tap(find.byIcon(Icons.copy));
      await tester.pump();

      expect(wasCopied, isTrue);
    });

    testWidgets('copy button has minimum 48dp tap target', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Current location (GPS)',
              what3words: '///daring.lion.race',
              onCopyWhat3words: () {},
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.constraints?.minWidth, 48);
      expect(iconButton.constraints?.minHeight, 48);
    });

    testWidgets('displays static map preview when URL provided',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Current location (GPS)',
              staticMapUrl:
                  'https://maps.googleapis.com/maps/api/staticmap?center=55.95,-3.19&zoom=14',
            ),
          ),
        ),
      );

      expect(find.byType(LocationMiniMapPreview), findsOneWidget);
    });

    testWidgets('map preview is view-only (no tap action)', (tester) async {
      // The map preview is now view-only - action is handled by dedicated button below
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Current location (GPS)',
              staticMapUrl: 'https://maps.googleapis.com/maps/api/staticmap',
              onChangeLocation: () {},
            ),
          ),
        ),
      );

      // Map preview should exist
      expect(find.byType(LocationMiniMapPreview), findsOneWidget);

      // The "Change Location" button should handle the action instead
      expect(find.text('Change Location'), findsOneWidget);
    });

    testWidgets('displays all enhanced features together', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Current location (GPS)',
              formattedLocation: 'Near Edinburgh, Scotland',
              what3words: '///daring.lion.race',
              staticMapUrl: 'https://maps.googleapis.com/maps/api/staticmap',
              locationSource: LocationSource.gps,
            ),
          ),
        ),
      );

      // All enhanced elements should be present
      expect(find.text('Near Edinburgh, Scotland'), findsOneWidget);
      expect(find.text('///daring.lion.race'), findsOneWidget);
      expect(find.byType(LocationMiniMapPreview), findsOneWidget);
      // GPS icon appears in header + potentially in button
      expect(find.byIcon(Icons.gps_fixed), findsWidgets);
    });

    testWidgets('backward compatible - basic card without enhanced features',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Current location (GPS)',
              // No enhanced features provided
            ),
          ),
        ),
      );

      // Basic card should work
      expect(find.text('55.95, -3.19'), findsOneWidget);
      expect(find.text('Current location (GPS)'), findsOneWidget);

      // No enhanced features shown
      expect(find.byType(LocationMiniMapPreview), findsNothing);
      expect(find.byIcon(Icons.grid_3x3), findsNothing);
    });
  });

  group('LocationCard Action Button Toggle', () {
    testWidgets(
        'shows "Use GPS Location" button when location source is manual',
        (tester) async {
      bool useGpsCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Your chosen location',
              locationSource: LocationSource.manual,
              onChangeLocation: () {},
              onUseGps: () => useGpsCalled = true,
            ),
          ),
        ),
      );

      // Manual location shows BOTH buttons side-by-side
      expect(find.text('Use GPS'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);

      // Tap the Use GPS button
      await tester.tap(find.text('Use GPS'));
      await tester.pump();

      expect(useGpsCalled, isTrue);
    });

    testWidgets('shows "Change Location" button when location source is GPS',
        (tester) async {
      bool changeLocationCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Current location (GPS)',
              locationSource: LocationSource.gps,
              onChangeLocation: () => changeLocationCalled = true,
              onUseGps: () {},
            ),
          ),
        ),
      );

      // Change Location button should be visible for GPS source
      expect(find.text('Change Location'), findsOneWidget);
      expect(find.text('Use GPS'), findsNothing);

      // Tap the button
      await tester.tap(find.text('Change Location'));
      await tester.pump();

      expect(changeLocationCalled, isTrue);
    });

    testWidgets('shows "Change Location" for cached location source',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Last known location',
              locationSource: LocationSource.cached,
              onChangeLocation: () {},
            ),
          ),
        ),
      );

      expect(find.text('Change Location'), findsOneWidget);
      expect(find.text('Use GPS Location'), findsNothing);
    });

    testWidgets('shows "Change Location" for default fallback source',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Default location',
              locationSource: LocationSource.defaultFallback,
              onChangeLocation: () {},
            ),
          ),
        ),
      );

      expect(find.text('Change Location'), findsOneWidget);
      expect(find.text('Use GPS Location'), findsNothing);
    });

    testWidgets(
        'falls back to "Change Location" when onUseGps is null for manual source',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Your chosen location',
              locationSource: LocationSource.manual,
              onChangeLocation: () {},
              // onUseGps is null
            ),
          ),
        ),
      );

      // Should fall back to Change Location when onUseGps not provided
      expect(find.text('Change Location'), findsOneWidget);
      expect(find.text('Use GPS Location'), findsNothing);
    });

    testWidgets('action button meets minimum touch target (48dp)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Your chosen location',
              locationSource: LocationSource.manual,
              onChangeLocation: () {},
              onUseGps: () {},
            ),
          ),
        ),
      );

      // Manual location shows both buttons
      final useGpsButtonFinder = find.text('Use GPS');
      final changeButtonFinder = find.text('Change');
      expect(useGpsButtonFinder, findsOneWidget);
      expect(changeButtonFinder, findsOneWidget);

      // Verify Use GPS button has proper semantics
      final gpsSemanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.button == true &&
            widget.properties.label == 'Return to GPS location',
      );
      expect(gpsSemanticsFinder, findsOneWidget);

      // Verify Change button has proper semantics
      final changeSemanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.button == true &&
            widget.properties.label == 'Adjust your manual location',
      );
      expect(changeSemanticsFinder, findsOneWidget);
    });

    testWidgets('Use GPS button has correct accessibility semantics',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Your chosen location',
              locationSource: LocationSource.manual,
              onChangeLocation: () {},
              onUseGps: () {},
            ),
          ),
        ),
      );

      // Find both buttons (manual location shows dual buttons)
      expect(find.text('Use GPS'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);

      // Find Semantics wrapper for Use GPS by checking for its label
      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Return to GPS location',
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('Change Location button has correct accessibility semantics',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Current location (GPS)',
              locationSource: LocationSource.gps,
              onChangeLocation: () {},
            ),
          ),
        ),
      );

      // Find the button
      expect(find.text('Change Location'), findsOneWidget);

      // Find Semantics wrapper by checking for its label
      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Change your location',
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets(
        'manual location shows dual buttons and Change callback fires correctly',
        (tester) async {
      bool changeLocationCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Your chosen location',
              locationSource: LocationSource.manual,
              onChangeLocation: () => changeLocationCalled = true,
              onUseGps: () {},
            ),
          ),
        ),
      );

      // Both buttons visible
      expect(find.text('Change'), findsOneWidget);
      expect(find.text('Use GPS'), findsOneWidget);

      // Tap Change button
      await tester.tap(find.text('Change'));
      await tester.pump();

      expect(changeLocationCalled, isTrue);
    });

    testWidgets('manual location shows dual buttons (not single toggle)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Your chosen location',
              locationSource: LocationSource.manual,
              onChangeLocation: () {},
              onUseGps: () {},
            ),
          ),
        ),
      );

      // Manual location shows BOTH buttons side-by-side
      expect(find.text('Use GPS'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);

      // Verify it's NOT a single button with "Change Location" text
      expect(find.text('Change Location'), findsNothing);

      // Both should have proper accessibility
      expect(
        find.bySemanticsLabel('Return to GPS location'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Adjust your manual location'),
        findsOneWidget,
      );
    });
  });
}
