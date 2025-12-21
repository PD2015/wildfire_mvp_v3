import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wildfire_mvp_v3/features/map/widgets/map_type_selector.dart';

void main() {
  group('MapTypeSelector', () {
    testWidgets('displays terrain icon for terrain map type', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapTypeSelector(
              currentMapType: MapType.terrain,
              onMapTypeChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.terrain), findsOneWidget);
    });

    testWidgets('displays satellite icon for satellite map type', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapTypeSelector(
              currentMapType: MapType.satellite,
              onMapTypeChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.satellite_alt), findsOneWidget);
    });

    testWidgets('displays layers icon for hybrid map type', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapTypeSelector(
              currentMapType: MapType.hybrid,
              onMapTypeChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.layers), findsOneWidget);
    });

    testWidgets('displays map icon for normal map type', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapTypeSelector(
              currentMapType: MapType.normal,
              onMapTypeChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.map), findsOneWidget);
    });

    testWidgets('opens popup menu on tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapTypeSelector(
              currentMapType: MapType.terrain,
              onMapTypeChanged: (_) {},
            ),
          ),
        ),
      );

      // Tap the icon button to open menu
      await tester.tap(find.byType(PopupMenuButton<MapType>));
      await tester.pumpAndSettle();

      // Menu items should be visible
      expect(find.text('Terrain'), findsOneWidget);
      expect(find.text('Satellite'), findsOneWidget);
      expect(find.text('Hybrid'), findsOneWidget);
      expect(find.text('Normal'), findsOneWidget);
    });

    testWidgets('calls onMapTypeChanged when menu item selected', (
      tester,
    ) async {
      MapType? selectedType;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapTypeSelector(
              currentMapType: MapType.terrain,
              onMapTypeChanged: (type) {
                selectedType = type;
              },
            ),
          ),
        ),
      );

      // Open popup menu
      await tester.tap(find.byType(PopupMenuButton<MapType>));
      await tester.pumpAndSettle();

      // Select satellite
      await tester.tap(find.text('Satellite'));
      await tester.pumpAndSettle();

      expect(selectedType, equals(MapType.satellite));
    });

    testWidgets('highlights currently selected map type in menu', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapTypeSelector(
              currentMapType: MapType.hybrid,
              onMapTypeChanged: (_) {},
            ),
          ),
        ),
      );

      // Open popup menu
      await tester.tap(find.byType(PopupMenuButton<MapType>));
      await tester.pumpAndSettle();

      // Find the Hybrid text and verify it has bold styling
      final hybridText = tester.widget<Text>(find.text('Hybrid'));
      expect(hybridText.style?.fontWeight, equals(FontWeight.bold));

      // Other items should not be bold
      final terrainText = tester.widget<Text>(find.text('Terrain'));
      expect(terrainText.style?.fontWeight, isNot(equals(FontWeight.bold)));
    });

    testWidgets('has proper semantics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapTypeSelector(
              currentMapType: MapType.terrain,
              onMapTypeChanged: (_) {},
            ),
          ),
        ),
      );

      // Find the outer Semantics widget with current map type in label
      final semanticsFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label != null &&
            widget.properties.label!.contains('currently Terrain'),
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('uses grey icon color matching Google Maps style', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(useMaterial3: true),
          home: Scaffold(
            body: MapTypeSelector(
              currentMapType: MapType.terrain,
              onMapTypeChanged: (_) {},
            ),
          ),
        ),
      );

      // Get the icon and verify it uses onSurfaceVariant color
      final icon = tester.widget<Icon>(find.byIcon(Icons.terrain));
      final colorScheme = Theme.of(
        tester.element(find.byType(MapTypeSelector)),
      ).colorScheme;

      expect(icon.color, equals(colorScheme.onSurfaceVariant));
    });

    testWidgets('has container with rounded corners and shadow', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapTypeSelector(
              currentMapType: MapType.terrain,
              onMapTypeChanged: (_) {},
            ),
          ),
        ),
      );

      // Find the container with decoration
      final container = tester.widget<Container>(
        find.byKey(const Key('map_type_selector_container')),
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, equals(BorderRadius.circular(8)));
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow!.length, equals(1));
    });
  });
}
