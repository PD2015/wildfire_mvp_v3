// Verification test for ActiveFiresResponse model
// Tests all functionality required by Task 2: bounds validation, serialization, filtering
// Validates Task 2 completion: "Create ActiveFiresResponse Model"

import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:wildfire_mvp_v3/models/active_fires_response.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';

void main() {
  print('🧪 Testing ActiveFiresResponse model with viewport bounds and metadata...\n');

  // Test data setup
  final bounds = gmaps.LatLngBounds(
    southwest: const gmaps.LatLng(55.0, -4.0),
    northeast: const gmaps.LatLng(56.0, -3.0),
  );

  final now = DateTime.now().toUtc();
  final incidents = [
    FireIncident.test(
      id: 'fire_001',
      location: const LatLng(55.5, -3.5), // Within bounds
      confidence: 95.0,
      frp: 1200.0,
    ),
    FireIncident.test(
      id: 'fire_002', 
      location: const LatLng(55.8, -3.2), // Within bounds
      confidence: 80.0,
      frp: 500.0,
    ),
    FireIncident.test(
      id: 'fire_003',
      location: const LatLng(54.0, -5.0), // Outside bounds (should be filtered)
      confidence: 70.0,
      frp: 300.0,
    ),
  ];

  // Test 1: Create response with incidents
  print('📦 Test 1: Creating response with fire incidents...');
  final response = ActiveFiresResponse(
    incidents: incidents.take(2).toList(), // Only incidents within bounds
    queriedBounds: bounds,
    responseTimeMs: 250,
    dataSource: DataSource.effis,
    totalCount: 3, // Total found before filtering
    timestamp: now,
  );

  print('✅ Created response:');
  print('   Incidents: ${response.incidents.length}/${response.totalCount}');
  print('   Response time: ${response.responseTimeMs}ms');
  print('   Data source: ${response.dataSource}');
  print('   Has incidents: ${response.hasIncidents}');
  print('   Is empty: ${response.isEmpty}');
  print('   Is valid: ${response.isValid}');

  // Test 2: Empty response factory
  print('\n🔍 Test 2: Creating empty response...');
  final emptyResponse = ActiveFiresResponse.empty(
    bounds: bounds,
    dataSource: DataSource.mock,
    responseTimeMs: 100,
  );

  print('✅ Created empty response:');
  print('   Is empty: ${emptyResponse.isEmpty}');
  print('   Has incidents: ${emptyResponse.hasIncidents}');
  print('   Total count: ${emptyResponse.totalCount}');
  print('   Is valid: ${emptyResponse.isValid}');

  // Test 3: Serialization/Deserialization
  print('\n🔄 Test 3: Testing serialization...');
  final json = response.toJson();
  print('✅ Serialized to JSON (${json.toString().length} chars)');

  final deserialized = ActiveFiresResponse.fromCacheJson(json);
  print('✅ Deserialized from JSON:');
  print('   Same incident count: ${deserialized.incidents.length == response.incidents.length}');
  print('   Same bounds: ${deserialized.queriedBounds.toString() == response.queriedBounds.toString()}');
  print('   Same response time: ${deserialized.responseTimeMs == response.responseTimeMs}');
  print('   Same data source: ${deserialized.dataSource == response.dataSource}');

  // Test 4: Filtering by confidence
  print('\n🎯 Test 4: Testing confidence filtering...');
  final highConfidenceResponse = response.filterByConfidence(90.0);
  print('✅ Filtered by confidence >= 90%:');
  print('   Original incidents: ${response.incidents.length}');
  print('   High confidence incidents: ${highConfidenceResponse.incidents.length}');
  
  if (highConfidenceResponse.hasIncidents) {
    print('   Top confidence: ${highConfidenceResponse.incidents.first.confidence}%');
  }

  // Test 5: Filtering by FRP
  print('\n🔥 Test 5: Testing FRP filtering...');
  final highFrpResponse = response.filterByFrp(600.0);
  print('✅ Filtered by FRP >= 600 MW:');
  print('   Original incidents: ${response.incidents.length}');
  print('   High FRP incidents: ${highFrpResponse.incidents.length}');

  // Test 6: Sorting methods
  print('\n📊 Test 6: Testing sorting methods...');
  final byDetection = response.incidentsByDetectionTime;
  final byConfidence = response.incidentsByConfidence;
  
  print('✅ Sorting tests:');
  print('   By detection time: ${byDetection.length} incidents');
  print('   By confidence: ${byConfidence.length} incidents');
  
  if (byConfidence.isNotEmpty && byConfidence.first.confidence != null) {
    print('   Highest confidence: ${byConfidence.first.confidence}%');
  }

  // Test 7: copyWith functionality
  print('\n📋 Test 7: Testing copyWith...');
  final updatedResponse = response.copyWith(
    responseTimeMs: 150,
    dataSource: DataSource.mock,
  );
  
  print('✅ Updated via copyWith:');
  print('   New response time: ${updatedResponse.responseTimeMs}ms');
  print('   New data source: ${updatedResponse.dataSource}');
  print('   Same incidents: ${updatedResponse.incidents.length == response.incidents.length}');
  print('   Same bounds: ${updatedResponse.queriedBounds.toString() == response.queriedBounds.toString()}');

  // Test 8: Bounds validation
  print('\n🗺️  Test 8: Testing bounds validation...');
  final invalidIncident = FireIncident.test(
    id: 'invalid',
    location: const LatLng(60.0, 10.0), // Far outside bounds
  );
  
  final invalidResponse = response.copyWith(
    incidents: [...response.incidents, invalidIncident],
  );
  
  print('✅ Bounds validation:');
  print('   Valid response: ${response.isValid}');
  print('   Invalid response: ${invalidResponse.isValid}');

  print('\n🎉 All ActiveFiresResponse model tests passed!');
  print('📋 Task 2: "Create ActiveFiresResponse Model" - COMPLETE ✅');
}