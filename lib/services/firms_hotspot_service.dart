import 'dart:async';
import 'dart:developer' as developer;
import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import '../models/api_error.dart';
import '../models/hotspot.dart';
import '../models/lat_lng_bounds.dart';
import '../models/location_models.dart';
import '../models/fire_data_mode.dart';
import 'hotspot_service.dart';
import 'utils/geo_utils.dart';

/// NASA FIRMS REST API service for hotspot data
///
/// Primary data source for VIIRS hotspot detections.
/// Uses simple REST API with CSV response format for efficiency.
///
/// FIRMS provides the same underlying VIIRS satellite data as GWIS,
/// but via a more mobile-friendly REST API with bounding box queries.
///
/// API Documentation: https://firms.modaps.eosdis.nasa.gov/api/area
///
/// Part of 021-live-fire-data feature implementation.
class FirmsHotspotService implements HotspotService {
  /// FIRMS Area API base URL
  static const String _baseUrl =
      'https://firms.modaps.eosdis.nasa.gov/api/area';

  /// User-Agent header for FIRMS requests
  static const String _userAgent = 'WildFire/0.1 (prototype)';

  final String _apiKey;
  final http.Client _httpClient;

  /// Creates FirmsHotspotService with injected dependencies
  ///
  /// [apiKey] - NASA FIRMS MAP_KEY (get from firms.modaps.eosdis.nasa.gov/api/map_key/)
  /// [httpClient] - Injectable HTTP client for network requests
  FirmsHotspotService({required String apiKey, required http.Client httpClient})
    : _apiKey = apiKey,
      _httpClient = httpClient;

  @override
  String get serviceName => 'NASA FIRMS';

  @override
  Future<Either<ApiError, List<Hotspot>>> getHotspots({
    required LatLngBounds bounds,
    required HotspotTimeFilter timeFilter,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    // Validate API key
    if (_apiKey.isEmpty) {
      return Left(ApiError(message: 'FIRMS API key not configured'));
    }

    // Validate timeout
    if (timeout.inMilliseconds <= 0) {
      return Left(ApiError(message: 'Timeout must be positive duration'));
    }

    final sw = bounds.southwest;
    final ne = bounds.northeast;

    // C2 compliance: Log at 2dp only
    developer.log(
      'FirmsHotspotService: Fetching ${timeFilter.name} hotspots for bounds '
      '${GeographicUtils.logRedact(sw.latitude, sw.longitude)} to '
      '${GeographicUtils.logRedact(ne.latitude, ne.longitude)}',
      name: 'FirmsHotspotService',
    );

    // Build FIRMS Area API URL
    // Format: /api/area/csv/{MAP_KEY}/{SOURCE}/{west},{south},{east},{north}/{days}
    final days = timeFilter == HotspotTimeFilter.today ? 1 : 7;
    final url =
        '$_baseUrl/csv/$_apiKey/VIIRS_SNPP_NRT/'
        '${sw.longitude},${sw.latitude},${ne.longitude},${ne.latitude}/$days';

    developer.log(
      'FirmsHotspotService: Request URL (domain only): ${Uri.parse(url).host}',
      name: 'FirmsHotspotService',
    );

    try {
      final response = await _httpClient
          .get(Uri.parse(url), headers: {'User-Agent': _userAgent})
          .timeout(timeout);

      if (response.statusCode == 200) {
        return _parseCsvResponse(response.body);
      }

      // Handle error responses
      if (response.statusCode == 401 || response.statusCode == 403) {
        return Left(
          ApiError(
            message: 'FIRMS API key invalid or expired',
            statusCode: response.statusCode,
          ),
        );
      }

      if (response.statusCode == 429) {
        return Left(
          ApiError(
            message: 'FIRMS rate limit exceeded',
            statusCode: response.statusCode,
          ),
        );
      }

      return Left(
        ApiError(
          message: 'FIRMS request failed with status ${response.statusCode}',
          statusCode: response.statusCode,
        ),
      );
    } on TimeoutException {
      return Left(ApiError(message: 'FIRMS request timed out'));
    } catch (e) {
      return Left(ApiError(message: 'FIRMS request failed: $e'));
    }
  }

  /// Parse FIRMS CSV response to list of hotspots
  ///
  /// CSV columns (VIIRS S-NPP NRT):
  /// latitude,longitude,bright_ti4,scan,track,acq_date,acq_time,
  /// satellite,instrument,confidence,version,bright_ti5,frp,daynight
  Either<ApiError, List<Hotspot>> _parseCsvResponse(String csv) {
    try {
      final lines = csv.split('\n');
      if (lines.isEmpty) {
        developer.log(
          'FirmsHotspotService: Empty response',
          name: 'FirmsHotspotService',
        );
        return const Right([]);
      }

      // Parse header row
      final headers = lines.first.split(',').map((h) => h.trim()).toList();

      // Find required column indices
      final latIdx = headers.indexOf('latitude');
      final lonIdx = headers.indexOf('longitude');
      final dateIdx = headers.indexOf('acq_date');
      final timeIdx = headers.indexOf('acq_time');
      final frpIdx = headers.indexOf('frp');
      final confIdx = headers.indexOf('confidence');

      // Validate required columns exist
      if (latIdx == -1 || lonIdx == -1) {
        return Left(
          ApiError(
            message:
                'FIRMS response missing required columns (latitude, longitude)',
          ),
        );
      }

      final hotspots = <Hotspot>[];

      // Parse data rows (skip header)
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final values = line.split(',');
        if (values.length < headers.length) continue;

        try {
          final lat = double.parse(values[latIdx]);
          final lon = double.parse(values[lonIdx]);

          // Parse date/time
          final acqDate = dateIdx >= 0 ? values[dateIdx] : '';
          final acqTime = timeIdx >= 0 ? values[timeIdx] : '0000';
          final detectedAt = _parseAcquisitionDateTime(acqDate, acqTime);

          // Parse FRP (Fire Radiative Power)
          final frp = frpIdx >= 0
              ? double.tryParse(values[frpIdx]) ?? 0.0
              : 0.0;

          // Parse confidence (FIRMS uses: l=low, n=nominal, h=high)
          final confStr = confIdx >= 0 ? values[confIdx] : 'n';
          final confidence = _parseConfidence(confStr);

          // Generate unique ID from coordinates and time
          final id =
              'firms_${lat.toStringAsFixed(5)}_${lon.toStringAsFixed(5)}_'
              '${detectedAt.millisecondsSinceEpoch}';

          hotspots.add(
            Hotspot(
              id: id,
              location: LatLng(lat, lon),
              detectedAt: detectedAt,
              frp: frp,
              confidence: confidence,
            ),
          );
        } catch (e) {
          // Skip malformed rows but continue parsing
          developer.log(
            'FirmsHotspotService: Skipping malformed row $i: $e',
            name: 'FirmsHotspotService',
          );
        }
      }

      developer.log(
        'FirmsHotspotService: Parsed ${hotspots.length} hotspots',
        name: 'FirmsHotspotService',
      );

      return Right(hotspots);
    } catch (e) {
      return Left(ApiError(message: 'Failed to parse FIRMS CSV response: $e'));
    }
  }

  /// Parse FIRMS date/time strings to DateTime
  ///
  /// FIRMS format: acq_date = "2025-07-15", acq_time = "1345" (HHMM)
  DateTime _parseAcquisitionDateTime(String date, String time) {
    try {
      if (date.isEmpty) return DateTime.now().toUtc();

      final parts = date.split('-');
      if (parts.length != 3) return DateTime.now().toUtc();

      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      // Parse time as HHMM format
      final hour = time.length >= 2
          ? int.tryParse(time.substring(0, 2)) ?? 0
          : 0;
      final minute = time.length >= 4
          ? int.tryParse(time.substring(2, 4)) ?? 0
          : 0;

      return DateTime.utc(year, month, day, hour, minute);
    } catch (e) {
      return DateTime.now().toUtc();
    }
  }

  /// Parse FIRMS confidence string to percentage
  ///
  /// FIRMS uses: 'l' (low), 'n' (nominal), 'h' (high)
  /// Can also be numeric 0-100
  double _parseConfidence(String confidence) {
    final trimmed = confidence.trim().toLowerCase();
    switch (trimmed) {
      case 'l':
      case 'low':
        return 25.0;
      case 'n':
      case 'nominal':
        return 50.0;
      case 'h':
      case 'high':
        return 85.0;
      default:
        // Try parsing as number
        return double.tryParse(trimmed)?.clamp(0.0, 100.0) ?? 50.0;
    }
  }
}
