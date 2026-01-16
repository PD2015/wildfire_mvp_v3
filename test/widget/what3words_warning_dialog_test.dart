import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wildfire_mvp_v3/features/location_picker/widgets/what3words_warning_dialog.dart';

void main() {
  group('What3wordsWarningDialog', () {
    testWidgets('displays title "what3words Unavailable"', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: What3wordsWarningDialog())),
      );

      expect(find.text('what3words Unavailable'), findsOneWidget);
    });

    testWidgets('shows loading message when isLoading is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: What3wordsWarningDialog(isLoading: true)),
        ),
      );

      expect(find.textContaining('still loading'), findsOneWidget);
    });

    testWidgets('shows unavailable message when isLoading is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: What3wordsWarningDialog(isLoading: false)),
        ),
      );

      expect(find.textContaining('could not be retrieved'), findsOneWidget);
    });

    testWidgets('has "Wait" button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: What3wordsWarningDialog())),
      );

      expect(find.byKey(const Key('wait_button')), findsOneWidget);
      expect(find.text('Wait'), findsOneWidget);
    });

    testWidgets('has "Confirm Anyway" button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: What3wordsWarningDialog())),
      );

      expect(find.byKey(const Key('confirm_anyway_button')), findsOneWidget);
      expect(find.text('Confirm Anyway'), findsOneWidget);
    });

    testWidgets('"Wait" button returns false', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await What3wordsWarningDialog.show(context);
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap Wait button
      await tester.tap(find.byKey(const Key('wait_button')));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('"Confirm Anyway" button returns true', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await What3wordsWarningDialog.show(context);
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap Confirm Anyway button
      await tester.tap(find.byKey(const Key('confirm_anyway_button')));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('static show() displays dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  What3wordsWarningDialog.show(context);
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Dialog should not be visible initially
      expect(find.text('what3words Unavailable'), findsNothing);

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Dialog should now be visible
      expect(find.text('what3words Unavailable'), findsOneWidget);
    });

    testWidgets('dismissing dialog returns false', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await What3wordsWarningDialog.show(context);
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap outside dialog to dismiss (tap barrier)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('shows info icon with explanation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: What3wordsWarningDialog())),
      );

      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(
        find.textContaining('Coordinates are always saved'),
        findsOneWidget,
      );
    });

    testWidgets('static show() passes isLoading parameter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  What3wordsWarningDialog.show(context, isLoading: true);
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog with isLoading: true
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Should show loading message
      expect(find.textContaining('still loading'), findsOneWidget);
    });
  });
}
