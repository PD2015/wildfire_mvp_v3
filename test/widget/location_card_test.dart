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

    testWidgets('button shows "Set" when no location', (tester) async {
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

      expect(find.text('Set'), findsOneWidget);
      expect(find.text('Change'), findsNothing);
    });

    testWidgets('button shows "Change" when location exists', (tester) async {
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

      expect(find.text('Change'), findsOneWidget);
      expect(find.text('Set'), findsNothing);
    });

    testWidgets('onChangeLocation callback fires when button tapped',
        (tester) async {
      bool callbackFired = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Current location',
              onChangeLocation: () => callbackFired = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Change'));
      await tester.pump();

      expect(callbackFired, isTrue);
    });

    testWidgets('no button shown when onChangeLocation is null',
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

      expect(find.byType(FilledButton), findsNothing);
      expect(find.text('Change'), findsNothing);
      expect(find.text('Set'), findsNothing);
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
      // Should show "Set" button (not "Change") because validation failed
      expect(find.text('Set'), findsOneWidget);
      expect(find.text('Change'), findsNothing);
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
      expect(find.text('Set'), findsOneWidget);
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

      expect(find.byIcon(Icons.gps_fixed), findsOneWidget);
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

      expect(find.byIcon(Icons.cached), findsOneWidget);
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

    testWidgets('card has minimum touch target height', (tester) async {
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

      final button = tester.getSize(find.byType(FilledButton));

      // Button should have minimum 36dp height + 16dp padding = 52dp total
      expect(button.height, greaterThanOrEqualTo(36));
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

    testWidgets('map preview tap triggers onTapMapPreview', (tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Current location (GPS)',
              staticMapUrl: 'https://maps.googleapis.com/maps/api/staticmap',
              onTapMapPreview: () => wasTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(LocationMiniMapPreview));
      await tester.pump();

      expect(wasTapped, isTrue);
    });

    testWidgets(
        'map preview falls back to onChangeLocation if onTapMapPreview not set',
        (tester) async {
      bool changeLocationCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationCard(
              coordinatesLabel: '55.95, -3.19',
              subtitle: 'Current location (GPS)',
              staticMapUrl: 'https://maps.googleapis.com/maps/api/staticmap',
              onChangeLocation: () => changeLocationCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(LocationMiniMapPreview));
      await tester.pump();

      expect(changeLocationCalled, isTrue);
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
      expect(find.byIcon(Icons.gps_fixed), findsOneWidget);
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
}
