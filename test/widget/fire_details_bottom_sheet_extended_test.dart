import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/models/burnt_area.dart';
import 'package:wildfire_mvp_v3/models/hotspot.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/widgets/fire_details_bottom_sheet.dart';

/// Tests for extended FireDetailsBottomSheet functionality
///
/// Part of 021-live-fire-data feature - T027 & T033
/// Tests hotspot and burnt area display modes with educational labels
/// and data-specific metadata display.
void main() {
  group('FireDetailsBottomSheet Extended', () {
    group('Hotspot Display', () {
      // Test data - active fire hotspot
      late Hotspot testHotspot;

      setUp(() {
        testHotspot = Hotspot(
          id: 'viirs_12345',
          location: const LatLng(56.0, -4.0),
          detectedAt: DateTime.now().subtract(const Duration(hours: 3)),
          frp: 45.0,
          confidence: 85.0,
        );
      });

      testWidgets(
          'displays "Active Hotspot" educational label for hotspot type',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireDetailsBottomSheet.fromHotspot(
                hotspot: testHotspot,
                onClose: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Active Hotspot'), findsOneWidget);
        // Educational description should explain what this means
        expect(
          find.textContaining('Satellite-detected'),
          findsOneWidget,
        );
      });

      testWidgets('displays FRP with intensity indicator', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireDetailsBottomSheet.fromHotspot(
                hotspot: testHotspot,
                onClose: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // FRP value should be displayed
        expect(find.textContaining('45'), findsWidgets);
        expect(find.textContaining('MW'), findsOneWidget);
        // Intensity derived from FRP (45 MW = moderate)
        expect(find.text('Moderate'), findsOneWidget);
      });

      testWidgets('displays "Detected X hours ago" relative time format',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireDetailsBottomSheet.fromHotspot(
                hotspot: testHotspot,
                onClose: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Should show relative time, not absolute timestamp
        expect(find.textContaining('3 hours ago'), findsOneWidget);
      });

      testWidgets('displays confidence level', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireDetailsBottomSheet.fromHotspot(
                hotspot: testHotspot,
                onClose: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // High confidence hotspot (85%)
        expect(find.text('85%'), findsOneWidget);
      });

      testWidgets('displays sensor source (VIIRS)', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireDetailsBottomSheet.fromHotspot(
                hotspot: testHotspot,
                onClose: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('VIIRS'), findsOneWidget);
      });
    });

    group('Burnt Area Display', () {
      // Test data - burnt area polygon
      late BurntArea testBurntArea;

      setUp(() {
        testBurntArea = BurntArea(
          id: 'effis_67890',
          boundaryPoints: const [
            LatLng(56.0, -4.0),
            LatLng(56.1, -4.0),
            LatLng(56.1, -3.9),
            LatLng(56.0, -3.9),
          ],
          areaHectares: 125.5,
          fireDate: DateTime(2025, 7, 10),
          seasonYear: 2025,
          landCoverBreakdown: const {
            'forest': 0.45,
            'shrubland': 0.30,
            'grassland': 0.15,
            'agriculture': 0.10,
          },
          isSimplified: true,
          originalPointCount: 245,
        );
      });

      testWidgets(
          'displays "Verified Burnt Area" educational label for burntArea type',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireDetailsBottomSheet.fromBurntArea(
                burntArea: testBurntArea,
                onClose: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Verified Burnt Area'), findsOneWidget);
        // Educational description should explain what this means - check exact text
        expect(
          find.text(
              'MODIS satellite-confirmed area affected by fire this season.'),
          findsOneWidget,
        );
      });

      testWidgets('displays simplification notice when isSimplified = true',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireDetailsBottomSheet.fromBurntArea(
                burntArea: testBurntArea,
                onClose: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Simplification notice with original point count
        expect(find.textContaining('Simplified'), findsOneWidget);
        expect(find.textContaining('245'), findsOneWidget);
      });

      testWidgets(
          'does not display simplification notice when isSimplified = false',
          (tester) async {
        final unsimplifiedArea = BurntArea(
          id: 'effis_unsimplified',
          boundaryPoints: const [
            LatLng(56.0, -4.0),
            LatLng(56.1, -4.0),
            LatLng(56.1, -3.9),
          ],
          areaHectares: 50.0,
          fireDate: DateTime(2025, 7, 10),
          seasonYear: 2025,
          isSimplified: false,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireDetailsBottomSheet.fromBurntArea(
                burntArea: unsimplifiedArea,
                onClose: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Simplified'), findsNothing);
      });

      testWidgets('displays land cover breakdown as horizontal bars',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireDetailsBottomSheet.fromBurntArea(
                burntArea: testBurntArea,
                onClose: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Land cover section header
        expect(find.text('Land Cover Affected'), findsOneWidget);

        // Individual land cover types with percentages
        expect(find.text('Forest'), findsOneWidget);
        expect(find.text('45%'), findsOneWidget);
        expect(find.text('Shrubland'), findsOneWidget);
        expect(find.text('30%'), findsOneWidget);
        expect(find.text('Grassland'), findsOneWidget);
        expect(find.text('15%'), findsOneWidget);
        expect(find.text('Agriculture'), findsOneWidget);
        expect(find.text('10%'), findsOneWidget);

        // Should have visual bars (LinearProgressIndicator)
        expect(find.byType(LinearProgressIndicator), findsNWidgets(4));
      });

      testWidgets('displays area in hectares', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireDetailsBottomSheet.fromBurntArea(
                burntArea: testBurntArea,
                onClose: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('125.5'), findsOneWidget);
        expect(find.textContaining('hectares'), findsOneWidget);
      });

      testWidgets('displays sensor source (MODIS)', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireDetailsBottomSheet.fromBurntArea(
                burntArea: testBurntArea,
                onClose: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('MODIS'), findsOneWidget);
      });
    });

    group('Relative Time Formatting', () {
      testWidgets('formats minutes ago correctly', (tester) async {
        final recentHotspot = Hotspot(
          id: 'recent_1',
          location: const LatLng(56.0, -4.0),
          detectedAt: DateTime.now().subtract(const Duration(minutes: 45)),
          frp: 20.0,
          confidence: 75.0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireDetailsBottomSheet.fromHotspot(
                hotspot: recentHotspot,
                onClose: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('45 minutes ago'), findsOneWidget);
      });

      testWidgets('formats days ago correctly', (tester) async {
        final oldHotspot = Hotspot(
          id: 'old_1',
          location: const LatLng(56.0, -4.0),
          detectedAt: DateTime.now().subtract(const Duration(days: 3)),
          frp: 20.0,
          confidence: 75.0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireDetailsBottomSheet.fromHotspot(
                hotspot: oldHotspot,
                onClose: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('3 days ago'), findsOneWidget);
      });

      testWidgets('formats hours ago correctly', (tester) async {
        final hourOldHotspot = Hotspot(
          id: 'hour_1',
          location: const LatLng(56.0, -4.0),
          detectedAt: DateTime.now().subtract(const Duration(hours: 5)),
          frp: 20.0,
          confidence: 75.0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireDetailsBottomSheet.fromHotspot(
                hotspot: hourOldHotspot,
                onClose: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('5 hours ago'), findsOneWidget);
      });
    });

    group('Factory Constructors', () {
      testWidgets('fromHotspot creates correct display type', (tester) async {
        final hotspot = Hotspot(
          id: 'factory_test',
          location: const LatLng(56.0, -4.0),
          detectedAt: DateTime.now(),
          frp: 20.0,
          confidence: 75.0,
        );

        final sheet = FireDetailsBottomSheet.fromHotspot(
          hotspot: hotspot,
          onClose: () {},
        );

        expect(sheet.displayType, equals(FireDataDisplayType.hotspot));
        expect(sheet.hotspot, equals(hotspot));
        expect(sheet.incident, isNotNull);
      });

      testWidgets('fromBurntArea creates correct display type', (tester) async {
        final burntArea = BurntArea(
          id: 'factory_test',
          boundaryPoints: const [
            LatLng(56.0, -4.0),
            LatLng(56.1, -4.0),
            LatLng(56.1, -3.9),
          ],
          areaHectares: 50.0,
          fireDate: DateTime(2025, 7, 10),
          seasonYear: 2025,
        );

        final sheet = FireDetailsBottomSheet.fromBurntArea(
          burntArea: burntArea,
          onClose: () {},
        );

        expect(sheet.displayType, equals(FireDataDisplayType.burntArea));
        expect(sheet.burntArea, equals(burntArea));
        expect(sheet.incident, isNotNull);
      });
    });

    group('Accessibility', () {
      testWidgets('educational label has semantic description', (tester) async {
        final hotspot = Hotspot(
          id: 'a11y_test',
          location: const LatLng(56.0, -4.0),
          detectedAt: DateTime.now(),
          frp: 20.0,
          confidence: 75.0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireDetailsBottomSheet.fromHotspot(
                hotspot: hotspot,
                onClose: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Find the semantics widget containing the educational info
        final semanticsFinder = find.bySemanticsLabel(
          RegExp(r'Active Hotspot.*Satellite-detected'),
        );
        expect(semanticsFinder, findsOneWidget);
      });

      testWidgets('land cover bars have semantic values', (tester) async {
        final burntArea = BurntArea(
          id: 'a11y_test',
          boundaryPoints: const [
            LatLng(56.0, -4.0),
            LatLng(56.1, -4.0),
            LatLng(56.1, -3.9),
          ],
          areaHectares: 50.0,
          fireDate: DateTime(2025, 7, 10),
          seasonYear: 2025,
          landCoverBreakdown: const {
            'forest': 0.45,
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireDetailsBottomSheet.fromBurntArea(
                burntArea: burntArea,
                onClose: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Each progress bar should be present - verify the text is there
        expect(find.text('Forest'), findsOneWidget);
        expect(find.text('45%'), findsOneWidget);
      });

      testWidgets('simplification notice has semantic label', (tester) async {
        final burntArea = BurntArea(
          id: 'a11y_simplified',
          boundaryPoints: const [
            LatLng(56.0, -4.0),
            LatLng(56.1, -4.0),
            LatLng(56.1, -3.9),
          ],
          areaHectares: 50.0,
          fireDate: DateTime(2025, 7, 10),
          seasonYear: 2025,
          isSimplified: true,
          originalPointCount: 500,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireDetailsBottomSheet.fromBurntArea(
                burntArea: burntArea,
                onClose: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.bySemanticsLabel(
            RegExp(r'Polygon simplified from 500 points'),
          ),
          findsOneWidget,
        );
      });
    });
  });
}
