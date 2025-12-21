import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wildfire_mvp_v3/features/onboarding/widgets/radius_selector.dart';
import 'package:wildfire_mvp_v3/models/consent_record.dart';

void main() {
  group('RadiusSelector', () {
    testWidgets('displays all radius options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadiusSelector(
              selectedRadius: 10,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Should show Off, 5km, 10km, 25km, 50km
      expect(find.text('Off'), findsOneWidget);
      expect(find.text('5km'), findsOneWidget);
      expect(find.text('10km'), findsOneWidget);
      expect(find.text('25km'), findsOneWidget);
      expect(find.text('50km'), findsOneWidget);
    });

    testWidgets('shows selected chip as selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadiusSelector(
              selectedRadius: 25,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));

      // Find the 25km chip and verify it's selected
      final chip25 = chips.firstWhere(
        (chip) => (chip.label as Text).data == '25km',
      );
      expect(chip25.selected, isTrue);

      // Verify others are not selected
      final chip10 = chips.firstWhere(
        (chip) => (chip.label as Text).data == '10km',
      );
      expect(chip10.selected, isFalse);
    });

    testWidgets('calls onChanged when chip tapped', (tester) async {
      int? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadiusSelector(
              selectedRadius: 10,
              onChanged: (value) => selectedValue = value,
            ),
          ),
        ),
      );

      await tester.tap(find.text('50km'));
      await tester.pump();

      expect(selectedValue, 50);
    });

    testWidgets('Off option has value of 0', (tester) async {
      int? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadiusSelector(
              selectedRadius: 10,
              onChanged: (value) => selectedValue = value,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Off'));
      await tester.pump();

      expect(selectedValue, 0);
    });

    testWidgets('has accessibility labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadiusSelector(
              selectedRadius: 10,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Check semantics are present
      final semantics = find.byType(Semantics);
      expect(semantics, findsWidgets);
    });

    testWidgets('respects valid radius options from config', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadiusSelector(
              selectedRadius: 10,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
      expect(chips.length, OnboardingConfig.validRadiusOptions.length);
    });

    testWidgets('chips have minimum 48dp touch target', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RadiusSelector(
              selectedRadius: 10,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
      for (final chip in chips) {
        // Material's padded tap target ensures 48dp minimum
        expect(chip.materialTapTargetSize, MaterialTapTargetSize.padded);
      }
    });
  });
}
