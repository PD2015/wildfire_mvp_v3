import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/theme/risk_palette.dart';
import 'package:wildfire_mvp_v3/widgets/chips/time_filter_chip.dart';

void main() {
  group('TimeFilterChip Widget Tests', () {
    testWidgets('renders all time range options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeFilterChip(
              selectedRange: TimeRange.last24Hours,
              onRangeChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Last 6h'), findsOneWidget);
      expect(find.text('Last 12h'), findsOneWidget);
      expect(find.text('Last 24h'), findsOneWidget);
      expect(find.text('Last 48h'), findsOneWidget);
    });

    testWidgets('shows selected range with visual indication', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeFilterChip(
              selectedRange: TimeRange.last12Hours,
              onRangeChanged: (_) {},
            ),
          ),
        ),
      );

      // Find the selected chip
      final selectedChip = tester.widget<FilterChip>(
        find.byKey(const Key('time_filter_last12Hours')),
      );

      expect(selectedChip.selected, isTrue);
    });

    testWidgets('calls onRangeChanged when chip tapped', (tester) async {
      TimeRange? changedRange;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeFilterChip(
              selectedRange: TimeRange.last24Hours,
              onRangeChanged: (range) => changedRange = range,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Last 6h'));
      await tester.pump();

      expect(changedRange, equals(TimeRange.last6Hours));
    });

    testWidgets('updates selection when different chip tapped', (tester) async {
      TimeRange selectedRange = TimeRange.last24Hours;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return TimeFilterChip(
                  selectedRange: selectedRange,
                  onRangeChanged: (range) {
                    setState(() {
                      selectedRange = range;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      // Initially 24h is selected
      var selectedChip = tester.widget<FilterChip>(
        find.byKey(const Key('time_filter_last24Hours')),
      );
      expect(selectedChip.selected, isTrue);

      // Tap 12h chip
      await tester.tap(find.text('Last 12h'));
      await tester.pumpAndSettle();

      // Now 12h should be selected
      selectedChip = tester.widget<FilterChip>(
        find.byKey(const Key('time_filter_last12Hours')),
      );
      expect(selectedChip.selected, isTrue);

      // 24h should no longer be selected
      final previousChip = tester.widget<FilterChip>(
        find.byKey(const Key('time_filter_last24Hours')),
      );
      expect(previousChip.selected, isFalse);
    });

    testWidgets('selected chip has blue accent color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeFilterChip(
              selectedRange: TimeRange.last6Hours,
              onRangeChanged: (_) {},
            ),
          ),
        ),
      );

      final selectedChip = tester.widget<FilterChip>(
        find.byKey(const Key('time_filter_last6Hours')),
      );

      expect(
        selectedChip.selectedColor,
        equals(RiskPalette.blueAccent.withValues(alpha: 0.2)),
      );
      expect(selectedChip.checkmarkColor, equals(RiskPalette.blueAccent));
    });

    testWidgets('unselected chip has gray background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeFilterChip(
              selectedRange: TimeRange.last24Hours,
              onRangeChanged: (_) {},
            ),
          ),
        ),
      );

      final unselectedChip = tester.widget<FilterChip>(
        find.byKey(const Key('time_filter_last6Hours')),
      );

      expect(
        unselectedChip.backgroundColor,
        equals(RiskPalette.lightGray.withValues(alpha: 0.3)),
      );
    });

    testWidgets('has rounded corners with border', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeFilterChip(
              selectedRange: TimeRange.last24Hours,
              onRangeChanged: (_) {},
            ),
          ),
        ),
      );

      final chip = tester.widget<FilterChip>(
        find.byKey(const Key('time_filter_last24Hours')),
      );

      final shape = chip.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, equals(BorderRadius.circular(20)));
      expect(shape.side.width, equals(2.0));
      expect(shape.side.color, equals(RiskPalette.blueAccent));
    });

    testWidgets('chips are scrollable horizontally', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200, // Narrow width to force scrolling
              child: TimeFilterChip(
                selectedRange: TimeRange.last24Hours,
                onRangeChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      final scrollView = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(scrollView.scrollDirection, equals(Axis.horizontal));
    });

    group('Accessibility (C3 Compliance)', () {
      testWidgets('has semantic label describing current filter', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TimeFilterChip(
                selectedRange: TimeRange.last24Hours,
                onRangeChanged: (_) {},
              ),
            ),
          ),
        );

        expect(
          find.bySemanticsLabel('Time filter: Last 24h'),
          findsOneWidget,
        );
      });

      testWidgets('each chip has semantic label', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TimeFilterChip(
                selectedRange: TimeRange.last24Hours,
                onRangeChanged: (_) {},
              ),
            ),
          ),
        );

        expect(find.bySemanticsLabel('Filter by Last 6h'), findsOneWidget);
        expect(find.bySemanticsLabel('Filter by Last 12h'), findsOneWidget);
        expect(find.bySemanticsLabel('Filter by Last 24h'), findsOneWidget);
        expect(find.bySemanticsLabel('Filter by Last 48h'), findsOneWidget);
      });

      testWidgets('chips have minimum touch target size', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TimeFilterChip(
                selectedRange: TimeRange.last24Hours,
                onRangeChanged: (_) {},
              ),
            ),
          ),
        );

        final chip = tester.widget<FilterChip>(
          find.byKey(const Key('time_filter_last24Hours')),
        );

        expect(chip.materialTapTargetSize, equals(MaterialTapTargetSize.padded));
        expect(chip.visualDensity, equals(VisualDensity.comfortable));
      });
    });
  });

  group('TimeRange Enum Tests', () {
    test('has correct duration values', () {
      expect(TimeRange.last6Hours.duration, equals(const Duration(hours: 6)));
      expect(TimeRange.last12Hours.duration, equals(const Duration(hours: 12)));
      expect(TimeRange.last24Hours.duration, equals(const Duration(hours: 24)));
      expect(TimeRange.last48Hours.duration, equals(const Duration(hours: 48)));
    });

    test('has correct label values', () {
      expect(TimeRange.last6Hours.label, equals('Last 6h'));
      expect(TimeRange.last12Hours.label, equals('Last 12h'));
      expect(TimeRange.last24Hours.label, equals('Last 24h'));
      expect(TimeRange.last48Hours.label, equals('Last 48h'));
    });

    test('cutoffTime returns correct timestamp', () {
      final now = DateTime.now().toUtc();
      final cutoff = TimeRange.last24Hours.cutoffTime;
      final expectedCutoff = now.subtract(const Duration(hours: 24));

      // Allow 1 second tolerance for test execution time
      expect(
        cutoff.difference(expectedCutoff).abs().inSeconds,
        lessThan(1),
      );
    });

    test('includes returns true for recent timestamps', () {
      final now = DateTime.now().toUtc();
      final recentTime = now.subtract(const Duration(hours: 12));

      expect(TimeRange.last24Hours.includes(recentTime), isTrue);
      expect(TimeRange.last6Hours.includes(recentTime), isFalse);
    });

    test('includes returns false for old timestamps', () {
      final oldTime = DateTime.now().toUtc().subtract(const Duration(days: 3));

      expect(TimeRange.last24Hours.includes(oldTime), isFalse);
      expect(TimeRange.last48Hours.includes(oldTime), isFalse);
    });

    test('includes handles edge cases correctly', () {
      final now = DateTime.now().toUtc();
      
      // Exactly at cutoff boundary (should be excluded)
      final exactCutoff = TimeRange.last24Hours.cutoffTime;
      expect(TimeRange.last24Hours.includes(exactCutoff), isFalse);
      
      // Just after cutoff (should be included)
      final justAfter = exactCutoff.add(const Duration(seconds: 1));
      expect(TimeRange.last24Hours.includes(justAfter), isTrue);
      
      // Current time (should be included)
      expect(TimeRange.last24Hours.includes(now), isTrue);
    });
  });
}
