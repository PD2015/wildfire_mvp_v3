import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Test environment configuration for debugging tests
class DebugTestEnvironment {
  
  /// Set up SharedPreferences testing environment
  static void setUpSharedPreferences() {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Clear SharedPreferences before each test
    SharedPreferences.setMockInitialValues({});
  }

  /// Set up SharedPreferences with debugging data
  static void setUpSharedPreferencesWithDebuggingData() {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    SharedPreferences.setMockInitialValues({
      'manual_location_lat': 57.2,
      'manual_location_lon': -3.8,
      'manual_location_place': 'Aviemore (Debug)',
      'location_timestamp': '2025-10-07T12:00:00Z',
      'location_source': 'DEBUG_BYPASS',
      'test_mode': true,
    });
  }

  /// Set up SharedPreferences with cleared cache state
  static void setUpSharedPreferencesWithClearedCache() {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    SharedPreferences.setMockInitialValues({
      'test_mode': true, // Only preserved key
    });
  }

  /// Tear down test environment
  static void tearDown() {
    // Clear any SharedPreferences state
    SharedPreferences.setMockInitialValues({});
  }

  /// Get current SharedPreferences state for debugging
  static Future<Map<String, dynamic>> getCurrentPreferencesState() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final state = <String, dynamic>{};
    
    for (final key in keys) {
      final value = prefs.get(key);
      state[key] = value;
    }
    
    return state;
  }

  /// Validate that debugging keys are present
  static Future<bool> hasDebuggingData() async {
    final prefs = await SharedPreferences.getInstance();
    
    return prefs.containsKey('manual_location_lat') &&
           prefs.containsKey('manual_location_lon') &&
           prefs.containsKey('location_source');
  }

  /// Validate that debugging keys are cleared
  static Future<bool> isDebuggingDataCleared() async {
    final prefs = await SharedPreferences.getInstance();
    
    return !prefs.containsKey('manual_location_lat') &&
           !prefs.containsKey('manual_location_lon') &&
           !prefs.containsKey('manual_location_place') &&
           !prefs.containsKey('location_timestamp') &&
           !prefs.containsKey('location_source');
  }

  /// Validate that test mode is preserved
  static Future<bool> isTestModePreserved() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('test_mode') == true;
  }
}

/// Custom test group wrapper for debugging tests
void debuggingTestGroup(String description, Function() body, {
  bool setUpDebuggingData = false,
  bool setClearedCache = false,
}) {
  group(description, () {
    setUp(() {
      if (setUpDebuggingData) {
        DebugTestEnvironment.setUpSharedPreferencesWithDebuggingData();
      } else if (setClearedCache) {
        DebugTestEnvironment.setUpSharedPreferencesWithClearedCache();
      } else {
        DebugTestEnvironment.setUpSharedPreferences();
      }
    });

    tearDown(() {
      DebugTestEnvironment.tearDown();
    });

    body();
  });
}

/// Custom test wrapper for debugging tests
void debuggingTest(String description, Function() body, {
  bool setUpDebuggingData = false,
  bool setClearedCache = false,
}) {
  test(description, () async {
    if (setUpDebuggingData) {
      DebugTestEnvironment.setUpSharedPreferencesWithDebuggingData();
    } else if (setClearedCache) {
      DebugTestEnvironment.setUpSharedPreferencesWithClearedCache();
    } else {
      DebugTestEnvironment.setUpSharedPreferences();
    }

    await body();

    DebugTestEnvironment.tearDown();
  });
}