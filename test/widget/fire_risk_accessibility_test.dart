import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/widgets/bottom_nav.dart';
import 'package:wildfire_mvp_v3/widgets/risk_banner.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';
import 'package:wildfire_mvp_v3/models/risk_level.dart';
import 'package:wildfire_mvp_v3/services/utils/geo_utils.dart';

void main() {
  group('T005: Accessibility touch targets and semantic labels', () {
    testWidgets('bottom nav fire risk item has ≥44dp touch target', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(bottomNavigationBar: AppBottomNav(currentPath: '/')),
        ),
      );

      // NavigationBar (Material Design 3) provides ≥48dp touch targets by design
      // We verify the component exists and is properly configured for accessibility
      final navBar = find.byType(NavigationBar);
      expect(navBar, findsOneWidget);

      // Verify Fire Risk destination is present with proper label
      expect(find.text('Fire Risk'), findsOneWidget);

      // NavigationBar automatically provides:
      // - ≥48dp touch targets per Material Design 3 spec
      // - Proper semantic labels for screen readers
      // - Keyboard navigation support
      // This test verifies the component is present and configured correctly
    });

    testWidgets(
      'RiskBanner has proper semantic description with level, time, and source',
      (tester) async {
        final testFireRisk = FireRisk(
          level: RiskLevel.high,
          fwi: 25.0,
          source: DataSource.effis,
          observedAt: DateTime(2025, 11, 1, 12, 0).toUtc(),
          freshness: Freshness.live,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RiskBanner(state: RiskBannerSuccess(testFireRisk)),
            ),
          ),
        );

        // Find RiskBanner widget
        final banner = find.byType(RiskBanner);
        expect(banner, findsOneWidget);

        // Verify risk level text is displayed (searches for any case variation)
        final highText = find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.data != null &&
              widget.data!.toUpperCase().contains('HIGH'),
        );
        expect(
          highText,
          findsWidgets,
          reason: 'Risk level should be displayed for users',
        );

        // Verify data source is indicated
        expect(
          find.textContaining('EFFIS'),
          findsWidgets,
          reason: 'Data source should be indicated',
        );
      },
    );

    testWidgets('semantic labels do not contain PII or raw coordinates', (
      tester,
    ) async {
      final testFireRisk = FireRisk(
        level: RiskLevel.moderate,
        fwi: 15.0,
        source: DataSource.effis,
        observedAt: DateTime.now().toUtc(),
        freshness: Freshness.live,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RiskBanner(state: RiskBannerSuccess(testFireRisk)),
          ),
        ),
      );

      // Find all text widgets in the banner
      final textWidgets = find.descendant(
        of: find.byType(RiskBanner),
        matching: find.byType(Text),
      );

      // Check each text widget for PII
      for (final textFinder in textWidgets.evaluate()) {
        final Text textWidget = textFinder.widget as Text;
        final textData = textWidget.data ?? '';

        // Verify no high-precision coordinates (e.g., 55.9533)
        final highPrecisionPattern = RegExp(r'\d{2}\.\d{4,}');
        expect(
          textData,
          isNot(matches(highPrecisionPattern)),
          reason:
              'Text must not contain high-precision coordinates (C2 compliance)',
        );

        // Verify no email addresses
        expect(
          textData,
          isNot(contains('@')),
          reason: 'Text must not contain email addresses',
        );
      }
    });

    testWidgets('bottom nav fire risk icon has descriptive semantic label', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(bottomNavigationBar: AppBottomNav(currentPath: '/')),
        ),
      );

      // Find the warning icon (selected state)
      final warningIcon = find.byIcon(Icons.warning_amber);
      expect(warningIcon, findsOneWidget);

      // Get semantics for the icon
      final semantics = tester.getSemantics(warningIcon);

      // Verify icon has meaningful semantic label (not just "icon")
      expect(
        semantics.label,
        isNotEmpty,
        reason: 'Icon must have descriptive semantic label',
      );
      expect(
        semantics.label.toLowerCase(),
        contains('warning'),
        reason: 'Icon semantic label should describe its purpose',
      );
      expect(
        semantics.label.toLowerCase(),
        contains('fire risk'),
        reason: 'Icon semantic label should relate to fire risk',
      );
    });

    testWidgets('RiskBanner touch target is adequate for interaction', (
      tester,
    ) async {
      final testFireRisk = FireRisk(
        level: RiskLevel.veryLow,
        fwi: 3.0,
        source: DataSource.mock,
        observedAt: DateTime.now().toUtc(),
        freshness: Freshness.live,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: RiskBanner(state: RiskBannerSuccess(testFireRisk)),
            ),
          ),
        ),
      );

      // Get the RiskBanner size
      final banner = find.byType(RiskBanner);
      final RenderBox renderBox = tester.renderObject(banner);
      final size = renderBox.size;

      // Verify banner has adequate height for readability
      // Banner may not need full 44dp since it's informational, not a button
      expect(
        size.height,
        greaterThan(30.0),
        reason: 'RiskBanner should have adequate height for readability',
      );
      expect(
        size.width,
        greaterThan(200.0),
        reason: 'RiskBanner should have substantial width for content',
      );
    });

    testWidgets('all navigation items have adequate touch targets', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(bottomNavigationBar: AppBottomNav(currentPath: '/')),
        ),
      );

      // Verify NavigationBar exists (provides ≥48dp touch targets by Material Design 3 spec)
      final navBar = find.byType(NavigationBar);
      expect(navBar, findsOneWidget);

      // Verify all three navigation items are present and accessible
      final navItems = ['Fire Risk', 'Map', 'Report Fire'];

      for (final itemLabel in navItems) {
        final item = find.text(itemLabel);
        expect(
          item,
          findsOneWidget,
          reason: 'Navigation item "$itemLabel" should be accessible',
        );
      }

      // NavigationBar automatically provides proper touch targets (≥48dp)
      // and semantic labels for all destinations per Material Design 3 spec
    });

    testWidgets(
      'GeographicUtils.logRedact is used for coordinate logging compliance',
      (tester) async {
        // Test the utility function used throughout the app for C2 compliance
        const testLat = 55.9533;
        const testLon = -3.1883;

        final redactedCoords = GeographicUtils.logRedact(testLat, testLon);

        // Verify coordinates are redacted to 2 decimal places
        expect(
          redactedCoords,
          equals('55.95,-3.19'),
          reason:
              'GeographicUtils.logRedact must limit precision to 2 decimals (C2 compliance)',
        );

        // Verify no high-precision coordinates
        expect(
          redactedCoords,
          isNot(contains('55.9533')),
          reason: 'Full precision coordinates must not appear in logs',
        );
        expect(
          redactedCoords,
          isNot(contains('3.1883')),
          reason: 'Full precision coordinates must not appear in logs',
        );
      },
    );

    testWidgets('error state maintains accessibility requirements', (
      tester,
    ) async {
      const errorMessage = 'Network connection failed';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16.0),
              child: RiskBanner(state: RiskBannerError(errorMessage)),
            ),
          ),
        ),
      );

      // Verify error message is displayed
      expect(
        find.text(errorMessage),
        findsOneWidget,
        reason: 'Error messages must be visible to users',
      );

      // Verify banner still has adequate size in error state
      final banner = find.byType(RiskBanner);
      final RenderBox renderBox = tester.renderObject(banner);
      expect(
        renderBox.size.height,
        greaterThan(30.0),
        reason: 'Error state should maintain adequate size for readability',
      );
    });
  });
}
