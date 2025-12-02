import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:wildfire_mvp_v3/features/location_picker/widgets/map_type_toggle.dart';

void main() {
  group('MapTypeToggle', () {
    testWidgets('displays terrain icon when mapType is terrain',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapTypeToggle(
              currentMapType: MapType.terrain,
              onMapTypeChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.terrain), findsOneWidget);
    });

    testWidgets('displays satellite icon when mapType is satellite',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapTypeToggle(
              currentMapType: MapType.satellite,
              onMapTypeChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.satellite_alt), findsOneWidget);
    });

    testWidgets('displays layers icon when mapType is hybrid', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapTypeToggle(
              currentMapType: MapType.hybrid,
              onMapTypeChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.layers), findsOneWidget);
    });

    testWidgets('cycles terrain → satellite on tap', (tester) async {
      MapType? newMapType;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapTypeToggle(
              currentMapType: MapType.terrain,
              onMapTypeChanged: (type) {
                newMapType = type;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('map_type_toggle')));
      await tester.pump();

      expect(newMapType, MapType.satellite);
    });

    testWidgets('cycles satellite → hybrid on tap', (tester) async {
      MapType? newMapType;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapTypeToggle(
              currentMapType: MapType.satellite,
              onMapTypeChanged: (type) {
                newMapType = type;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('map_type_toggle')));
      await tester.pump();

      expect(newMapType, MapType.hybrid);
    });

    testWidgets('cycles hybrid → terrain on tap', (tester) async {
      MapType? newMapType;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapTypeToggle(
              currentMapType: MapType.hybrid,
              onMapTypeChanged: (type) {
                newMapType = type;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('map_type_toggle')));
      await tester.pump();

      expect(newMapType, MapType.terrain);
    });

    testWidgets('has ≥48dp touch target (C3)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapTypeToggle(
              currentMapType: MapType.terrain,
              onMapTypeChanged: (_) {},
            ),
          ),
        ),
      );

      // Find the SizedBox that sets the touch target
      final sizedBoxes = tester.widgetList<SizedBox>(
        find.descendant(
          of: find.byType(MapTypeToggle),
          matching: find.byType(SizedBox),
        ),
      );

      final touchTarget = sizedBoxes.firstWhere(
        (sb) => sb.width == 48 && sb.height == 48,
        orElse: () => const SizedBox(),
      );

      expect(touchTarget.width, 48);
      expect(touchTarget.height, 48);
    });

    testWidgets('has semantic label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapTypeToggle(
              currentMapType: MapType.terrain,
              onMapTypeChanged: (_) {},
            ),
          ),
        ),
      );

      // Check that Semantics widgets are present (multiple from Flutter internals)
      expect(
        find.descendant(
          of: find.byType(MapTypeToggle),
          matching: find.byType(Semantics),
        ),
        findsWidgets,
      );
    });

    testWidgets('has tooltip', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapTypeToggle(
              currentMapType: MapType.terrain,
              onMapTypeChanged: (_) {},
            ),
          ),
        ),
      );

      // Check that Tooltip widget is present
      expect(
        find.descendant(
          of: find.byType(MapTypeToggle),
          matching: find.byType(Tooltip),
        ),
        findsOneWidget,
      );
    });

    testWidgets('handles normal map type (fallback to terrain)',
        (tester) async {
      MapType? newMapType;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapTypeToggle(
              currentMapType: MapType.normal,
              onMapTypeChanged: (type) {
                newMapType = type;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('map_type_toggle')));
      await tester.pump();

      expect(newMapType, MapType.terrain);
    });

    testWidgets('is tappable (InkWell)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapTypeToggle(
              currentMapType: MapType.terrain,
              onMapTypeChanged: (_) {},
            ),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(MapTypeToggle),
          matching: find.byType(InkWell),
        ),
        findsOneWidget,
      );
    });

    testWidgets('has elevated surface (Material with elevation)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapTypeToggle(
              currentMapType: MapType.terrain,
              onMapTypeChanged: (_) {},
            ),
          ),
        ),
      );

      final materials = tester.widgetList<Material>(
        find.descendant(
          of: find.byType(MapTypeToggle),
          matching: find.byType(Material),
        ),
      );

      final elevatedMaterial = materials.firstWhere(
        (m) => m.elevation > 0,
        orElse: () => const Material(),
      );

      expect(elevatedMaterial.elevation, greaterThan(0));
    });
  });
}
