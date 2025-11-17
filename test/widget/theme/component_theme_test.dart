import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wildfire_mvp_v3/theme/wildfire_a11y_theme.dart';

/// Golden tests for themed components
/// Validates visual consistency of WildfireA11yTheme across light/dark modes
///
/// Run `flutter test --update-goldens` to regenerate baseline images
/// Run `flutter test` to compare against baselines
///
/// Constitutional compliance:
/// - C1: Automated visual regression testing
/// - C3: Verifies accessible component styling (≥44dp touch targets)
/// - C4: Documents theme application across components
void main() {
  group('ElevatedButton Theme (Light Mode)', () {
    testWidgets('renders with correct colors and spacing',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: WildfireA11yTheme.light,
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Primary Action'),
                  ),
                  const SizedBox(height: 16),
                  const ElevatedButton(
                    onPressed: null,
                    child: Text('Disabled Action'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/elevated_button_light.png'),
      );
    });
  });

  group('ElevatedButton Theme (Dark Mode)', () {
    testWidgets('renders with correct colors and spacing',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: WildfireA11yTheme.dark,
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Primary Action'),
                  ),
                  const SizedBox(height: 16),
                  const ElevatedButton(
                    onPressed: null,
                    child: Text('Disabled Action'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/elevated_button_dark.png'),
      );
    });
  });

  group('OutlinedButton Theme (Light Mode)', () {
    testWidgets('renders with correct border and colors',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: WildfireA11yTheme.light,
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Secondary Action'),
                  ),
                  const SizedBox(height: 16),
                  const OutlinedButton(
                    onPressed: null,
                    child: Text('Disabled Action'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/outlined_button_light.png'),
      );
    });
  });

  group('OutlinedButton Theme (Dark Mode)', () {
    testWidgets('renders with correct border and colors',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: WildfireA11yTheme.dark,
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Secondary Action'),
                  ),
                  const SizedBox(height: 16),
                  const OutlinedButton(
                    onPressed: null,
                    child: Text('Disabled Action'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/outlined_button_dark.png'),
      );
    });
  });

  group('TextButton Theme (Light Mode)', () {
    testWidgets('renders with correct colors and spacing',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: WildfireA11yTheme.light,
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: const Text('Tertiary Action'),
                  ),
                  const SizedBox(height: 16),
                  const TextButton(
                    onPressed: null,
                    child: Text('Disabled Action'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/text_button_light.png'),
      );
    });
  });

  group('TextButton Theme (Dark Mode)', () {
    testWidgets('renders with correct colors and spacing',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: WildfireA11yTheme.dark,
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: const Text('Tertiary Action'),
                  ),
                  const SizedBox(height: 16),
                  const TextButton(
                    onPressed: null,
                    child: Text('Disabled Action'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/text_button_dark.png'),
      );
    });
  });

  group('InputDecoration Theme (Light Mode)', () {
    testWidgets('renders text fields with correct styling',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: WildfireA11yTheme.light,
          home: const Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Default Field',
                        helperText: 'Helper text',
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Error Field',
                        errorText: 'This field has an error',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/input_decoration_light.png'),
      );
    });
  });

  group('InputDecoration Theme (Dark Mode)', () {
    testWidgets('renders text fields with correct styling',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: WildfireA11yTheme.dark,
          home: const Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Default Field',
                        helperText: 'Helper text',
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Error Field',
                        errorText: 'This field has an error',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('goldens/input_decoration_dark.png'),
      );
    });
  });
}
