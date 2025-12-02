/// Icon Keep Alive - ensures these icons are not tree-shaken in release builds
/// 
/// Flutter's tree-shaker may remove icons it can't statically detect.
/// This file explicitly references all icons used across the app.
/// 
/// Reference: https://docs.flutter.dev/development/tools/web-renderers#icon-tree-shaking
library icon_keep_alive;

import 'package:flutter/material.dart';

/// DO NOT CALL THIS FUNCTION - it exists only to prevent tree-shaking
/// of icons that are used dynamically throughout the app.
@pragma('vm:entry-point')
void keepIconsAlive() {
  // Location Picker icons
  const icons = [
    Icons.my_location,
    Icons.add,
    Icons.remove,
    Icons.layers,
    Icons.terrain,
    Icons.satellite_alt,
    Icons.map,
    Icons.map_outlined,
    Icons.location_pin,
    Icons.close,
    Icons.check,
    Icons.gps_fixed,
    Icons.cached,
    Icons.search,
    Icons.clear,
    Icons.location_on_outlined,
    
    // Bottom Navigation icons
    Icons.warning_amber,
    Icons.warning_amber_outlined,
    Icons.local_fire_department,
    Icons.local_fire_department_outlined,
    
    // Emergency button icons
    Icons.call,
    
    // Home screen icons
    Icons.refresh,
    Icons.error_outline,
    
    // Map screen icons
    Icons.check_circle_outline,
    Icons.cloud_done,
    Icons.science,
    Icons.science_outlined,
    Icons.access_time,
  ];
  
  // Reference to prevent optimization removal
  assert(icons.isNotEmpty);
}
