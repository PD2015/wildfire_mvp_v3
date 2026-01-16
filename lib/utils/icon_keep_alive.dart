/// Icon Keep Alive - prevents tree-shaking of dynamically-referenced icons
///
/// Flutter's web release builds use tree-shaking to remove unused icons.
/// Icons referenced dynamically (in switch statements, conditional logic,
/// or via variables) may be removed because the compiler can't statically
/// detect their usage.
///
/// This file explicitly references all icons used across the app to ensure
/// they're included in production builds.
///
/// Reference: https://docs.flutter.dev/deployment/web#tree-shaking-icons
///
/// Last audited: 2025-12-02
/// To update: Run `grep -r "Icons\." lib/ | sort -u` and add any new icons
library icon_keep_alive;

import 'package:flutter/material.dart';

/// References all icons to prevent tree-shaking.
/// DO NOT CALL - exists only to preserve icons in release builds.
@pragma('vm:entry-point')
void keepIconsAlive() {
  // This list is comprehensive - audited from all lib/**/*.dart files
  const icons = <IconData>[
    // === Location & GPS ===
    Icons.my_location,
    Icons.gps_fixed,
    Icons.location_pin,
    Icons.location_on,
    Icons.location_on_outlined,
    Icons.edit_location_alt,
    Icons.public, // defaultFallback location source
    // === Map Controls ===
    Icons.add,
    Icons.remove,
    Icons.layers,
    Icons.terrain,
    Icons.satellite_alt,
    Icons.map,
    Icons.map_outlined,

    // === Navigation & Actions ===
    Icons.close,
    Icons.check,
    Icons.search,
    Icons.clear,
    Icons.refresh,
    Icons.copy,

    // === Status & Feedback ===
    Icons.cached,
    Icons.cloud_done,
    Icons.check_circle_outline,
    Icons.error_outline,
    Icons.info_outline,

    // === Warning & Fire ===
    Icons.warning_amber,
    Icons.warning_amber_outlined,
    Icons.warning_amber_rounded,
    Icons.local_fire_department,
    Icons.local_fire_department_outlined,

    // === Communication ===
    Icons.call,
    Icons.phone,

    // === Data Source ===
    Icons.science,
    Icons.science_outlined,
    Icons.access_time,

    // === Misc ===
    Icons.lightbulb,
    Icons.grid_3x3,
  ];

  // Reference to prevent optimization removal
  assert(icons.isNotEmpty);
}
