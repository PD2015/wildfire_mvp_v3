import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wildfire_mvp_v3/features/onboarding/widgets/page_indicator.dart';

void main() {
  group('PageIndicator', () {
    testWidgets('renders correct number of dots', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PageIndicator(
              currentPage: 0,
              totalPages: 4,
            ),
          ),
        ),
      );

      // Should have 4 animated containers (dots)
      final containers = find.byType(AnimatedContainer);
      expect(containers, findsNWidgets(4));
    });

    testWidgets('highlights current page dot', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PageIndicator(
              currentPage: 2,
              totalPages: 4,
            ),
          ),
        ),
      );

      final dots = tester
          .widgetList<AnimatedContainer>(
            find.byType(AnimatedContainer),
          )
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

    testWidgets('has accessibility label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PageIndicator(
              currentPage: 1,
              totalPages: 4,
            ),
          ),
        ),
      );

      // Check semantics are present by looking for Row containing dots
      expect(find.byType(PageIndicator), findsOneWidget);

      // Find semantics node with the label
      final semanticsFinder = find.bySemanticsLabel('Page 2 of 4');
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('updates when currentPage changes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PageIndicator(
              currentPage: 0,
              totalPages: 4,
            ),
          ),
        ),
      );

      // Verify first page label
      expect(find.bySemanticsLabel('Page 1 of 4'), findsOneWidget);

      // Change to page 3
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PageIndicator(
              currentPage: 2,
              totalPages: 4,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify third page label
      expect(find.bySemanticsLabel('Page 3 of 4'), findsOneWidget);
    });

    testWidgets('works with single page', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PageIndicator(
              currentPage: 0,
              totalPages: 1,
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedContainer), findsOneWidget);
    });
  });
}
