import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wildfire_mvp_v3/features/location_picker/widgets/crosshair_overlay.dart';
import 'package:wildfire_mvp_v3/theme/brand_palette.dart';

void main() {
  group('CrosshairOverlay', () {
    testWidgets('renders location pin icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Stack(children: [CrosshairOverlay()])),
        ),
      );

      // Should render location pin icons (main + shadow layers)
      expect(find.byIcon(Icons.location_pin), findsWidgets);
    });

    testWidgets('uses default size of 48dp', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Stack(children: [CrosshairOverlay()])),
        ),
      );

      // Find the SizedBox that wraps the crosshair (first one with explicit width)
      final sizedBoxes = tester.widgetList<SizedBox>(
        find.descendant(
          of: find.byType(CrosshairOverlay),
          matching: find.byType(SizedBox),
        ),
      );

      // Find the one with width/height set to 48
      final mainSizedBox = sizedBoxes.firstWhere(
        (sb) => sb.width == 48.0 && sb.height == 48.0,
      );

      expect(mainSizedBox.width, 48.0);
      expect(mainSizedBox.height, 48.0);
    });

    testWidgets('uses default icon size of 36dp', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Stack(children: [CrosshairOverlay()])),
        ),
      );

      // Find all Icon widgets and check their sizes
      final icons = tester.widgetList<Icon>(find.byType(Icon));
      for (final icon in icons) {
        expect(icon.size, 36.0);
      }
    });

    testWidgets('uses BrandPalette.forest600 for main icon color', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Stack(children: [CrosshairOverlay()])),
        ),
      );

      // Find the main icon (forest600 color)
      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();

      // At least one icon should have forest600 color
      final hasForestIcon = icons.any(
        (icon) => icon.color == BrandPalette.forest600,
      );
      expect(hasForestIcon, isTrue);
    });

    testWidgets('respects custom size parameter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Stack(children: [CrosshairOverlay(size: 64.0)])),
        ),
      );

      final sizedBoxes = tester.widgetList<SizedBox>(
        find.descendant(
          of: find.byType(CrosshairOverlay),
          matching: find.byType(SizedBox),
        ),
      );

      // Find the one with width/height set to 64
      final mainSizedBox = sizedBoxes.firstWhere(
        (sb) => sb.width == 64.0 && sb.height == 64.0,
      );

      expect(mainSizedBox.width, 64.0);
      expect(mainSizedBox.height, 64.0);
    });

    testWidgets('respects custom iconSize parameter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(children: [CrosshairOverlay(iconSize: 42.0)]),
          ),
        ),
      );

      final icons = tester.widgetList<Icon>(find.byType(Icon));
      for (final icon in icons) {
        expect(icon.size, 42.0);
      }
    });

    testWidgets('is centered in parent', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Stack(children: [CrosshairOverlay()])),
        ),
      );

      // Should have Center widget somewhere in the tree
      expect(
        find.descendant(
          of: find.byType(CrosshairOverlay),
          matching: find.byType(Center),
        ),
        findsWidgets,
      );
    });

    testWidgets('does not intercept touch events (IgnorePointer)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Stack(children: [CrosshairOverlay()])),
        ),
      );

      // Should have IgnorePointer to let map handle touches
      expect(
        find.descendant(
          of: find.byType(CrosshairOverlay),
          matching: find.byType(IgnorePointer),
        ),
        findsOneWidget,
      );
    });

    testWidgets('has no semantic label (decorative only)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Stack(children: [CrosshairOverlay()])),
        ),
      );

      // Should not have Semantics wrapper with label
      final semantics = find.descendant(
        of: find.byType(CrosshairOverlay),
        matching: find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label != null,
        ),
      );
      expect(semantics, findsNothing);
    });
  });
}
