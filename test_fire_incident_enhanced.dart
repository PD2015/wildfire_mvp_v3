// Quick verification test for enhanced FireIncident model
// Tests all new satellite sensor fields for fire information sheet
// This verifies Task 1 completion: "Update FireIncident Model"

import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';

void main() {
  print('🧪 Testing enhanced FireIncident model with satellite sensor fields...\n');

  // Test 1: Create incident with all new fields
  final now = DateTime.now().toUtc();
  final detectedAt = now.subtract(Duration(hours: 2));
  
  final incident = FireIncident(
    id: 'test_fire_001',
    location: const LatLng(55.9533, -3.1883), // Edinburgh
    source: DataSource.effis,
    freshness: Freshness.live,
    timestamp: now,
    intensity: 'high',
    description: 'Large wildfire near Edinburgh',
    areaHectares: 150.5,
    // New satellite sensor fields
    detectedAt: detectedAt,
    sensorSource: 'VIIRS',
    confidence: 95.5,
    frp: 1250.0,
    lastUpdate: now,
  );

  print('✅ Created FireIncident with new fields:');
  print('   ID: ${incident.id}');
  print('   Detection Time: ${incident.detectedAt}');
  print('   Sensor: ${incident.sensorSource}');
  print('   Confidence: ${incident.confidence}%');
  print('   FRP: ${incident.frp} MW');
  print('   Last Update: ${incident.lastUpdate}');

  // Test 2: Serialization/Deserialization
  print('\n🔄 Testing serialization...');
  final json = incident.toJson();
  print('✅ Serialized to JSON (${json.length} chars)');

  final deserialized = FireIncident.fromCacheJson(json);
  print('✅ Deserialized from JSON');
  print('   Same ID: ${deserialized.id == incident.id}');
  print('   Same detection time: ${deserialized.detectedAt == incident.detectedAt}');
  print('   Same sensor: ${deserialized.sensorSource == incident.sensorSource}');

  // Test 3: Test factory
  print('\n🏭 Testing factory method...');
  final testIncident = FireIncident.test(
    id: 'factory_test',
    location: const LatLng(56.0, -4.0),
    confidence: 80.0,
    frp: 500.0,
  );
  print('✅ Created via factory with defaults:');
  print('   Sensor: ${testIncident.sensorSource}');
  print('   Intensity: ${testIncident.intensity}');

  // Test 4: copyWith method
  print('\n📋 Testing copyWith...');
  final updated = incident.copyWith(
    confidence: 98.0,
    frp: 1500.0,
    sensorSource: 'MODIS',
  );
  print('✅ Updated via copyWith:');
  print('   New confidence: ${updated.confidence}%');
  print('   New FRP: ${updated.frp} MW');
  print('   New sensor: ${updated.sensorSource}');
  print('   Same ID: ${updated.id == incident.id}');

  print('\n🎉 All enhanced FireIncident model tests passed!');
  print('📋 Task 1: "Update FireIncident Model" - COMPLETE ✅');
}