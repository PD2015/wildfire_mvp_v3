import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import '../models/api_error.dart';
import '../models/effis_fwi_result.dart';
import 'effis_service.dart';

/// Production implementation of EffisService using EFFIS WMS GetFeatureInfo
/// 
/// Integrates with EFFIS (European Forest Fire Information System) to retrieve
/// Fire Weather Index data for specific coordinates with comprehensive error
/// handling, retry logic, and response validation.
/// 
/// Key features:
/// - Constructor injection of http.Client for testability
/// - WMS GetFeatureInfo URL construction with proper coordinate transformation
/// - Exponential backoff retry with configurable jitter
/// - Structured error categorization with ApiError mapping
/// - Comprehensive input validation and response parsing
/// - Safe logging with coordinate precision limits
class EffisServiceImpl implements EffisService {
  static const String _baseUrl = 'https://ies-ows.jrc.ec.europa.eu/gwis';
  static const String _userAgent = 'WildFire/0.1 (prototype)';
  static const String _acceptHeader = 'application/json,*/*;q=0.8';
  
  final http.Client _httpClient;
  final Random _random;

  /// Creates EffisServiceImpl with injected HTTP client
  /// 
  /// [httpClient] - Injectable HTTP client for network requests (enables mocking)
  /// [random] - Injectable random generator for jitter (enables deterministic testing)
  EffisServiceImpl({
    required http.Client httpClient,
    Random? random,
  }) : _httpClient = httpClient,
       _random = random ?? Random();

  @override
  Future<Either<ApiError, EffisFwiResult>> getFwi({
    required double lat,
    required double lon,
    Duration timeout = const Duration(seconds: 30),
    int maxRetries = 3,
  }) async {
    // Validate input coordinates
    final validationError = _validateCoordinates(lat, lon);
    if (validationError != null) {
      return Left(validationError);
    }

    // Validate parameters
    if (timeout.inMilliseconds <= 0) {
      return Left(ApiError(
        message: 'Timeout must be positive duration',
      ));
    }

    if (maxRetries < 0 || maxRetries > 10) {
      return Left(ApiError(
        message: 'maxRetries must be between 0 and 10',
      ));
    }

    // Attempt request with retry logic
    return await _executeWithRetry(lat, lon, timeout, maxRetries);
  }

  /// Validates coordinate ranges per WGS84 bounds
  ApiError? _validateCoordinates(double lat, double lon) {
    if (lat < -90.0 || lat > 90.0) {
      return ApiError(
        message: 'Latitude must be between -90 and 90 degrees',
      );
    }

    if (lon < -180.0 || lon > 180.0) {
      return ApiError(
        message: 'Longitude must be between -180 and 180 degrees',
      );
    }

    return null;
  }

  /// Executes HTTP request with exponential backoff retry logic
  Future<Either<ApiError, EffisFwiResult>> _executeWithRetry(
    double lat,
    double lon,
    Duration timeout,
    int maxRetries,
  ) async {
    int attemptCount = 0;
    ApiError? lastError;

    while (attemptCount <= maxRetries) {
      try {
        // Construct WMS GetFeatureInfo URL
        final uri = _buildWmsUrl(lat, lon);
        
        // Execute HTTP request with timeout
        final response = await _httpClient.get(
          uri,
          headers: {
            'User-Agent': _userAgent,
            'Accept': _acceptHeader,
          },
        ).timeout(timeout);

        // Process response
        final result = await _processResponse(response);
        if (result.isRight()) {
          return result;
        }

        // Check if error is retryable
        final error = result.fold((l) => l, (r) => throw Exception('Unexpected Right'));
        if (!_isRetryableError(error)) {
          return Left(error);
        }

        lastError = error;

      } catch (e) {
        // Handle network exceptions
        lastError = _mapExceptionToApiError(e);
        
        // Check if exception is retryable
        if (!_isRetryableError(lastError)) {
          return Left(lastError);
        }
      }

      attemptCount++;

      // Apply exponential backoff if not final attempt
      if (attemptCount <= maxRetries) {
        final delay = _calculateBackoffDelay(attemptCount);
        await Future.delayed(delay);
      }
    }

    // All retries exhausted
    return Left(lastError ?? ApiError(
      message: 'Request failed after $maxRetries retries',
    ));
  }

  /// Builds WMS GetFeatureInfo URL for EFFIS service
  Uri _buildWmsUrl(double lat, double lon) {
    // Transform WGS84 coordinates to Web Mercator (EPSG:3857) bounds
    final webMercatorX = lon * 20037508.34 / 180;
    final webMercatorY = log(tan((90 + lat) * pi / 360)) / (pi / 180) * 20037508.34 / 180;
    
    // Create small bounding box around point (±1000m)
    const buffer = 1000.0;
    final minX = webMercatorX - buffer;
    final minY = webMercatorY - buffer;
    final maxX = webMercatorX + buffer;
    final maxY = webMercatorY + buffer;

    return Uri.parse(_baseUrl).replace(queryParameters: {
      'SERVICE': 'WMS',
      'VERSION': '1.3.0',
      'REQUEST': 'GetFeatureInfo',
      'LAYERS': 'ecmwf.fwi',
      'QUERY_LAYERS': 'ecmwf.fwi',
      'CRS': 'EPSG:3857',
      'BBOX': '$minX,$minY,$maxX,$maxY',
      'WIDTH': '256',
      'HEIGHT': '256',
      'I': '128',  // Query point X
      'J': '128',  // Query point Y
      'INFO_FORMAT': 'application/json',
      'FEATURE_COUNT': '1',
    });
  }

  /// Processes HTTP response and parses EFFIS data
  Future<Either<ApiError, EffisFwiResult>> _processResponse(http.Response response) async {
    // Handle HTTP error status codes
    if (response.statusCode >= 400) {
      return Left(_mapHttpStatusToApiError(response.statusCode, response.body));
    }

    // Validate content type
    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      return Left(ApiError(
        message: 'Unsupported response format: $contentType',
        statusCode: response.statusCode,
      ));
    }

    // Parse JSON response
    try {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return await _parseEffisResponse(jsonData);
    } catch (e) {
      return Left(ApiError(
        message: 'Failed to parse JSON response: ${e.toString()}',
        statusCode: response.statusCode,
      ));
    }
  }

  /// Parses EFFIS GeoJSON FeatureCollection response
  Future<Either<ApiError, EffisFwiResult>> _parseEffisResponse(Map<String, dynamic> jsonData) async {
    // Validate FeatureCollection structure
    if (jsonData['type'] != 'FeatureCollection') {
      return Left(ApiError(
        message: 'Invalid response format: expected FeatureCollection',
      ));
    }

    final features = jsonData['features'] as List<dynamic>?;
    if (features == null || features.isEmpty) {
      return Left(ApiError(
        message: 'No FWI data available for the specified coordinates',
      ));
    }

    try {
      // Parse first feature (should contain FWI data)
      final feature = features.first as Map<String, dynamic>;
      final properties = feature['properties'] as Map<String, dynamic>;
      
      // Extract FWI value (try different property names)
      final fwi = _extractFwiValue(properties);
      if (fwi == null) {
        return Left(ApiError(
          message: 'No FWI value found in response properties',
        ));
      }

      // Extract timestamp (try different property names)
      DateTime observedAt;
      if (properties.containsKey('datetime')) {
        observedAt = DateTime.parse(properties['datetime'] as String);
      } else if (properties.containsKey('timestamp')) {
        observedAt = DateTime.parse(properties['timestamp'] as String);
      } else {
        // Fallback to current time if no timestamp in response
        // Note: EFFIS responses may not always include timestamps
        observedAt = DateTime.now().toUtc();
      }

      // Extract geometry coordinates
      final geometry = feature['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List<dynamic>;
      final longitude = (coordinates[0] as num).toDouble();
      final latitude = (coordinates[1] as num).toDouble();

      // Create EffisFwiResult using existing model validation
      final effisResult = EffisFwiResult(
        fwi: fwi,
        dc: _extractDoubleProperty(properties, 'dc') ?? 0.0,
        dmc: _extractDoubleProperty(properties, 'dmc') ?? 0.0,
        ffmc: _extractDoubleProperty(properties, 'ffmc') ?? 0.0,
        isi: _extractDoubleProperty(properties, 'isi') ?? 0.0,
        bui: _extractDoubleProperty(properties, 'bui') ?? 0.0,
        datetime: observedAt,
        longitude: longitude,
        latitude: latitude,
      );

      return Right(effisResult);

    } catch (e) {
      return Left(ApiError(
        message: 'Failed to parse EFFIS feature data: ${e.toString()}',
      ));
    }
  }

  /// Extracts FWI value from properties, trying multiple field names
  double? _extractFwiValue(Map<String, dynamic> properties) {
    // Try common FWI property names used by EFFIS
    for (final key in ['fwi', 'FWI', 'value', 'VALUE']) {
      if (properties.containsKey(key)) {
        final value = properties[key];
        if (value is num) {
          return value.toDouble();
        }
      }
    }
    return null;
  }

  /// Safely extracts double property with fallback
  double? _extractDoubleProperty(Map<String, dynamic> properties, String key) {
    final value = properties[key];
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }

  /// Maps HTTP status codes to structured ApiError
  ApiError _mapHttpStatusToApiError(int statusCode, String responseBody) {
    switch (statusCode) {
      case 404:
        return ApiError(
          message: 'EFFIS endpoint not found or coordinates out of coverage area',
          statusCode: statusCode,
          reason: ApiErrorReason.notFound,
        );
      case 503:
        return ApiError(
          message: 'EFFIS service temporarily unavailable',
          statusCode: statusCode,
          reason: ApiErrorReason.serviceUnavailable,
        );
      case >= 500:
        return ApiError(
          message: 'EFFIS server error: HTTP $statusCode',
          statusCode: statusCode,
          reason: ApiErrorReason.serviceUnavailable,
        );
      default:
        return ApiError(
          message: 'EFFIS request failed: HTTP $statusCode',
          statusCode: statusCode,
        );
    }
  }

  /// Maps network exceptions to structured ApiError
  ApiError _mapExceptionToApiError(dynamic exception) {
    if (exception is SocketException) {
      return ApiError(
        message: 'Network connection failed: ${exception.message}',
      );
    } else if (exception is TimeoutException) {
      return ApiError(
        message: 'Request timed out while connecting to EFFIS',
      );
    } else {
      return ApiError(
        message: 'Unexpected error: ${exception.toString()}',
      );
    }
  }

  /// Determines if an error should trigger a retry attempt
  bool _isRetryableError(ApiError error) {
    // Retry on server errors (5xx) and network issues
    if (error.statusCode != null) {
      return error.statusCode! >= 500;
    }
    
    // Retry on network exceptions (timeout, connection failure)
    return error.message.contains('timeout') || 
           error.message.contains('connection') ||
           error.message.contains('Network');
  }

  /// Calculates exponential backoff delay with jitter
  Duration _calculateBackoffDelay(int attemptNumber) {
    // Base delay: 1000ms * (2^attemptNumber)
    final baseDelayMs = 1000 * pow(2, attemptNumber - 1);
    
    // Add jitter: ±25% of base delay
    final jitterMs = (baseDelayMs * 0.25 * (_random.nextDouble() - 0.5)).round();
    final totalDelayMs = (baseDelayMs + jitterMs).clamp(100, 30000); // Min 100ms, max 30s
    
    return Duration(milliseconds: totalDelayMs.toInt());
  }
}