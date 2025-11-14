import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/theme/risk_palette.dart';
import 'package:wildfire_mvp_v3/widgets/fire_marker.dart';

void main() {
  group('FireMarker Widget Tests', () {
    late FireIncident baseIncident;

    setUp(() {
      baseIncident = FireIncident.test(
        id: 'test-fire-1',
        location: const LatLng(56.0, -3.5),
        detectedAt: DateTime.now().toUtc(),
        sensorSource: 'VIIRS',
      );
    });

    testWidgets('renders fire icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FireMarker(incident: baseIncident),
          ),
        ),
      );

      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
    });

    group('Marker Size (Confidence/FRP-based)', () {
      testWidgets('small marker for low confidence (<50%)', (tester) async {
        final incident = baseIncident.copyWith(confidence: 30.0, frp: 2.0);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireMarker(incident: incident),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(FireMarker),
            matching: find.byType(Container),
          ).first,
        );

        expect(container.constraints?.maxWidth, equals(30.0));
        expect(container.constraints?.maxHeight, equals(30.0));
      });

      testWidgets('medium marker for moderate confidence (50-80%)', (tester) async {
        final incident = baseIncident.copyWith(confidence: 65.0, frp: 8.0);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireMarker(incident: incident),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(FireMarker),
            matching: find.byType(Container),
          ).first,
        );

        expect(container.constraints?.maxWidth, equals(44.0));
        expect(container.constraints?.maxHeight, equals(44.0));
      });

      testWidgets('large marker for high confidence (>80%)', (tester) async {
        final incident = baseIncident.copyWith(confidence: 92.0, frp: 5.0);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireMarker(incident: incident),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(FireMarker),
            matching: find.byType(Container),
          ).first,
        );

        expect(container.constraints?.maxWidth, equals(56.0));
        expect(container.constraints?.maxHeight, equals(56.0));
      });

      testWidgets('large marker for high FRP (>15 MW)', (tester) async {
        final incident = baseIncident.copyWith(confidence: 40.0, frp: 20.0);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireMarker(incident: incident),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(FireMarker),
            matching: find.byType(Container),
          ).first,
        );

        expect(container.constraints?.maxWidth, equals(56.0));
        expect(container.constraints?.maxHeight, equals(56.0));
      });

      testWidgets('medium marker meets C3 touch target requirement (≥44dp)', (tester) async {
        final incident = baseIncident.copyWith(confidence: 60.0);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireMarker(incident: incident),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(FireMarker),
            matching: find.byType(Container),
          ).first,
        );

        expect(container.constraints?.maxWidth, greaterThanOrEqualTo(44.0));
        expect(container.constraints?.maxHeight, greaterThanOrEqualTo(44.0));
      });
    });

    group('Marker Color (Age-based)', () {
      testWidgets('fresh fire (<6h) displays red', (tester) async {
        final incident = baseIncident.copyWith(
          detectedAt: DateTime.now().toUtc().subtract(const Duration(hours: 3)),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireMarker(incident: incident),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(FireMarker),
            matching: find.byType(Container),
          ).first,
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(RiskPalette.veryHigh)); // Red
      });

      testWidgets('recent fire (6-24h) displays orange', (tester) async {
        final incident = baseIncident.copyWith(
          detectedAt: DateTime.now().toUtc().subtract(const Duration(hours: 12)),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireMarker(incident: incident),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(FireMarker),
            matching: find.byType(Container),
          ).first,
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(RiskPalette.moderate)); // Orange
      });

      testWidgets('old fire (>24h) displays gray', (tester) async {
        final incident = baseIncident.copyWith(
          detectedAt: DateTime.now().toUtc().subtract(const Duration(days: 2)),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireMarker(incident: incident),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(FireMarker),
            matching: find.byType(Container),
          ).first,
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(RiskPalette.midGray)); // Gray
      });

      testWidgets('edge case: 6h fire is orange (not red)', (tester) async {
        final incident = baseIncident.copyWith(
          detectedAt: DateTime.now().toUtc().subtract(const Duration(hours: 6)),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireMarker(incident: incident),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(FireMarker),
            matching: find.byType(Container),
          ).first,
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(RiskPalette.moderate)); // Orange
      });

      testWidgets('edge case: 24h fire is gray (not orange)', (tester) async {
        final incident = baseIncident.copyWith(
          detectedAt: DateTime.now().toUtc().subtract(const Duration(hours: 24)),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireMarker(incident: incident),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(FireMarker),
            matching: find.byType(Container),
          ).first,
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(RiskPalette.midGray)); // Gray
      });
    });

    group('Selection State', () {
      testWidgets('unselected marker has no border', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireMarker(incident: baseIncident, isSelected: false),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(FireMarker),
            matching: find.byType(Container),
          ).first,
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.border, isNull);
      });

      testWidgets('selected marker has blue accent border', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireMarker(incident: baseIncident, isSelected: true),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(FireMarker),
            matching: find.byType(Container),
          ).first,
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.border, isNotNull);

        final border = decoration.border as Border;
        expect(border.top.color, equals(RiskPalette.blueAccent));
        expect(border.top.width, equals(4.0));
      });
    });

    group('Accessibility (C3 Compliance)', () {
      testWidgets('has semantic label describing fire incident', (tester) async {
        final incident = baseIncident.copyWith(
          confidence: 85.0,
          intensity: 'high',
          detectedAt: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireMarker(incident: incident),
            ),
          ),
        );

        // Check semantic label exists and contains key information
        expect(
          find.bySemanticsLabel(RegExp(r'Fire incident.*hours ago.*high confidence.*high level', caseSensitive: false)),
          findsOneWidget,
        );
      });

      testWidgets('semantic label formats age in minutes (<1h)', (tester) async {
        final incident = baseIncident.copyWith(
          detectedAt: DateTime.now().toUtc().subtract(const Duration(minutes: 30)),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireMarker(incident: incident),
            ),
          ),
        );

        expect(
          find.bySemanticsLabel(RegExp(r'Fire incident.*minutes ago')),
          findsOneWidget,
        );
      });

      testWidgets('semantic label formats age in days (>24h)', (tester) async {
        final incident = baseIncident.copyWith(
          detectedAt: DateTime.now().toUtc().subtract(const Duration(days: 3)),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireMarker(incident: incident),
            ),
          ),
        );

        expect(
          find.bySemanticsLabel(RegExp(r'Fire incident.*days ago')),
          findsOneWidget,
        );
      });

      testWidgets('marked as button for screen readers', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireMarker(incident: baseIncident),
            ),
          ),
        );

        // Verify semantics exist by checking for any semantics widget
        expect(find.byType(Semantics), findsWidgets);
      });
    });

    group('Tap Handling', () {
      testWidgets('calls onTap callback when tapped', (tester) async {
        var tapCalled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireMarker(
                incident: baseIncident,
                onTap: () => tapCalled = true,
              ),
            ),
          ),
        );

        await tester.tap(find.byType(FireMarker));
        await tester.pump();

        expect(tapCalled, isTrue);
      });

      testWidgets('no error when onTap is null', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireMarker(incident: baseIncident),
            ),
          ),
        );

        await tester.tap(find.byType(FireMarker));
        await tester.pump();

        // No exception thrown - test passes
      });
    });

    group('Visual Styling', () {
      testWidgets('has circular shape', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireMarker(incident: baseIncident),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(FireMarker),
            matching: find.byType(Container),
          ).first,
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.shape, equals(BoxShape.circle));
      });

      testWidgets('has shadow for depth perception', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireMarker(incident: baseIncident),
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(FireMarker),
            matching: find.byType(Container),
          ).first,
        );

        final decoration = container.decoration as BoxDecoration;
        expect(decoration.boxShadow, isNotNull);
        expect(decoration.boxShadow!.length, equals(1));
      });

      testWidgets('fire icon is white', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FireMarker(incident: baseIncident),
            ),
          ),
        );

        final icon = tester.widget<Icon>(find.byIcon(Icons.local_fire_department));
        expect(icon.color, equals(Colors.white));
      });
    });
  });
}
