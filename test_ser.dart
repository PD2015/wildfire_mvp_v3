// Debug script for testing FireIncident serialization
// NOTE: print() is intentional for debug output
// ignore_for_file: avoid_print

import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';

void main() {
  final incident = FireIncident.test(
    id: 'test1',
    location: const LatLng(55.9533, -3.1883),
    timestamp: DateTime(2025, 1, 20, 12, 0, 0),
    description: 'Test fire',
    areaHectares: 15.5,
  );

  final json = incident.toJson();
  print('Serialized: $json');

  final deserialized = FireIncident.fromCacheJson(json);
  print('Deserialized: ${deserialized.id}');
}
