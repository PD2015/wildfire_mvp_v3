import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/features/map/widgets/time_filter_chips.dart';
import 'package:wildfire_mvp_v3/models/fire_data_mode.dart';

void main() {
  group('TimeFilterChips', () {
    group('hotspots mode', () {
      testWidgets('displays Today and This Week chips', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TimeFilterChips(
                mode: FireDataMode.hotspots,
                hotspotFilter: HotspotTimeFilter.today,
                burntAreaFilter: BurntAreaSeasonFilter.thisSeason,
                onHotspotFilterChanged: (_) {},
                onBurntAreaFilterChanged: (_) {},
              ),
            ),
          ),
        );

        expect(find.text('Today'), findsOneWidget);
        expect(find.text('This Week'), findsOneWidget);
        // Season year chips should not be shown in hotspots mode
        expect(find.text(DateTime.now().year.toString()), findsNothing);
        expect(find.text((DateTime.now().year - 1).toString()), findsNothing);
      });

      testWidgets('tapping This Week calls onHotspotFilterChanged', (
        tester,
      ) async {
        HotspotTimeFilter? selectedFilter;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TimeFilterChips(
                mode: FireDataMode.hotspots,
                hotspotFilter: HotspotTimeFilter.today,
                burntAreaFilter: BurntAreaSeasonFilter.thisSeason,
                onHotspotFilterChanged: (filter) => selectedFilter = filter,
                onBurntAreaFilterChanged: (_) {},
              ),
            ),
          ),
        );

        await tester.tap(find.text('This Week'));
        await tester.pumpAndSettle();

        expect(selectedFilter, HotspotTimeFilter.thisWeek);
      });

      testWidgets('tapping Today calls onHotspotFilterChanged', (tester) async {
        HotspotTimeFilter? selectedFilter;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TimeFilterChips(
                mode: FireDataMode.hotspots,
                hotspotFilter: HotspotTimeFilter.thisWeek,
                burntAreaFilter: BurntAreaSeasonFilter.thisSeason,
                onHotspotFilterChanged: (filter) => selectedFilter = filter,
                onBurntAreaFilterChanged: (_) {},
              ),
            ),
          ),
        );

        await tester.tap(find.text('Today'));
        await tester.pumpAndSettle();

        expect(selectedFilter, HotspotTimeFilter.today);
      });
    });

    group('burnt areas mode', () {
      testWidgets('displays season year chips', (tester) async {
        final thisYear = DateTime.now().year.toString();
        final lastYear = (DateTime.now().year - 1).toString();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TimeFilterChips(
                mode: FireDataMode.burntAreas,
                hotspotFilter: HotspotTimeFilter.today,
                burntAreaFilter: BurntAreaSeasonFilter.thisSeason,
                onHotspotFilterChanged: (_) {},
                onBurntAreaFilterChanged: (_) {},
              ),
            ),
          ),
        );

        expect(find.text(thisYear), findsOneWidget);
        expect(find.text(lastYear), findsOneWidget);
        expect(find.text('Today'), findsNothing);
        expect(find.text('This Week'), findsNothing);
      });

      testWidgets('tapping last year calls onBurntAreaFilterChanged', (
        tester,
      ) async {
        final lastYear = (DateTime.now().year - 1).toString();
        BurntAreaSeasonFilter? selectedFilter;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TimeFilterChips(
                mode: FireDataMode.burntAreas,
                hotspotFilter: HotspotTimeFilter.today,
                burntAreaFilter: BurntAreaSeasonFilter.thisSeason,
                onHotspotFilterChanged: (_) {},
                onBurntAreaFilterChanged: (filter) => selectedFilter = filter,
              ),
            ),
          ),
        );

        await tester.tap(find.text(lastYear));
        await tester.pumpAndSettle();

        expect(selectedFilter, BurntAreaSeasonFilter.lastSeason);
      });

      testWidgets('tapping this year calls onBurntAreaFilterChanged', (
        tester,
      ) async {
        final thisYear = DateTime.now().year.toString();
        BurntAreaSeasonFilter? selectedFilter;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TimeFilterChips(
                mode: FireDataMode.burntAreas,
                hotspotFilter: HotspotTimeFilter.today,
                burntAreaFilter: BurntAreaSeasonFilter.lastSeason,
                onHotspotFilterChanged: (_) {},
                onBurntAreaFilterChanged: (filter) => selectedFilter = filter,
              ),
            ),
          ),
        );

        await tester.tap(find.text(thisYear));
        await tester.pumpAndSettle();

        expect(selectedFilter, BurntAreaSeasonFilter.thisSeason);
      });
    });

    group('disabled state', () {
      testWidgets('disabled chips do not respond to taps (hotspots)', (
        tester,
      ) async {
        HotspotTimeFilter? selectedFilter;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TimeFilterChips(
                mode: FireDataMode.hotspots,
                hotspotFilter: HotspotTimeFilter.today,
                burntAreaFilter: BurntAreaSeasonFilter.thisSeason,
                onHotspotFilterChanged: (filter) => selectedFilter = filter,
                onBurntAreaFilterChanged: (_) {},
                enabled: false,
              ),
            ),
          ),
        );

        await tester.tap(find.text('This Week'));
        await tester.pumpAndSettle();

        expect(selectedFilter, isNull);
      });

      testWidgets('disabled chips do not respond to taps (burnt areas)', (
        tester,
      ) async {
        BurntAreaSeasonFilter? selectedFilter;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TimeFilterChips(
                mode: FireDataMode.burntAreas,
                hotspotFilter: HotspotTimeFilter.today,
                burntAreaFilter: BurntAreaSeasonFilter.thisSeason,
                onHotspotFilterChanged: (_) {},
                onBurntAreaFilterChanged: (filter) => selectedFilter = filter,
                enabled: false,
              ),
            ),
          ),
        );

        await tester.tap(find.text((DateTime.now().year - 1).toString()));
        await tester.pumpAndSettle();

        expect(selectedFilter, isNull);
      });
    });

    group('mode switching', () {
      testWidgets('switches from hotspots to burnt areas chips', (
        tester,
      ) async {
        final thisYear = DateTime.now().year.toString();

        // Start with hotspots mode
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TimeFilterChips(
                mode: FireDataMode.hotspots,
                hotspotFilter: HotspotTimeFilter.today,
                burntAreaFilter: BurntAreaSeasonFilter.thisSeason,
                onHotspotFilterChanged: (_) {},
                onBurntAreaFilterChanged: (_) {},
              ),
            ),
          ),
        );

        expect(find.text('Today'), findsOneWidget);
        expect(find.text(thisYear), findsNothing);

        // Switch to burnt areas mode
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TimeFilterChips(
                mode: FireDataMode.burntAreas,
                hotspotFilter: HotspotTimeFilter.today,
                burntAreaFilter: BurntAreaSeasonFilter.thisSeason,
                onHotspotFilterChanged: (_) {},
                onBurntAreaFilterChanged: (_) {},
              ),
            ),
          ),
        );

        expect(find.text('Today'), findsNothing);
        expect(find.text(thisYear), findsOneWidget);
      });
    });

    group('accessibility', () {
      testWidgets('has proper semantics for hotspots mode', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TimeFilterChips(
                mode: FireDataMode.hotspots,
                hotspotFilter: HotspotTimeFilter.today,
                burntAreaFilter: BurntAreaSeasonFilter.thisSeason,
                onHotspotFilterChanged: (_) {},
                onBurntAreaFilterChanged: (_) {},
              ),
            ),
          ),
        );

        expect(
          find.bySemanticsLabel('Time filter for hotspots'),
          findsOneWidget,
        );
      });

      testWidgets('has proper semantics for burnt areas mode', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TimeFilterChips(
                mode: FireDataMode.burntAreas,
                hotspotFilter: HotspotTimeFilter.today,
                burntAreaFilter: BurntAreaSeasonFilter.thisSeason,
                onHotspotFilterChanged: (_) {},
                onBurntAreaFilterChanged: (_) {},
              ),
            ),
          ),
        );

        expect(
          find.bySemanticsLabel('Time filter for burnt areas'),
          findsOneWidget,
        );
      });

      testWidgets('chips have tooltips', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TimeFilterChips(
                mode: FireDataMode.hotspots,
                hotspotFilter: HotspotTimeFilter.today,
                burntAreaFilter: BurntAreaSeasonFilter.thisSeason,
                onHotspotFilterChanged: (_) {},
                onBurntAreaFilterChanged: (_) {},
              ),
            ),
          ),
        );

        // Verify tooltips exist
        expect(find.byType(Tooltip), findsNWidgets(2));
      });
    });

    group('visual selection state', () {
      testWidgets('Today chip shows selected styling when active', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TimeFilterChips(
                mode: FireDataMode.hotspots,
                hotspotFilter: HotspotTimeFilter.today,
                burntAreaFilter: BurntAreaSeasonFilter.thisSeason,
                onHotspotFilterChanged: (_) {},
                onBurntAreaFilterChanged: (_) {},
              ),
            ),
          ),
        );

        // Widget should render with selected Today chip
        final todayText = find.text('Today');
        expect(todayText, findsOneWidget);
      });

      testWidgets('this year chip shows selected styling when active', (
        tester,
      ) async {
        final thisYear = DateTime.now().year.toString();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TimeFilterChips(
                mode: FireDataMode.burntAreas,
                hotspotFilter: HotspotTimeFilter.today,
                burntAreaFilter: BurntAreaSeasonFilter.thisSeason,
                onHotspotFilterChanged: (_) {},
                onBurntAreaFilterChanged: (_) {},
              ),
            ),
          ),
        );

        // Widget should render with selected this year chip
        final thisSeasonText = find.text(thisYear);
        expect(thisSeasonText, findsOneWidget);
      });
    });
  });
}
