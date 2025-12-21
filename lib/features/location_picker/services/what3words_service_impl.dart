import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:wildfire_mvp_v3/config/feature_flags.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/models/what3words_models.dart';
import 'package:wildfire_mvp_v3/utils/location_utils.dart';
import 'what3words_service.dart';

/// Implementation of [What3wordsService] using the what3words REST API
///
/// API documentation: https://developer.what3words.com/public-api/docs
/// Rate limits: 500 requests/minute for free tier
class What3wordsServiceImpl implements What3wordsService {
  static const String _baseUrl = 'https://api.what3words.com/v3';
  static const Duration _timeout = Duration(seconds: 10);

  final http.Client _client;
  final String _apiKey;

  What3wordsServiceImpl({http.Client? client, String? apiKey})
    : _client = client ?? http.Client(),
      _apiKey = apiKey ?? FeatureFlags.what3wordsApiKey;

  @override
  Future<Either<What3wordsError, What3wordsAddress>> convertTo3wa({
    required double lat,
    required double lon,
  }) async {
    if (_apiKey.isEmpty) {
      return const Left(
        What3wordsApiError(
          code: 'NoApiKey',
          message: 'what3words API key not configured',
        ),
      );
    }

    final url = Uri.parse(
      '$_baseUrl/convert-to-3wa',
    ).replace(queryParameters: {'coordinates': '$lat,$lon', 'key': _apiKey});

    debugPrint(
      'What3words: Converting ${LocationUtils.logRedact(lat, lon)} to address',
    );

    try {
      final response = await _client.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;

        if (json.containsKey('error')) {
          final error = json['error'] as Map<String, dynamic>;
          return Left(
            What3wordsApiError(
              code: error['code'] as String? ?? 'Unknown',
              message: error['message'] as String? ?? 'Unknown API error',
            ),
          );
        }

        final words = json['words'] as String?;
        if (words == null) {
          return const Left(
            What3wordsApiError(
              code: 'InvalidResponse',
              message: 'Invalid response: missing words',
            ),
          );
        }

        final address = What3wordsAddress.tryParse(words);
        if (address == null) {
          return Left(What3wordsInvalidAddressError(words));
        }

        debugPrint('What3words: Resolved to ${address.words}');
        return Right(address);
      } else if (response.statusCode == 401) {
        return const Left(
          What3wordsApiError(
            code: 'InvalidKey',
            message: 'Invalid API key',
            statusCode: 401,
          ),
        );
      } else if (response.statusCode == 429) {
        return const Left(
          What3wordsApiError(
            code: 'QuotaExceeded',
            message: 'Rate limit exceeded',
            statusCode: 429,
          ),
        );
      } else {
        return Left(
          What3wordsApiError(
            code: 'HttpError',
            message: 'API error: ${response.statusCode}',
            statusCode: response.statusCode,
          ),
        );
      }
    } on http.ClientException catch (e) {
      debugPrint('What3words: Network error - $e');
      return Left(What3wordsNetworkError(e.message));
    } catch (e) {
      debugPrint('What3words: Unexpected error - $e');
      return Left(What3wordsNetworkError(e.toString()));
    }
  }

  @override
  Future<Either<What3wordsError, LatLng>> convertToCoordinates({
    required String words,
  }) async {
    if (_apiKey.isEmpty) {
      return const Left(
        What3wordsApiError(
          code: 'NoApiKey',
          message: 'what3words API key not configured',
        ),
      );
    }

    // Validate format before API call
    final address = What3wordsAddress.tryParse(words);
    if (address == null) {
      return Left(What3wordsInvalidAddressError(words));
    }

    final url = Uri.parse(
      '$_baseUrl/convert-to-coordinates',
    ).replace(queryParameters: {'words': address.words, 'key': _apiKey});

    debugPrint('What3words: Converting ${address.words} to coordinates');

    try {
      final response = await _client.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;

        if (json.containsKey('error')) {
          final error = json['error'] as Map<String, dynamic>;
          final code = error['code'] as String?;

          // Specific error handling for "not found" addresses
          if (code == 'BadWords') {
            return Left(What3wordsInvalidAddressError(words));
          }

          return Left(
            What3wordsApiError(
              code: code ?? 'Unknown',
              message: error['message'] as String? ?? 'Unknown API error',
            ),
          );
        }

        final coords = json['coordinates'] as Map<String, dynamic>?;
        if (coords == null) {
          return const Left(
            What3wordsApiError(
              code: 'InvalidResponse',
              message: 'Invalid response: missing coordinates',
            ),
          );
        }

        final lat = (coords['lat'] as num?)?.toDouble();
        final lng = (coords['lng'] as num?)?.toDouble();

        if (lat == null || lng == null) {
          return const Left(
            What3wordsApiError(
              code: 'InvalidResponse',
              message: 'Invalid response: missing lat/lng',
            ),
          );
        }

        debugPrint(
          'What3words: Resolved to ${LocationUtils.logRedact(lat, lng)}',
        );
        return Right(LatLng(lat, lng));
      } else if (response.statusCode == 401) {
        return const Left(
          What3wordsApiError(
            code: 'InvalidKey',
            message: 'Invalid API key',
            statusCode: 401,
          ),
        );
      } else if (response.statusCode == 429) {
        return const Left(
          What3wordsApiError(
            code: 'QuotaExceeded',
            message: 'Rate limit exceeded',
            statusCode: 429,
          ),
        );
      } else {
        return Left(
          What3wordsApiError(
            code: 'HttpError',
            message: 'API error: ${response.statusCode}',
            statusCode: response.statusCode,
          ),
        );
      }
    } on http.ClientException catch (e) {
      debugPrint('What3words: Network error - $e');
      return Left(What3wordsNetworkError(e.message));
    } catch (e) {
      debugPrint('What3words: Unexpected error - $e');
      return Left(What3wordsNetworkError(e.toString()));
    }
  }
}
