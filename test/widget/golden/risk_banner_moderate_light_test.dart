import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/widgets/risk_banner.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';
import 'package:wildfire_mvp_v3/models/risk_level.dart';

void main() {
  group('RiskBanner Golden Test - Moderate Light', () {
    testWidgets(
        'should match golden image for Moderate risk level in light theme',
        (WidgetTester tester) async {
      // Fixed test data for reproducibility
      final testFireRisk = FireRisk(
        level: RiskLevel.moderate,
        fwi: 15.7,
        source: DataSource.effis,
        observedAt: DateTime.parse('2025-11-02T14:30:00Z'),
        freshness: Freshness.live,
      );

      // Build widget in light theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 350,
                child: RiskBanner(
                  state: RiskBannerSuccess(testFireRisk),
                  locationLabel: 'Aberdeen (57.15, -2.11)',
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Golden test assertion
      await expectLater(
        find.byType(RiskBanner),
        matchesGoldenFile('goldens/risk_banner_moderate_light.png'),
      );
    });
  });
}
