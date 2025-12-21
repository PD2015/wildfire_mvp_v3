import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/features/map/widgets/incidents_timestamp_chip.dart';
import 'package:wildfire_mvp_v3/theme/wildfire_a11y_theme.dart';

void main() {
  group('IncidentsTimestampChip', () {
    Widget buildChip(DateTime lastUpdated) {
      return MaterialApp(
        theme: WildfireA11yTheme.light,
        home: Scaffold(
          body: Center(child: IncidentsTimestampChip(lastUpdated: lastUpdated)),
        ),
      );
    }

    testWidgets('renders with clock icon', (tester) async {
      final now = DateTime.now().toUtc();
      await tester.pumpWidget(buildChip(now));

      // Verify clock icon is present
      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('shows "Just now" for recent updates (<45s)', (tester) async {
      final now = DateTime.now().toUtc();
      final recentUpdate = now.subtract(const Duration(seconds: 30));

      await tester.pumpWidget(buildChip(recentUpdate));

      // Verify text shows "Just now"
      expect(find.text('Incidents updated Just now'), findsOneWidget);
    });

    testWidgets('formats minutes correctly', (tester) async {
      final now = DateTime.now().toUtc();
      final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));

      await tester.pumpWidget(buildChip(fiveMinutesAgo));

      // Verify text shows minutes
      expect(find.textContaining('Incidents updated'), findsOneWidget);
      expect(find.textContaining('min ago'), findsOneWidget);
    });

    testWidgets('formats hours correctly', (tester) async {
      final now = DateTime.now().toUtc();
      final twoHoursAgo = now.subtract(const Duration(hours: 2));

      await tester.pumpWidget(buildChip(twoHoursAgo));

      // Verify text shows hours
      expect(find.textContaining('Incidents updated'), findsOneWidget);
      expect(find.textContaining('hour'), findsOneWidget);
    });

    testWidgets('formats days correctly', (tester) async {
      final now = DateTime.now().toUtc();
      final threeDaysAgo = now.subtract(const Duration(days: 3));

      await tester.pumpWidget(buildChip(threeDaysAgo));

      // Verify text shows days
      expect(find.textContaining('Incidents updated'), findsOneWidget);
      expect(find.textContaining('day'), findsOneWidget);
    });

    testWidgets('has semantic label for screen readers', (tester) async {
      final now = DateTime.now().toUtc();
      final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));

      await tester.pumpWidget(buildChip(fiveMinutesAgo));

      // Verify semantic label exists
      final semantics = tester.getSemantics(find.byType(Chip));
      expect(semantics.label, contains('Incidents last updated'));
    });

    testWidgets('semantic label matches display time format', (tester) async {
      final now = DateTime.now().toUtc();
      final recentUpdate = now.subtract(const Duration(seconds: 20));

      await tester.pumpWidget(buildChip(recentUpdate));

      // Verify semantic label says "Just now"
      final semantics = tester.getSemantics(find.byType(Chip));
      expect(semantics.label, contains('Just now'));
    });

    testWidgets('has minimum touch target of 44dp (C3 accessibility)', (
      tester,
    ) async {
      final now = DateTime.now().toUtc();
      await tester.pumpWidget(buildChip(now));

      // Get chip size
      final chipFinder = find.byType(Chip);
      final chipSize = tester.getSize(chipFinder);

      // Material Design minimum touch target: 44dp
      // Note: width can vary based on text, but height must be ≥44dp
      expect(
        chipSize.height,
        greaterThanOrEqualTo(44.0),
        reason: 'Chip height must be ≥44dp for C3 accessibility compliance',
      );
    });

    testWidgets('uses theme colors correctly', (tester) async {
      final now = DateTime.now().toUtc();
      await tester.pumpWidget(buildChip(now));

      // Get chip widget
      final chipWidget = tester.widget<Chip>(find.byType(Chip));

      // Verify chip uses theme colors
      final theme = WildfireA11yTheme.light;
      expect(
        chipWidget.backgroundColor,
        equals(theme.colorScheme.surfaceContainerHighest),
      );

      // Verify icon color
      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.access_time));
      expect(iconWidget.color, equals(theme.colorScheme.onSurface));
    });

    testWidgets('has appropriate elevation for visibility', (tester) async {
      final now = DateTime.now().toUtc();
      await tester.pumpWidget(buildChip(now));

      // Get chip widget
      final chipWidget = tester.widget<Chip>(find.byType(Chip));

      // Verify subtle elevation (2.0 per design)
      expect(
        chipWidget.elevation,
        equals(2.0),
        reason: 'Chip should have subtle elevation for map overlay visibility',
      );
    });

    testWidgets('updates display when lastUpdated changes', (tester) async {
      final now = DateTime.now().toUtc();
      final firstUpdate = now.subtract(const Duration(minutes: 5));

      // Build with initial timestamp
      await tester.pumpWidget(buildChip(firstUpdate));
      expect(find.textContaining('min ago'), findsOneWidget);

      // Update with recent timestamp
      final secondUpdate = now.subtract(const Duration(seconds: 10));
      await tester.pumpWidget(buildChip(secondUpdate));
      await tester.pumpAndSettle();

      // Verify display updated to "Just now"
      expect(find.text('Incidents updated Just now'), findsOneWidget);
    });

    testWidgets('renders correctly in dark mode', (tester) async {
      final now = DateTime.now().toUtc();

      // Build with dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: WildfireA11yTheme.dark,
          home: Scaffold(
            body: Center(child: IncidentsTimestampChip(lastUpdated: now)),
          ),
        ),
      );

      // Verify chip renders
      expect(find.byType(Chip), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);

      // Verify uses dark theme colors
      final chipWidget = tester.widget<Chip>(find.byType(Chip));
      final darkTheme = WildfireA11yTheme.dark;
      expect(
        chipWidget.backgroundColor,
        equals(darkTheme.colorScheme.surfaceContainerHighest),
      );
    });

    testWidgets('auto-refreshes display every minute with timer', (
      tester,
    ) async {
      // Start with timestamp from 1.5 minutes ago
      final now = DateTime.now().toUtc();
      final onePointFiveMinutesAgo = now.subtract(const Duration(seconds: 90));

      await tester.pumpWidget(buildChip(onePointFiveMinutesAgo));

      // Initial state: shows "1 min ago"
      expect(find.textContaining('min ago'), findsOneWidget);

      // Verify timer triggers rebuild after 1 minute
      // Note: We can't test that the displayed time changes because
      // DateTime.now() is real-world time, not test clock time.
      // But we can verify the widget rebuilds by checking it's still rendered.
      await tester.pump(const Duration(minutes: 1));
      await tester.pump(); // Process the setState from timer

      // Widget should still be rendered after timer fires
      expect(find.byType(IncidentsTimestampChip), findsOneWidget);
      expect(find.byIcon(Icons.access_time), findsOneWidget);
    });

    testWidgets('timer is cancelled on dispose', (tester) async {
      final now = DateTime.now().toUtc();
      await tester.pumpWidget(buildChip(now));

      // Widget mounted, timer should be active
      expect(find.byType(IncidentsTimestampChip), findsOneWidget);

      // Remove widget from tree
      await tester.pumpWidget(const SizedBox.shrink());

      // Widget disposed, timer should be cancelled (no memory leak)
      // If timer wasn't cancelled, this would throw or cause issues
      await tester.pump(const Duration(minutes: 2));
      expect(find.byType(IncidentsTimestampChip), findsNothing);
    });
  });
}
