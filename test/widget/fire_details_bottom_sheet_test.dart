import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';
import 'package:wildfire_mvp_v3/theme/risk_palette.dart';
import 'package:wildfire_mvp_v3/widgets/fire_details_bottom_sheet.dart';

void main() {
  group('FireDetailsBottomSheet Widget Tests', () {
    late FireIncident testIncident;
    const testUserLocation = LatLng(55.9533, -3.1883); // Edinburgh

    setUp(() {
      testIncident = FireIncident.test(
        id: 'test-fire-1',
        location: const LatLng(56.0, -3.5),
        source: DataSource.effis,
        freshness: Freshness.live,
        detectedAt: DateTime(2024, 11, 14, 10, 30).toUtc(),
        sensorSource: 'VIIRS',
        confidence: 85.5,
        frp: 12.3,
        intensity: 'high',
        areaHectares: 5.2,
        description: 'Active wildfire detected in forest area',
      );
    });

    testWidgets('displays fire incident header', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FireDetailsBottomSheet(incident: testIncident),
          ),
        ),
      );

      expect(find.text('Fire Incident Details'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department), findsWidgets);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('close button has minimum touch target (C3 compliance)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FireDetailsBottomSheet(incident: testIncident),
          ),
        ),
      );

      final closeButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.close),
          matching: find.byType(IconButton),
        ),
      );
      expect(closeButton.constraints?.minWidth, greaterThanOrEqualTo(44));
      expect(closeButton.constraints?.minHeight, greaterThanOrEqualTo(44));
    });

    testWidgets('displays data source chip', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FireDetailsBottomSheet(incident: testIncident),
          ),
        ),
      );

      expect(find.text('LIVE'), findsOneWidget);
    });

    testWidgets('displays demo chip for mock data', (tester) async {
      final mockIncident = testIncident.copyWith(
        source: DataSource.mock,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FireDetailsBottomSheet(incident: mockIncident),
          ),
        ),
      );

      expect(find.text('DEMO DATA'), findsOneWidget);
    });

    testWidgets('displays distance card when user location provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FireDetailsBottomSheet(
              incident: testIncident,
              userLocation: testUserLocation,
            ),
          ),
        ),
      );

      expect(find.text('Distance from your location'), findsOneWidget);
      expect(find.byIcon(Icons.navigation), findsOneWidget);
    });

    testWidgets('hides distance card when user location not provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FireDetailsBottomSheet(incident: testIncident),
          ),
        ),
      );

      expect(find.text('Distance from your location'), findsNothing);
      expect(find.byIcon(Icons.navigation), findsNothing);
    });

    testWidgets('displays all detection details', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FireDetailsBottomSheet(incident: testIncident),
          ),
        ),
      );

      expect(find.text('Detection Details'), findsOneWidget);
      expect(find.text('Detected'), findsOneWidget);
      expect(find.text('Sensor'), findsOneWidget);
      expect(find.text('VIIRS'), findsOneWidget);
    });

    testWidgets('displays fire intensity metrics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FireDetailsBottomSheet(incident: testIncident),
          ),
        ),
      );

      expect(find.text('Fire Intensity'), findsOneWidget);
      expect(find.text('Confidence'), findsOneWidget);
      expect(find.text('85.5%'), findsOneWidget);
      expect(find.text('Fire Radiative Power'), findsOneWidget);
      expect(find.text('12.3 MW'), findsOneWidget);
      expect(find.text('Intensity Level'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
    });

    testWidgets('displays area when available', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FireDetailsBottomSheet(incident: testIncident),
          ),
        ),
      );

      expect(find.text('Estimated Area'), findsOneWidget);
      expect(find.text('5.2 ha'), findsOneWidget);
    });

    testWidgets('displays location coordinates', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FireDetailsBottomSheet(incident: testIncident),
          ),
        ),
      );

      expect(find.text('Location'), findsOneWidget);
      expect(find.text('Coordinates'), findsOneWidget);
      expect(find.textContaining('56.0000'), findsOneWidget);
      expect(find.textContaining('-3.5000'), findsOneWidget);
    });

    testWidgets('displays description when available', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FireDetailsBottomSheet(incident: testIncident),
          ),
        ),
      );

      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Active wildfire detected in forest area'), findsOneWidget);
    });

    testWidgets('hides optional fields when not available', (tester) async {
      final minimalIncident = FireIncident.test(
        id: 'minimal-1',
        location: const LatLng(56.0, -3.5),
        detectedAt: DateTime.now().toUtc(),
        sensorSource: 'MODIS',
        // No confidence, frp, area, or description
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FireDetailsBottomSheet(incident: minimalIncident),
          ),
        ),
      );

      expect(find.text('Confidence'), findsNothing);
      expect(find.text('Fire Radiative Power'), findsNothing);
      expect(find.text('Estimated Area'), findsNothing);
      expect(find.text('Description'), findsNothing);
    });

    testWidgets('sheet is draggable and scrollable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FireDetailsBottomSheet(incident: testIncident),
          ),
        ),
      );

      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('has drag handle indicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FireDetailsBottomSheet(incident: testIncident),
          ),
        ),
      );

      // Find the drag handle container
      final dragHandle = tester.widgetList<Container>(find.byType(Container)).firstWhere(
        (container) {
          final decoration = container.decoration as BoxDecoration?;
          return decoration != null && 
                 decoration.color == RiskPalette.midGray &&
                 container.constraints?.maxWidth == 40;
        },
      );
      
      expect(dragHandle, isNotNull);
    });

    testWidgets('close button calls onClose callback', (tester) async {
      var closeCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FireDetailsBottomSheet(
              incident: testIncident,
              onClose: () => closeCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(closeCalled, isTrue);
    });

    testWidgets('has proper semantic labels for screen readers (C3 compliance)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FireDetailsBottomSheet(
              incident: testIncident,
              userLocation: testUserLocation,
            ),
          ),
        ),
      );

      // Check for semantic labels
      final semanticsLabels = tester.widgetList<Semantics>(find.byType(Semantics))
          .where((s) => s.properties.label != null && s.properties.label!.isNotEmpty)
          .map((s) => s.properties.label)
          .toList();

      expect(semanticsLabels, isNotEmpty, reason: 'Should have semantic labels for accessibility');
      
      // Verify specific important labels
      expect(semanticsLabels.any((label) => label!.contains('Fire incident')), isTrue);
      expect(semanticsLabels.any((label) => label!.contains('Close')), isTrue);
      expect(semanticsLabels.any((label) => label!.contains('from your location')), isTrue);
    });

    testWidgets('formats date and time correctly', (tester) async {
      final incident = FireIncident.test(
        id: 'date-test',
        location: const LatLng(56.0, -3.5),
        detectedAt: DateTime(2024, 3, 15, 14, 30).toUtc(),
        sensorSource: 'TEST',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FireDetailsBottomSheet(incident: incident),
          ),
        ),
      );

      // Should show formatted date (Mar 15, 2024)
      expect(find.textContaining('Mar'), findsAtLeastNWidgets(1));
      expect(find.textContaining('15'), findsAtLeastNWidgets(1));
      expect(find.textContaining('2024'), findsAtLeastNWidgets(1));
    });

    testWidgets('sheet has rounded top corners', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FireDetailsBottomSheet(incident: testIncident),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(DraggableScrollableSheet),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      final borderRadius = decoration.borderRadius as BorderRadius;
      
      expect(borderRadius.topLeft.x, equals(20));
      expect(borderRadius.topRight.x, equals(20));
    });
  });
}
