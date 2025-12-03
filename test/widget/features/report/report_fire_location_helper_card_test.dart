import 'dart:ui' show SemanticsFlag;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/features/report/models/report_fire_state.dart';
import 'package:wildfire_mvp_v3/features/report/widgets/report_fire_location_helper_card.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart' as app;
import 'package:wildfire_mvp_v3/models/what3words_models.dart';

void main() {
  // Required for clipboard operations in tests
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestWidget({
    ReportFireLocation? location,
    VoidCallback? onSelectLocation,
  }) {
    return MaterialApp(
      theme: ThemeData.light(useMaterial3: true),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ReportFireLocationHelperCard(
              location: location,
              onSelectLocation: onSelectLocation ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  group('ReportFireLocationHelperCard', () {
    group('empty state', () {
      testWidgets('shows header with correct title', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.text('Location to give when you call'), findsOneWidget);
        expect(find.text('Optional — helps you tell 999 where the fire is.'),
            findsOneWidget);
      });

      testWidgets('shows empty state message', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(
          find.text(
              'Use the map to pick where the fire is. Your location will appear here so you can read it out when you call.'),
          findsOneWidget,
        );
      });

      testWidgets('shows "Open map to set location" button', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.text('Open map to set location'), findsOneWidget);
        expect(find.byIcon(Icons.add_location_alt), findsOneWidget);
      });

      testWidgets('does not show copy button', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.byKey(const Key('copy_location_button')), findsNothing);
      });

      testWidgets('shows disclaimer', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(
          find.text(
              'This app does not contact emergency services. Always phone 999, 101 or Crimestoppers yourself.'),
          findsOneWidget,
        );
      });
    });

    group('with location set', () {
      late ReportFireLocation testLocation;

      setUp(() {
        testLocation = ReportFireLocation(
          coordinates: const app.LatLng(57.04850, -3.59620),
          nearestPlaceName: 'Cairngorms National Park',
          what3words: What3wordsAddress.parse('slurs.this.name'),
          selectedAt: DateTime.now(),
        );
      });

      testWidgets('shows nearest place name', (tester) async {
        await tester.pumpWidget(buildTestWidget(location: testLocation));

        expect(find.text('Nearest place'), findsOneWidget);
        expect(find.text('Cairngorms National Park'), findsOneWidget);
      });

      testWidgets('shows coordinates with 5dp precision', (tester) async {
        await tester.pumpWidget(buildTestWidget(location: testLocation));

        expect(find.text('Coordinates'), findsOneWidget);
        expect(find.text('57.04850, -3.59620'), findsOneWidget);
      });

      testWidgets('shows coordinates helper text', (tester) async {
        await tester.pumpWidget(buildTestWidget(location: testLocation));

        expect(
          find.text('Exact coordinates recommended for fire service'),
          findsOneWidget,
        );
      });

      testWidgets('shows what3words address', (tester) async {
        await tester.pumpWidget(buildTestWidget(location: testLocation));

        expect(find.text('what3words'), findsOneWidget);
        expect(find.text('///slurs.this.name'), findsOneWidget);
      });

      testWidgets('shows "Update location" button', (tester) async {
        await tester.pumpWidget(buildTestWidget(location: testLocation));

        expect(find.text('Update location'), findsOneWidget);
        expect(find.byIcon(Icons.edit_location_alt), findsOneWidget);
      });

      testWidgets('shows copy button', (tester) async {
        await tester.pumpWidget(buildTestWidget(location: testLocation));

        expect(find.byKey(const Key('copy_location_button')), findsOneWidget);
        expect(find.byIcon(Icons.copy), findsOneWidget);
      });
    });

    group('without optional fields', () {
      testWidgets('shows unavailable for missing what3words', (tester) async {
        final location = ReportFireLocation(
          coordinates: const app.LatLng(57.04850, -3.59620),
          selectedAt: DateTime.now(),
        );

        await tester.pumpWidget(buildTestWidget(location: location));

        expect(find.text('/// Unavailable'), findsOneWidget);
      });

      testWidgets('does not show place name section when null', (tester) async {
        final location = ReportFireLocation(
          coordinates: const app.LatLng(57.04850, -3.59620),
          selectedAt: DateTime.now(),
        );

        await tester.pumpWidget(buildTestWidget(location: location));

        expect(find.text('Nearest place'), findsNothing);
      });
    });

    group('button interactions', () {
      testWidgets('open map button triggers callback', (tester) async {
        var callbackCalled = false;

        await tester.pumpWidget(buildTestWidget(
          onSelectLocation: () => callbackCalled = true,
        ));

        await tester.tap(find.byKey(const Key('open_location_picker_button')));
        await tester.pump();

        expect(callbackCalled, isTrue);
      });

      testWidgets('update location button triggers callback', (tester) async {
        var callbackCalled = false;
        final location = ReportFireLocation(
          coordinates: const app.LatLng(57.04850, -3.59620),
          selectedAt: DateTime.now(),
        );

        await tester.pumpWidget(buildTestWidget(
          location: location,
          onSelectLocation: () => callbackCalled = true,
        ));

        await tester.tap(find.byKey(const Key('open_location_picker_button')));
        await tester.pump();

        expect(callbackCalled, isTrue);
      });

      testWidgets('copy button copies to clipboard and shows snackbar',
          (tester) async {
        final location = ReportFireLocation(
          coordinates: const app.LatLng(57.04850, -3.59620),
          nearestPlaceName: 'Aviemore',
          what3words: What3wordsAddress.parse('filled.count.soap'),
          selectedAt: DateTime.now(),
        );

        // Mock clipboard
        String? clipboardContent;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (MethodCall methodCall) async {
            if (methodCall.method == 'Clipboard.setData') {
              clipboardContent =
                  (methodCall.arguments as Map)['text'] as String;
            }
            return null;
          },
        );

        await tester.pumpWidget(buildTestWidget(location: location));

        await tester.tap(find.byKey(const Key('copy_location_button')));
        await tester.pumpAndSettle();

        // Verify clipboard content
        expect(clipboardContent, contains('Nearest place: Aviemore'));
        expect(clipboardContent, contains('Coordinates: 57.04850, -3.59620'));
        expect(clipboardContent, contains('what3words: ///filled.count.soap'));

        // Verify snackbar
        expect(
          find.text(
              'Location copied. You can paste it into notes before calling.'),
          findsOneWidget,
        );
      });
    });

    group('accessibility', () {
      testWidgets('buttons have minimum 48dp touch targets', (tester) async {
        final location = ReportFireLocation(
          coordinates: const app.LatLng(57.04850, -3.59620),
          selectedAt: DateTime.now(),
        );

        await tester.pumpWidget(buildTestWidget(location: location));

        // Find the update button
        final openButton = tester.widget<SizedBox>(
          find
              .ancestor(
                of: find.byKey(const Key('open_location_picker_button')),
                matching: find.byType(SizedBox),
              )
              .first,
        );
        expect(openButton.height, greaterThanOrEqualTo(48));

        // Find the copy button wrapper
        final copyButtonWrapper = tester.widget<SizedBox>(
          find
              .ancestor(
                of: find.byKey(const Key('copy_location_button')),
                matching: find.byType(SizedBox),
              )
              .first,
        );
        expect(copyButtonWrapper.height, greaterThanOrEqualTo(48));
        expect(copyButtonWrapper.width, greaterThanOrEqualTo(48));
      });

      testWidgets('header is marked as semantic header', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        final semantics = tester.getSemantics(
          find.text('Location to give when you call'),
        );

        expect(semantics.hasFlag(SemanticsFlag.isHeader), isTrue);
      });

      testWidgets('disclaimer has semantic label', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        // Find Semantics widget containing the disclaimer
        final semanticsWidget = find.byWidgetPredicate((widget) {
          if (widget is Semantics && widget.properties.label != null) {
            return widget.properties.label!
                .contains('This app does not contact emergency services');
          }
          return false;
        });

        expect(semanticsWidget, findsOneWidget);
      });
    });

    group('Material 3 theming', () {
      testWidgets('uses theme colors not hardcoded values', (tester) async {
        final customTheme = ThemeData.light(useMaterial3: true).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.purple,
          ),
        );

        await tester.pumpWidget(MaterialApp(
          theme: customTheme,
          home: Scaffold(
            body: ReportFireLocationHelperCard(
              location: null,
              onSelectLocation: () {},
            ),
          ),
        ));

        // Card should render without errors with custom theme
        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('card has rounded corners', (tester) async {
        await tester.pumpWidget(buildTestWidget());

        final card = tester.widget<Card>(find.byType(Card));
        final shape = card.shape as RoundedRectangleBorder;

        expect(shape.borderRadius, equals(BorderRadius.circular(16)));
      });
    });
  });
}
