import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wildfire_mvp_v3/features/location_picker/widgets/location_info_panel.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/models/what3words_models.dart';

void main() {
  // Initialize Flutter bindings for clipboard access
  TestWidgetsFlutterBinding.ensureInitialized();

  const testCoordinates = LatLng(55.9533, -3.1883);
  final testWhat3words = What3wordsAddress.tryParse('filled.count.soap')!;

  group('LocationInfoPanel', () {
    testWidgets('displays default header "Pan map to set location"',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LocationInfoPanel(
              coordinates: testCoordinates,
            ),
          ),
        ),
      );

      // Should display default header
      expect(find.text('Pan map to set location'), findsOneWidget);
      expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    });

    testWidgets('displays coordinates with 2dp precision', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LocationInfoPanel(
              coordinates: testCoordinates,
            ),
          ),
        ),
      );

      // Should display coordinates in redacted format (2dp)
      expect(find.text('55.95,-3.19'), findsOneWidget);
    });

    testWidgets('shows loading state for what3words', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LocationInfoPanel(
              coordinates: testCoordinates,
              isLoadingWhat3words: true,
            ),
          ),
        ),
      );

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('displays what3words address when available', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationInfoPanel(
              coordinates: testCoordinates,
              what3words: testWhat3words,
            ),
          ),
        ),
      );

      // Should display what3words address
      expect(find.text('filled.count.soap'), findsOneWidget);
      // Should show /// prefix
      expect(find.text('///'), findsOneWidget);
    });

    testWidgets('shows error state when what3words fails', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LocationInfoPanel(
              coordinates: testCoordinates,
              what3wordsError: 'Network error',
            ),
          ),
        ),
      );

      // Should show unavailable message
      expect(find.text('Unavailable'), findsOneWidget);
    });

    testWidgets('copy button triggers callback', (tester) async {
      bool copyTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationInfoPanel(
              coordinates: testCoordinates,
              what3words: testWhat3words,
              onCopyWhat3words: () {
                copyTapped = true;
              },
            ),
          ),
        ),
      );

      // Find and tap copy button
      final copyButton = find.byKey(const Key('copy_what3words_button'));
      expect(copyButton, findsOneWidget);
      await tester.tap(copyButton);
      await tester.pump();

      expect(copyTapped, isTrue);
    });

    testWidgets('copy button has ≥48dp touch target (C3)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationInfoPanel(
              coordinates: testCoordinates,
              what3words: testWhat3words,
              onCopyWhat3words: () {},
            ),
          ),
        ),
      );

      // Find the SizedBox wrapping the IconButton
      final copyButtonParent = find.ancestor(
        of: find.byKey(const Key('copy_what3words_button')),
        matching: find.byType(SizedBox),
      );

      final sizedBoxes = tester.widgetList<SizedBox>(copyButtonParent);
      final buttonWrapper = sizedBoxes.firstWhere(
        (sb) => sb.width == 48 && sb.height == 48,
        orElse: () => const SizedBox(),
      );

      expect(buttonWrapper.width, 48);
      expect(buttonWrapper.height, 48);
    });

    testWidgets('shows Confirm and Cancel buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LocationInfoPanel(
              coordinates: testCoordinates,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('confirm_location_button')), findsOneWidget);
      expect(find.byKey(const Key('cancel_button')), findsOneWidget);
      expect(find.text('Confirm Location'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Confirm button triggers callback', (tester) async {
      bool confirmTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationInfoPanel(
              coordinates: testCoordinates,
              canConfirm: true,
              onConfirm: () {
                confirmTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('confirm_location_button')));
      await tester.pump();

      expect(confirmTapped, isTrue);
    });

    testWidgets('Cancel button triggers callback', (tester) async {
      bool cancelTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationInfoPanel(
              coordinates: testCoordinates,
              onCancel: () {
                cancelTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('cancel_button')));
      await tester.pump();

      expect(cancelTapped, isTrue);
    });

    testWidgets('Confirm button disabled when canConfirm is false',
        (tester) async {
      bool confirmTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationInfoPanel(
              coordinates: testCoordinates,
              canConfirm: false,
              onConfirm: () {
                confirmTapped = true;
              },
            ),
          ),
        ),
      );

      // Try to tap the disabled button
      await tester.tap(find.byKey(const Key('confirm_location_button')));
      await tester.pump();

      expect(confirmTapped, isFalse);
    });

    testWidgets('action buttons have ≥48dp height (C3)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LocationInfoPanel(
              coordinates: testCoordinates,
            ),
          ),
        ),
      );

      // Find the SizedBox wrapping the Confirm button
      final confirmButtonParent = find.ancestor(
        of: find.byKey(const Key('confirm_location_button')),
        matching: find.byType(SizedBox),
      );

      final confirmSizedBoxes =
          tester.widgetList<SizedBox>(confirmButtonParent);
      final confirmWrapper = confirmSizedBoxes.firstWhere(
        (sb) => sb.height == 48,
        orElse: () => const SizedBox(),
      );

      expect(confirmWrapper.height, 48);

      // Find the SizedBox wrapping the Cancel button
      final cancelButtonParent = find.ancestor(
        of: find.byKey(const Key('cancel_button')),
        matching: find.byType(SizedBox),
      );

      final cancelSizedBoxes = tester.widgetList<SizedBox>(cancelButtonParent);
      final cancelWrapper = cancelSizedBoxes.firstWhere(
        (sb) => sb.height == 48,
        orElse: () => const SizedBox(),
      );

      expect(cancelWrapper.height, 48);
    });

    testWidgets('has semantic labels for accessibility', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationInfoPanel(
              coordinates: testCoordinates,
              what3words: testWhat3words,
            ),
          ),
        ),
      );

      // Check that Semantics widgets are present
      final semantics = find.byType(Semantics);
      expect(semantics, findsWidgets);
    });

    testWidgets('shows default message when no what3words and not loading',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LocationInfoPanel(
              coordinates: testCoordinates,
              isLoadingWhat3words: false,
            ),
          ),
        ),
      );

      expect(find.text('what3words • Awaiting location…'), findsOneWidget);
    });

    testWidgets('coordinates row has location icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LocationInfoPanel(
              coordinates: testCoordinates,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.my_location), findsOneWidget);
    });
  });
}
