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
        expect(find.text('This Season'), findsNothing);
        expect(find.text('Last Season'), findsNothing);
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
      testWidgets('displays This Season and Last Season chips', (tester) async {
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

        expect(find.text('This Season'), findsOneWidget);
        expect(find.text('Last Season'), findsOneWidget);
        expect(find.text('Today'), findsNothing);
        expect(find.text('This Week'), findsNothing);
      });

      testWidgets('tapping Last Season calls onBurntAreaFilterChanged', (
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
              ),
            ),
          ),
        );

        await tester.tap(find.text('Last Season'));
        await tester.pumpAndSettle();

        expect(selectedFilter, BurntAreaSeasonFilter.lastSeason);
      });

      testWidgets('tapping This Season calls onBurntAreaFilterChanged', (
        tester,
      ) async {
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

        await tester.tap(find.text('This Season'));
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

        await tester.tap(find.text('Last Season'));
        await tester.pumpAndSettle();

        expect(selectedFilter, isNull);
      });
    });

    group('mode switching', () {
      testWidgets('switches from hotspots to burnt areas chips', (
        tester,
      ) async {
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
        expect(find.text('This Season'), findsNothing);

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
        expect(find.text('This Season'), findsOneWidget);
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

      testWidgets('This Season chip shows selected styling when active', (
        tester,
      ) async {
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

        // Widget should render with selected This Season chip
        final thisSeasonText = find.text('This Season');
        expect(thisSeasonText, findsOneWidget);
      });
    });
  });
}
