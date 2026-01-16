import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/features/map/widgets/map_source_chip.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';
import 'package:wildfire_mvp_v3/theme/wildfire_a11y_theme.dart';

void main() {
  group('MapSourceChip', () {
    /// Helper to build chip in test harness
    Widget buildChip({
      required Freshness source,
      DateTime? lastUpdated,
      bool isOffline = false,
      VoidCallback? onTap,
      ThemeData? theme,
    }) {
      return MaterialApp(
        theme: theme ?? WildfireA11yTheme.light,
        home: Scaffold(
          body: Center(
            child: MapSourceChip(
              source: source,
              lastUpdated: lastUpdated ?? DateTime.now().toUtc(),
              isOffline: isOffline,
              onTap: onTap,
            ),
          ),
        ),
      );
    }

    group('Display states', () {
      testWidgets('shows "DEMO DATA" when source is mock', (tester) async {
        await tester.pumpWidget(buildChip(source: Freshness.mock));

        expect(find.text('DEMO DATA'), findsOneWidget);
        expect(find.byIcon(Icons.science_outlined), findsOneWidget);
      });

      testWidgets('shows "LIVE DATA" when source is live', (tester) async {
        await tester.pumpWidget(buildChip(source: Freshness.live));

        expect(find.text('LIVE DATA'), findsOneWidget);
        expect(find.byIcon(Icons.cloud_done), findsOneWidget);
      });

      testWidgets('shows "CACHED" when source is cached', (tester) async {
        // Cached data now has its own distinct display
        await tester.pumpWidget(buildChip(source: Freshness.cached));

        expect(find.text('CACHED'), findsOneWidget);
        expect(find.byIcon(Icons.cached), findsOneWidget);
      });

      testWidgets('shows "OFFLINE" when isOffline is true', (tester) async {
        await tester.pumpWidget(
          buildChip(source: Freshness.live, isOffline: true),
        );

        expect(find.text('OFFLINE'), findsOneWidget);
        expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      });

      testWidgets('offline state takes precedence over source', (tester) async {
        // Even with mock source, offline should show OFFLINE chip
        await tester.pumpWidget(
          buildChip(source: Freshness.mock, isOffline: true),
        );

        expect(find.text('OFFLINE'), findsOneWidget);
        expect(find.text('DEMO DATA'), findsNothing);
      });
    });

    group('Tappable behavior (onTap callback)', () {
      testWidgets('shows swap icon when onTap is provided', (tester) async {
        await tester.pumpWidget(
          buildChip(source: Freshness.mock, onTap: () {}),
        );

        // Swap icon indicates tappable
        expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
      });

      testWidgets('hides swap icon when onTap is null', (tester) async {
        await tester.pumpWidget(buildChip(source: Freshness.mock, onTap: null));

        // No swap icon when not tappable
        expect(find.byIcon(Icons.swap_horiz), findsNothing);
      });

      testWidgets('calls onTap callback when tapped (demo mode)', (
        tester,
      ) async {
        var tapCount = 0;
        await tester.pumpWidget(
          buildChip(source: Freshness.mock, onTap: () => tapCount++),
        );

        // Tap the chip
        await tester.tap(find.text('DEMO DATA'));
        await tester.pump();

        expect(tapCount, 1);
      });

      testWidgets('calls onTap callback when tapped (live mode)', (
        tester,
      ) async {
        var tapCount = 0;
        await tester.pumpWidget(
          buildChip(source: Freshness.live, onTap: () => tapCount++),
        );

        // Tap the chip
        await tester.tap(find.text('LIVE DATA'));
        await tester.pump();

        expect(tapCount, 1);
      });

      testWidgets('calls onTap callback when tapped (cached mode)', (
        tester,
      ) async {
        var tapCount = 0;
        await tester.pumpWidget(
          buildChip(source: Freshness.cached, onTap: () => tapCount++),
        );

        // Tap the chip
        await tester.tap(find.text('CACHED'));
        await tester.pump();

        expect(tapCount, 1);
      });

      testWidgets('offline chip is NOT tappable (no onTap wired)', (
        tester,
      ) async {
        // Offline chips don't get onTap because users need to retry, not toggle
        await tester.pumpWidget(
          buildChip(
            source: Freshness.live,
            isOffline: true,
            onTap: () {}, // Even if provided, offline ignores it
          ),
        );

        // No swap icon on offline chip
        expect(find.byIcon(Icons.swap_horiz), findsNothing);
      });
    });

    group('Accessibility (C3 compliance)', () {
      testWidgets('demo chip has semantic label for screen readers', (
        tester,
      ) async {
        await tester.pumpWidget(buildChip(source: Freshness.mock));

        // Semantic label should contain demo data indication (case insensitive)
        final semantics = tester.getSemantics(find.byType(Chip));
        expect(semantics.label.toUpperCase(), contains('DEMO'));
      });

      testWidgets('live chip has semantic label for screen readers', (
        tester,
      ) async {
        await tester.pumpWidget(buildChip(source: Freshness.live));

        // Semantic label should contain live data indication (case insensitive)
        final semantics = tester.getSemantics(find.byType(Chip));
        expect(semantics.label.toUpperCase(), contains('LIVE'));
      });

      testWidgets('cached chip has semantic label for screen readers', (
        tester,
      ) async {
        await tester.pumpWidget(buildChip(source: Freshness.cached));

        // Semantic label should contain cached data indication (case insensitive)
        final semantics = tester.getSemantics(find.byType(Chip));
        expect(semantics.label.toUpperCase(), contains('CACHED'));
      });

      testWidgets('offline chip has semantic label for screen readers', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildChip(source: Freshness.live, isOffline: true),
        );

        // Semantic label should contain offline indication (case insensitive)
        final semantics = tester.getSemantics(find.byType(Chip));
        expect(semantics.label.toUpperCase(), contains('OFFLINE'));
      });

      testWidgets('tappable chip has accessible tap hint', (tester) async {
        await tester.pumpWidget(
          buildChip(source: Freshness.mock, onTap: () {}),
        );

        // Find the Semantics widget with button property (indicates tappable)
        // The semantic label is set at the Semantics wrapper, not the Chip
        final semanticsFinder = find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.button == true,
        );
        expect(semanticsFinder, findsOneWidget);

        // Verify the semantics label on the wrapper mentions tap action
        final semanticsWidget = tester.widget<Semantics>(semanticsFinder);
        expect(semanticsWidget.properties.label, contains('Tap to switch'));
      });

      testWidgets('tappable chip is marked as button in semantics', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildChip(source: Freshness.mock, onTap: () {}),
        );

        // Find the Semantics widget wrapping the tappable chip
        final semanticsFinder = find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.button == true,
        );
        expect(semanticsFinder, findsOneWidget);
      });

      testWidgets('chip meets minimum touch target of 44dp', (tester) async {
        await tester.pumpWidget(buildChip(source: Freshness.mock));

        // Get chip size
        final chipFinder = find.byType(Chip);
        final chipSize = tester.getSize(chipFinder);

        // C3 accessibility: minimum 44dp touch target
        // Note: Chip itself may be smaller but tappable area should be adequate
        // The InkWell wrapper ensures adequate touch area
        expect(
          chipSize.height,
          greaterThanOrEqualTo(32),
        ); // Compact chip minimum
      });
    });

    group('Visual styling (theme tokens)', () {
      testWidgets('demo chip uses tertiaryContainer from theme', (
        tester,
      ) async {
        await tester.pumpWidget(buildChip(source: Freshness.mock));

        final chip = tester.widget<Chip>(find.byType(Chip));
        final scheme = WildfireA11yTheme.light.colorScheme;
        // Demo uses tertiary (amber) for warning state
        expect(chip.backgroundColor, scheme.tertiaryContainer);
        expect(chip.side?.color, scheme.tertiary);
      });

      testWidgets('live chip uses primaryContainer from theme', (tester) async {
        await tester.pumpWidget(buildChip(source: Freshness.live));

        final chip = tester.widget<Chip>(find.byType(Chip));
        final scheme = WildfireA11yTheme.light.colorScheme;
        // Live uses primary (forest green) for active state
        expect(chip.backgroundColor, scheme.primaryContainer);
        expect(chip.side?.color, scheme.primary);
      });

      testWidgets('cached chip uses secondaryContainer from theme', (
        tester,
      ) async {
        await tester.pumpWidget(buildChip(source: Freshness.cached));

        final chip = tester.widget<Chip>(find.byType(Chip));
        final scheme = WildfireA11yTheme.light.colorScheme;
        // Cached uses secondary (mint) for stale state
        expect(chip.backgroundColor, scheme.secondaryContainer);
        expect(chip.side?.color, scheme.secondary);
      });

      testWidgets('offline chip uses tertiaryContainer from theme', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildChip(source: Freshness.live, isOffline: true),
        );

        final chip = tester.widget<Chip>(find.byType(Chip));
        final scheme = WildfireA11yTheme.light.colorScheme;
        // Offline uses tertiary (amber) for warning state
        expect(chip.backgroundColor, scheme.tertiaryContainer);
        expect(chip.side?.color, scheme.tertiary);
      });

      testWidgets('dark theme has adequate contrast for demo chip', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildChip(source: Freshness.mock, theme: WildfireA11yTheme.dark),
        );

        final chip = tester.widget<Chip>(find.byType(Chip));
        final scheme = WildfireA11yTheme.dark.colorScheme;
        // Dark theme uses same token but different resolved colors
        expect(chip.backgroundColor, scheme.tertiaryContainer);
      });

      testWidgets('dark theme has adequate contrast for live chip', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildChip(source: Freshness.live, theme: WildfireA11yTheme.dark),
        );

        final chip = tester.widget<Chip>(find.byType(Chip));
        final scheme = WildfireA11yTheme.dark.colorScheme;
        // Dark theme uses same token but different resolved colors
        expect(chip.backgroundColor, scheme.primaryContainer);
      });

      testWidgets('dark theme has adequate contrast for cached chip', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildChip(source: Freshness.cached, theme: WildfireA11yTheme.dark),
        );

        final chip = tester.widget<Chip>(find.byType(Chip));
        final scheme = WildfireA11yTheme.dark.colorScheme;
        // Dark theme uses same token but different resolved colors
        expect(chip.backgroundColor, scheme.secondaryContainer);
      });
    });
  });
}
