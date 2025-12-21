import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wildfire_mvp_v3/widgets/location_mini_map_preview.dart';

void main() {
  group('LocationMiniMapPreview Widget Tests', () {
    const testStaticMapUrl =
        'https://maps.googleapis.com/maps/api/staticmap'
        '?center=55.95,-3.19&zoom=14&size=300x200&markers=color:red|55.95,-3.19&key=TEST_KEY';

    Widget buildTestWidget({
      String? staticMapUrl,
      bool isLoading = false,
      VoidCallback? onTap,
      double height = 140,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: LocationMiniMapPreview(
            staticMapUrl: staticMapUrl,
            isLoading: isLoading,
            onTap: onTap,
            height: height,
          ),
        ),
      );
    }

    group('Initial State', () {
      testWidgets('displays error state when staticMapUrl is null', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget(staticMapUrl: null));

        expect(find.text('Map preview unavailable'), findsOneWidget);
        expect(find.byIcon(Icons.map_outlined), findsOneWidget);
      });

      testWidgets('displays loading state when isLoading is true', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(staticMapUrl: testStaticMapUrl, isLoading: true),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Loading map...'), findsOneWidget);
      });

      testWidgets('has correct default height of 140px', (tester) async {
        await tester.pumpWidget(buildTestWidget(staticMapUrl: null));

        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        expect(container.constraints?.maxHeight, 140);
      });

      testWidgets('respects custom height parameter', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(staticMapUrl: null, height: 200),
        );

        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        expect(container.constraints?.maxHeight, 200);
      });
    });

    group('Tap Interaction', () {
      testWidgets('shows "Tap to change" overlay when onTap is provided', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(staticMapUrl: null, onTap: () {}),
        );

        expect(find.text('Tap to change'), findsOneWidget);
        expect(find.byIcon(Icons.touch_app), findsOneWidget);
      });

      testWidgets('hides "Tap to change" overlay when onTap is null', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(staticMapUrl: null, onTap: null),
        );

        expect(find.text('Tap to change'), findsNothing);
        expect(find.byIcon(Icons.touch_app), findsNothing);
      });

      testWidgets('calls onTap when preview is tapped', (tester) async {
        bool wasTapped = false;

        await tester.pumpWidget(
          buildTestWidget(staticMapUrl: null, onTap: () => wasTapped = true),
        );

        await tester.tap(find.byType(InkWell));
        await tester.pump();

        expect(wasTapped, isTrue);
      });

      testWidgets('InkWell has borderRadius matching container', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(staticMapUrl: null, onTap: () {}),
        );

        final inkWell = tester.widget<InkWell>(find.byType(InkWell));
        expect(inkWell.borderRadius, BorderRadius.circular(16));
      });
    });

    group('Accessibility', () {
      testWidgets('widget tree contains LocationMiniMapPreview', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(staticMapUrl: null, onTap: () {}),
        );

        // Verify the widget is in the tree and includes accessibility-relevant elements
        expect(find.byType(LocationMiniMapPreview), findsOneWidget);
        expect(find.byType(InkWell), findsOneWidget);
      });

      testWidgets('full surface is tappable (C3 compliance)', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(staticMapUrl: null, onTap: () {}),
        );

        // InkWell covers the full container
        final inkWellSize = tester.getSize(find.byType(InkWell));
        final containerSize = tester.getSize(find.byType(Container).first);

        expect(inkWellSize.width, containerSize.width);
        expect(inkWellSize.height, containerSize.height);
      });
    });

    group('Visual Design', () {
      testWidgets('has rounded corners (16dp radius)', (tester) async {
        await tester.pumpWidget(buildTestWidget(staticMapUrl: null));

        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        final decoration = container.decoration as BoxDecoration;

        expect(decoration.borderRadius, BorderRadius.circular(16));
      });

      testWidgets('has border outline', (tester) async {
        await tester.pumpWidget(buildTestWidget(staticMapUrl: null));

        final container = tester.widget<Container>(
          find.byType(Container).first,
        );
        final decoration = container.decoration as BoxDecoration;

        expect(decoration.border, isNotNull);
      });
    });
  });
}
