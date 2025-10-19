import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Accessibility helper utilities for A10 map tests
///
/// Provides reusable methods for validating C3 compliance.
class A11yHelpers {
  /// Verify touch target meets minimum size requirements
  ///
  /// iOS: ≥44dp, Android: ≥48dp
  /// Using 44dp as minimum for cross-platform consistency
  static void verifyTouchTargetSize(WidgetTester tester, Finder finder) {
    expect(finder, findsOneWidget,
        reason: 'Widget not found for touch target check');

    final size = tester.getSize(finder);
    expect(
      size.width,
      greaterThanOrEqualTo(44.0),
      reason: 'Touch target width must be ≥44dp (found ${size.width})',
    );
    expect(
      size.height,
      greaterThanOrEqualTo(44.0),
      reason: 'Touch target height must be ≥44dp (found ${size.height})',
    );
  }

  /// Verify widget has semantic label for screen readers
  static void verifySemanticLabel(
      WidgetTester tester, Finder finder, String expectedLabel) {
    expect(finder, findsOneWidget,
        reason: 'Widget not found for semantic label check');

    final semantics = tester.getSemantics(finder);
    expect(
      semantics.label,
      isNotEmpty,
      reason: 'Widget must have semantic label for screen readers',
    );

    if (expectedLabel.isNotEmpty) {
      expect(
        semantics.label,
        contains(expectedLabel),
        reason: 'Semantic label should contain "$expectedLabel"',
      );
    }
  }
}
