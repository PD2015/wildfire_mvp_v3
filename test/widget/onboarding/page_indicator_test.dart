import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wildfire_mvp_v3/features/onboarding/widgets/page_indicator.dart';

void main() {
  group('PageIndicator', () {
    testWidgets('renders correct number of dots', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PageIndicator(currentPage: 0, totalPages: 4)),
        ),
      );

      // Should have 4 animated containers (dots)
      final containers = find.byType(AnimatedContainer);
      expect(containers, findsNWidgets(4));
    });

    testWidgets('highlights current page dot', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PageIndicator(currentPage: 2, totalPages: 4)),
        ),
      );

      final dots = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .toList();

      // Active dot (index 2) should be wider
      final activeDot = dots[2];
      final inactiveDot = dots[0];

      // Check via constraints - active should be 24 wide
      final activeCon = activeDot.constraints;
      final inactiveCon = inactiveDot.constraints;

      expect(activeCon?.maxWidth, 24);
      expect(inactiveCon?.maxWidth, 8);
    });

    testWidgets('has accessibility label with page title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PageIndicator(currentPage: 1, totalPages: 4)),
        ),
      );

      // Check semantics are present by looking for Row containing dots
      expect(find.byType(PageIndicator), findsOneWidget);

      // Find semantics node with descriptive label (uses defaultOnboardingTitles)
      final semanticsFinder = find.bySemanticsLabel(
        'Step 2 of 4: Safety information',
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('updates accessibility label when currentPage changes', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PageIndicator(currentPage: 0, totalPages: 4)),
        ),
      );

      // Verify first page label (Welcome)
      expect(find.bySemanticsLabel('Step 1 of 4: Welcome'), findsOneWidget);

      // Change to page 3 (Privacy)
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PageIndicator(currentPage: 2, totalPages: 4)),
        ),
      );

      await tester.pumpAndSettle();

      // Verify third page label (Privacy)
      expect(find.bySemanticsLabel('Step 3 of 4: Privacy'), findsOneWidget);
    });

    testWidgets('works with single page', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PageIndicator(currentPage: 0, totalPages: 1)),
        ),
      );

      expect(find.byType(AnimatedContainer), findsOneWidget);
    });

    testWidgets('uses custom page titles when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PageIndicator(
              currentPage: 1,
              totalPages: 3,
              pageTitles: ['First', 'Second', 'Third'],
            ),
          ),
        ),
      );

      // Find semantics node with custom label
      final semanticsFinder = find.bySemanticsLabel('Step 2 of 3: Second');
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('falls back gracefully when page index exceeds titles', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PageIndicator(
              currentPage: 5,
              totalPages: 6,
              pageTitles: ['Only', 'Two'], // Only 2 titles for 6 pages
            ),
          ),
        ),
      );

      // Should fall back to simple format without title
      final semanticsFinder = find.bySemanticsLabel('Step 6 of 6');
      expect(semanticsFinder, findsOneWidget);
    });
  });
}
