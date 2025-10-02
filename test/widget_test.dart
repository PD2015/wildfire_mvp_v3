// This is a basic widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:wildfire_mvp_v3/main.dart';

void main() {
  testWidgets('WildFire app loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WildFireApp());

    // Verify that our app title appears (appears in both AppBar and body).
    expect(find.text('WildFire Risk Assessment'), findsNWidgets(2));
    expect(find.text('EffisService implementation in progress...'),
        findsOneWidget);
  });
}
