import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wildfire_mvp_v3/features/onboarding/widgets/onboarding_card.dart';

void main() {
  group('OnboardingCard', () {
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: OnboardingCard(child: Text('Test content'))),
        ),
      );

      expect(find.text('Test content'), findsOneWidget);
    });

    testWidgets('applies default padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OnboardingCard(child: Container(key: const Key('child'))),
          ),
        ),
      );

      final padding = tester.widget<Padding>(
        find
            .ancestor(
              of: find.byKey(const Key('child')),
              matching: find.byType(Padding),
            )
            .first,
      );

      expect(padding.padding, const EdgeInsets.all(24));
    });

    testWidgets('applies custom padding when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OnboardingCard(
              padding: const EdgeInsets.all(16),
              child: Container(key: const Key('child')),
            ),
          ),
        ),
      );

      final padding = tester.widget<Padding>(
        find
            .ancestor(
              of: find.byKey(const Key('child')),
              matching: find.byType(Padding),
            )
            .first,
      );

      expect(padding.padding, const EdgeInsets.all(16));
    });

    testWidgets('displays icon when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnboardingCard(icon: Icons.star, child: Text('Content')),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('displays title when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnboardingCard(title: 'Card Title', child: Text('Content')),
          ),
        ),
      );

      expect(find.text('Card Title'), findsOneWidget);
    });

    testWidgets('displays icon with custom color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnboardingCard(
              icon: Icons.star,
              iconColor: Colors.red,
              child: Text('Content'),
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.star));
      expect(icon.color, Colors.red);
    });

    testWidgets('applies background color when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnboardingCard(
              backgroundColor: Colors.blue,
              child: Text('Content'),
            ),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.color, Colors.blue);
    });

    testWidgets('constrains max width to 400dp', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OnboardingCard(child: Container(key: const Key('child'))),
          ),
        ),
      );

      // Find the ConstrainedBox that's a direct child of Center
      final constrainedBoxes = tester.widgetList<ConstrainedBox>(
        find.byType(ConstrainedBox),
      );

      // Find one with 400 max width
      final hasCorrectConstraint = constrainedBoxes.any(
        (box) => box.constraints.maxWidth == 400,
      );
      expect(hasCorrectConstraint, isTrue);
    });

    testWidgets('has rounded corners with 16dp radius', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: OnboardingCard(child: Text('Content'))),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      final shape = card.shape as RoundedRectangleBorder;
      final borderRadius = shape.borderRadius as BorderRadius;

      expect(borderRadius.topLeft.x, 16);
    });
  });
}
