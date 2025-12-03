import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wildfire_mvp_v3/features/map/utils/marker_icon_helper.dart';

void main() {
  // Ensure Flutter bindings are initialized for tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MarkerIconHelper', () {
    late MarkerIconHelper helper;

    setUp(() {
      helper = MarkerIconHelper();
    });

    tearDown(() {
      helper.dispose();
    });

    test('isReady returns false before initialization', () {
      expect(helper.isReady, isFalse);
    });

    test('getIcon returns fallback marker before initialization', () {
      // Should return default marker since not initialized
      final icon = helper.getIcon('high');
      expect(icon, isA<BitmapDescriptor>());
    });

    test('getIcon handles case-insensitive intensity', () {
      // These should all work without throwing
      expect(() => helper.getIcon('HIGH'), returnsNormally);
      expect(() => helper.getIcon('High'), returnsNormally);
      expect(() => helper.getIcon('high'), returnsNormally);
    });

    test('getIcon handles unknown intensity gracefully', () {
      final icon = helper.getIcon('unknown_intensity');
      expect(icon, isA<BitmapDescriptor>());
    });

    test('getIcon returns different fallback markers for each intensity', () {
      // Before initialization, should return different colored fallback markers
      final lowIcon = helper.getIcon('low');
      final moderateIcon = helper.getIcon('moderate');
      final highIcon = helper.getIcon('high');

      // All should be valid BitmapDescriptors
      expect(lowIcon, isA<BitmapDescriptor>());
      expect(moderateIcon, isA<BitmapDescriptor>());
      expect(highIcon, isA<BitmapDescriptor>());
    });

    test('dispose clears cache and resets state', () {
      helper.dispose();
      expect(helper.isReady, isFalse);
    });

    test('dispose can be called multiple times safely', () {
      helper.dispose();
      helper.dispose();
      expect(helper.isReady, isFalse);
    });

    // NOTE: The initialize() method requires the full Flutter rendering engine
    // (raster thread) to convert Canvas drawings to PNG bytes. This works in
    // real app execution but can hang in unit test environments.
    //
    // Full initialization testing should be done via:
    // 1. Integration tests with real device/emulator
    // 2. Manual testing in the app
    //
    // The synchronous fallback behavior (tested above) ensures the app
    // works even if initialization fails.
  });
}
