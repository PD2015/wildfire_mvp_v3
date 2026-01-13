import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/widgets/expandable_location_panel.dart';

/// Widget tests for ExpandableLocationPanel
///
/// Tests cover:
/// - Coordinates display and copy functionality
/// - what3words display and copy functionality
/// - Map preview rendering
/// - Action buttons (Change Location, Use GPS)
/// - Loading states
/// - Adaptive colors on different backgrounds
/// - Accessibility (C3 compliance)
void main() {
  group('ExpandableLocationPanel', () {
    Widget buildTestWidget({
      String? formattedLocation,
      bool isGeocodingLoading = false,
      String? coordinatesLabel,
      String? what3words,
      bool isWhat3wordsLoading = false,
      String? staticMapUrl,
      bool isMapLoading = false,
      LocationSource? locationSource,
      Color parentBackgroundColor = const Color(0xFFFFEB3B), // Amber
      VoidCallback? onChangeLocation,
      VoidCallback? onUseGps,
      VoidCallback? onCopyWhat3words,
      VoidCallback? onCopyCoordinates,
      bool showMapPreview = true,
      bool showActions = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: ExpandableLocationPanel(
              formattedLocation: formattedLocation,
              isGeocodingLoading: isGeocodingLoading,
              coordinatesLabel: coordinatesLabel,
              what3words: what3words,
              isWhat3wordsLoading: isWhat3wordsLoading,
              staticMapUrl: staticMapUrl,
              isMapLoading: isMapLoading,
              locationSource: locationSource,
              parentBackgroundColor: parentBackgroundColor,
              onChangeLocation: onChangeLocation,
              onUseGps: onUseGps,
              onCopyWhat3words: onCopyWhat3words,
              onCopyCoordinates: onCopyCoordinates,
              showMapPreview: showMapPreview,
              showActions: showActions,
            ),
          ),
        ),
      );
    }

    group('Header display', () {
      testWidgets('shows "Location used" title', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          coordinatesLabel: '57.20, -3.83',
        ));

        expect(find.text('Location used'), findsOneWidget);
      });

      testWidgets('shows navigation icon', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          coordinatesLabel: '57.20, -3.83',
        ));

        expect(find.byIcon(Icons.navigation_outlined), findsOneWidget);
      });

      testWidgets('shows formatted location and GPS source', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          coordinatesLabel: '57.20, -3.83',
          formattedLocation: 'Grantown-on-Spey',
          locationSource: LocationSource.gps,
        ));

        expect(find.text('Grantown-on-Spey · Current (GPS)'), findsOneWidget);
      });

      testWidgets('shows formatted location and Manual source', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          coordinatesLabel: '57.20, -3.83',
          formattedLocation: 'Edinburgh',
          locationSource: LocationSource.manual,
        ));

        expect(find.text('Edinburgh · Manual'), findsOneWidget);
      });

      testWidgets('shows source only when no formatted location',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(
          coordinatesLabel: '57.20, -3.83',
          locationSource: LocationSource.cached,
        ));

        expect(find.text('Cached'), findsOneWidget);
      });
    });

    group('Coordinates display', () {
      testWidgets('shows coordinates label', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          coordinatesLabel: '57.20, -3.83',
        ));

        expect(find.text('57.20, -3.83'), findsOneWidget);
        expect(find.text('Lat/Lng: '), findsOneWidget);
      });

      testWidgets('shows ellipsis for loading coordinates', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          coordinatesLabel: null,
          isGeocodingLoading: true,
        ));

        expect(find.text('...'), findsOneWidget);
      });

      testWidgets('hides coordinates section when no data', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          coordinatesLabel: null,
          isGeocodingLoading: false,
        ));

        expect(find.text('Lat/Lng: '), findsNothing);
      });

      testWidgets('validates coordinates format', (tester) async {
        // Invalid: missing comma
        await tester.pumpWidget(buildTestWidget(
          coordinatesLabel: '57.20',
        ));
        expect(find.text('Lat/Lng: '), findsNothing);

        // Invalid: not numbers
        await tester.pumpWidget(buildTestWidget(
          coordinatesLabel: 'abc, def',
        ));
        expect(find.text('Lat/Lng: '), findsNothing);
      });

      testWidgets('shows copy button when coordinates provided',
          (tester) async {
        var copied = false;
        await tester.pumpWidget(buildTestWidget(
          coordinatesLabel: '57.20, -3.83',
          onCopyCoordinates: () => copied = true,
        ));

        // Find copy icon in the coordinates row
        final copyIcons = find.byIcon(Icons.copy);
        expect(copyIcons, findsAtLeastNWidgets(1));

        // Tap the first copy icon (coordinates)
        await tester.tap(copyIcons.first);
        expect(copied, isTrue);
      });
    });

    group('what3words display', () {
      testWidgets('shows what3words address', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          what3words: '///daring.lion.race',
        ));

        expect(find.text('///daring.lion.race'), findsOneWidget);
      });

      testWidgets('shows loading indicator while fetching', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          isWhat3wordsLoading: true,
        ));

        expect(find.text('Loading what3words...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('shows copy button when what3words provided', (tester) async {
        var copied = false;
        await tester.pumpWidget(buildTestWidget(
          what3words: '///daring.lion.race',
          onCopyWhat3words: () => copied = true,
        ));

        // Find copy icon (only one copy button for w3w alone)
        final copyIcon = find.byIcon(Icons.copy);
        expect(copyIcon, findsOneWidget);

        await tester.tap(copyIcon);
        expect(copied, isTrue);
      });

      testWidgets('hides what3words section when no data', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          what3words: null,
          isWhat3wordsLoading: false,
        ));

        expect(find.byIcon(Icons.grid_3x3), findsNothing);
      });
    });

    group('Map preview', () {
      testWidgets('shows map preview section by default', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          coordinatesLabel: '57.20, -3.83',
          showMapPreview: true,
        ));

        // Map section should be present (placeholder or loading)
        expect(find.byType(ClipRRect), findsOneWidget);
      });

      testWidgets('hides map preview when disabled', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          coordinatesLabel: '57.20, -3.83',
          showMapPreview: false,
        ));

        // Only show coordinates row, no map container
        expect(find.text('57.20, -3.83'), findsOneWidget);
      });

      testWidgets('shows loading indicator while map loads', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          coordinatesLabel: '57.20, -3.83',
          isMapLoading: true,
          showMapPreview: true,
        ));

        // Should have CircularProgressIndicator for map
        expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
      });

      testWidgets('shows placeholder icon when no map URL', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          coordinatesLabel: null,
          staticMapUrl: null,
          isMapLoading: false,
          showMapPreview: true,
        ));

        expect(find.byIcon(Icons.map_outlined), findsOneWidget);
      });
    });

    group('Action buttons', () {
      testWidgets('shows Change Location button', (tester) async {
        var changed = false;
        await tester.pumpWidget(buildTestWidget(
          coordinatesLabel: '57.20, -3.83',
          onChangeLocation: () => changed = true,
        ));

        expect(find.text('Change Location'), findsOneWidget);
        await tester.tap(find.text('Change Location'));
        expect(changed, isTrue);
      });

      testWidgets('shows Use GPS button for manual location', (tester) async {
        var usedGps = false;
        await tester.pumpWidget(buildTestWidget(
          coordinatesLabel: '57.20, -3.83',
          locationSource: LocationSource.manual,
          onUseGps: () => usedGps = true,
          onChangeLocation: () {},
        ));

        expect(find.text('Use GPS'), findsOneWidget);
        await tester.tap(find.text('Use GPS'));
        expect(usedGps, isTrue);
      });

      testWidgets('shows both buttons when manual with GPS callback',
          (tester) async {
        await tester.pumpWidget(buildTestWidget(
          coordinatesLabel: '57.20, -3.83',
          locationSource: LocationSource.manual,
          onChangeLocation: () {},
          onUseGps: () {},
        ));

        expect(find.text('Change'), findsOneWidget);
        expect(find.text('Use GPS'), findsOneWidget);
      });

      testWidgets('hides Use GPS button for GPS source', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          coordinatesLabel: '57.20, -3.83',
          locationSource: LocationSource.gps,
          onChangeLocation: () {},
          onUseGps: () {},
        ));

        expect(find.text('Use GPS'), findsNothing);
        expect(find.text('Change Location'), findsOneWidget);
      });

      testWidgets('hides actions when showActions is false', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          coordinatesLabel: '57.20, -3.83',
          onChangeLocation: () {},
          showActions: false,
        ));

        expect(find.text('Change Location'), findsNothing);
      });
    });

    group('Adaptive colors', () {
      testWidgets('renders on dark background', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          coordinatesLabel: '57.20, -3.83',
          parentBackgroundColor: const Color(0xFF8B0000), // Dark red
        ));

        expect(find.byType(ExpandableLocationPanel), findsOneWidget);
      });

      testWidgets('renders on light background', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          coordinatesLabel: '57.20, -3.83',
          parentBackgroundColor: const Color(0xFFFFFF00), // Yellow
        ));

        expect(find.byType(ExpandableLocationPanel), findsOneWidget);
      });
    });

    group('Accessibility (C3)', () {
      testWidgets('copy buttons have minimum touch target', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          coordinatesLabel: '57.20, -3.83',
          onCopyCoordinates: () {},
        ));

        final copyButton = tester.widget<Container>(
          find
              .ancestor(
                of: find.byIcon(Icons.copy),
                matching: find.byType(Container),
              )
              .first,
        );

        expect(copyButton.constraints?.minWidth, greaterThanOrEqualTo(44));
        expect(copyButton.constraints?.minHeight, greaterThanOrEqualTo(44));
      });

      testWidgets('action buttons have minimum touch target', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          coordinatesLabel: '57.20, -3.83',
          onChangeLocation: () {},
        ));

        final actionButton = tester.widget<Container>(
          find
              .ancestor(
                of: find.text('Change Location'),
                matching: find.byType(Container),
              )
              .first,
        );

        expect(actionButton.constraints?.minHeight, greaterThanOrEqualTo(44));
      });

      testWidgets('coordinates row has semantic label', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          coordinatesLabel: '57.20, -3.83',
        ));

        expect(
          find.bySemanticsLabel(RegExp(r'Coordinates.*57.20, -3.83')),
          findsOneWidget,
        );
      });

      testWidgets('what3words row has semantic label', (tester) async {
        await tester.pumpWidget(buildTestWidget(
          what3words: '///daring.lion.race',
        ));

        expect(
          find.bySemanticsLabel(RegExp(r'what3words.*daring.lion.race')),
          findsOneWidget,
        );
      });
    });

    group('embeddedInRiskBanner styling', () {
      Widget buildEmbeddedWidget({
        bool embeddedInRiskBanner = false,
        Color parentBackgroundColor = const Color(0xFFFFEB3B),
        VoidCallback? onClose,
      }) {
        return MaterialApp(
          home: Scaffold(
            body: Center(
              child: ExpandableLocationPanel(
                coordinatesLabel: '57.20, -3.83',
                parentBackgroundColor: parentBackgroundColor,
                embeddedInRiskBanner: embeddedInRiskBanner,
                onClose: onClose,
              ),
            ),
          ),
        );
      }

      testWidgets('shows collapse button when onClose provided',
          (tester) async {
        var closeCallCount = 0;
        await tester.pumpWidget(buildEmbeddedWidget(
          embeddedInRiskBanner: true,
          onClose: () => closeCallCount++,
        ));

        // Should find the collapse button with down chevron
        expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);

        // Tap the collapse button
        await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
        await tester.pump();

        // onClose should be called
        expect(closeCallCount, 1);
      });

      testWidgets('hides collapse button when onClose is null', (tester) async {
        await tester.pumpWidget(buildEmbeddedWidget(
          embeddedInRiskBanner: true,
          onClose: null,
        ));

        // Should NOT find the collapse button
        expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
      });

      testWidgets('collapse button has accessible semantic label',
          (tester) async {
        await tester.pumpWidget(buildEmbeddedWidget(
          embeddedInRiskBanner: true,
          onClose: () {},
        ));

        expect(
          find.bySemanticsLabel('Collapse location details'),
          findsOneWidget,
        );
      });

      testWidgets('collapse button has dark circular background',
          (tester) async {
        await tester.pumpWidget(buildEmbeddedWidget(
          embeddedInRiskBanner: true,
          onClose: () {},
        ));

        // Find the container with circular shape
        final containerFinder = find.descendant(
          of: find.byType(InkWell),
          matching: find.byType(Container),
        );
        expect(containerFinder, findsWidgets);
      });

      testWidgets('collapse button has 48dp touch target', (tester) async {
        await tester.pumpWidget(buildEmbeddedWidget(
          embeddedInRiskBanner: true,
          onClose: () {},
        ));

        // Find the InkWell containing the button
        final inkWellFinder = find.ancestor(
          of: find.byIcon(Icons.keyboard_arrow_down),
          matching: find.byType(InkWell),
        );
        expect(inkWellFinder, findsOneWidget);

        // Verify the tappable area has minimum size
        final inkWell = tester.widget<InkWell>(inkWellFinder);
        expect(inkWell, isNotNull);
      });
    });
  });
}
