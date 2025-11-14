import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/theme/wildfire_a11y_theme.dart';

/// Simplified MaterialApp integration tests for WildfireA11yTheme
/// 
/// Tests focus on theme properties directly without loading full app context.
/// Full app integration verified via manual QA (quickstart.md steps 4-6).
void main() {
  testWidgets('WildfireA11yTheme.light has Material 3 enabled', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: WildfireA11yTheme.light,
        home: const Scaffold(body: Text('Test')),
      ),
    );

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme!.useMaterial3, isTrue);
    expect(materialApp.theme!.brightness, equals(Brightness.light));
  });

  testWidgets('WildfireA11yTheme.dark has Material 3 enabled', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: WildfireA11yTheme.dark,
        home: const Scaffold(body: Text('Test')),
      ),
    );

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme!.useMaterial3, isTrue);
    expect(materialApp.theme!.brightness, equals(Brightness.dark));
  });

  testWidgets('Light theme accessible from BuildContext', (tester) async {
    late ThemeData capturedTheme;

    await tester.pumpWidget(
      MaterialApp(
        theme: WildfireA11yTheme.light,
        home: Builder(
          builder: (context) {
            capturedTheme = Theme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(capturedTheme.useMaterial3, isTrue);
    expect(capturedTheme.brightness, equals(Brightness.light));
  });

  testWidgets('Dark theme accessible from BuildContext', (tester) async {
    late ThemeData capturedTheme;

    await tester.pumpWidget(
      MaterialApp(
        theme: WildfireA11yTheme.dark,
        home: Builder(
          builder: (context) {
            capturedTheme = Theme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(capturedTheme.useMaterial3, isTrue);
    expect(capturedTheme.brightness, equals(Brightness.dark));
  });

  testWidgets('Light ColorScheme accessible from context', (tester) async {
    late ColorScheme capturedColorScheme;

    await tester.pumpWidget(
      MaterialApp(
        theme: WildfireA11yTheme.light,
        home: Builder(
          builder: (context) {
            capturedColorScheme = Theme.of(context).colorScheme;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(capturedColorScheme.primary, isNotNull);
    expect(capturedColorScheme.surface, isNotNull);
    expect(capturedColorScheme.brightness, equals(Brightness.light));
  });

  testWidgets('Dark ColorScheme accessible from context', (tester) async {
    late ColorScheme capturedColorScheme;

    await tester.pumpWidget(
      MaterialApp(
        theme: WildfireA11yTheme.dark,
        home: Builder(
          builder: (context) {
            capturedColorScheme = Theme.of(context).colorScheme;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(capturedColorScheme.primary, isNotNull);
    expect(capturedColorScheme.surface, isNotNull);
    expect(capturedColorScheme.brightness, equals(Brightness.dark));
  });
}
