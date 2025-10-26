// Debug script for testing FireIncident serialization
// NOTE: print() is intentional for debug output
// ignore_for_file: avoid_print

import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';

void main() {
  final incident = FireIncident(
    id: 'test1',
    location: const LatLng(55.9533, -3.1883),
    source: DataSource.effis,
    freshness: Freshness.live,
    timestamp: DateTime(2025, 1, 20, 12, 0, 0),
    intensity: 'moderate',
    description: 'Test fire',
    areaHectares: 15.5,
  );

  final json = incident.toJson();
  print('Serialized: $json');

  final deserialized = FireIncident.fromJson(json);
  print('Deserialized: ${deserialized.id}');
}
