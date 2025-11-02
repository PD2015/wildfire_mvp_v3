import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../services/models/fire_risk.dart';
import '../models/risk_level.dart';
import '../theme/risk_palette.dart';
import '../utils/time_format.dart';
import 'badges/cached_badge.dart';

// Visual tokens for consistent banner styling
const double kBannerRadius = 16.0;
const EdgeInsets kBannerPadding = EdgeInsets.all(16.0);
const double kBannerElevation = 2.0;

/// Configuration class for RiskBanner widget features
class RiskBannerConfig extends Equatable {
  /// Whether to show the weather panel
  final bool showWeatherPanel;

  const RiskBannerConfig({this.showWeatherPanel = false});

  @override
  List<Object?> get props => [showWeatherPanel];
}

/// State representation for the RiskBanner widget
sealed class RiskBannerState extends Equatable {
  const RiskBannerState();

  @override
  List<Object?> get props => [];
}

/// Initial loading state
class RiskBannerLoading extends RiskBannerState {
  const RiskBannerLoading();
}

/// Success state with fire risk data
class RiskBannerSuccess extends RiskBannerState {
  final FireRisk data;

  const RiskBannerSuccess(this.data);

  @override
  List<Object?> get props => [data];
}

/// Error state with optional cached data
class RiskBannerError extends RiskBannerState {
  final String message;
  final FireRisk? cached;

  const RiskBannerError(this.message, {this.cached});

  @override
  List<Object?> get props => [message, cached];
}

/// RiskBanner widget that displays wildfire risk information
///
/// This is a pure StatelessWidget that consumes RiskBannerState without
/// performing any data fetching. It handles all UI states: loading, success,
/// and error with proper accessibility support.
class RiskBanner extends StatelessWidget {
  /// Current state of the risk banner
  final RiskBannerState state;

  /// Optional callback for retry action in error states
  final VoidCallback? onRetry;

  /// Optional location label for coordinate display
  final String? locationLabel;

  /// Configuration for banner features
  final RiskBannerConfig config;

  const RiskBanner({
    super.key,
    required this.state,
    this.onRetry,
    this.locationLabel,
    this.config = const RiskBannerConfig(),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 44.0,
      ), // A11y minimum touch target
      child: switch (state) {
        RiskBannerLoading() => _buildLoadingState(),
        RiskBannerSuccess(:final data) => _buildSuccessState(data),
        RiskBannerError(:final message, :final cached) => _buildErrorState(
            message,
            cached,
          ),
      },
    );
  }

  /// Builds the loading state with progress indicator
  Widget _buildLoadingState() {
    return Semantics(
      label: 'Loading wildfire risk data',
      child: const Card(
        elevation: kBannerElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(kBannerRadius)),
        ),
        color: RiskPalette.lightGray,
        child: Padding(
          padding: kBannerPadding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20.0,
                height: 20.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    RiskPalette.midGray,
                  ),
                ),
              ),
              SizedBox(width: 12.0),
              Text(
                'Loading wildfire risk...',
                style: TextStyle(color: RiskPalette.midGray, fontSize: 16.0),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the success state with risk level display
  Widget _buildSuccessState(FireRisk data) {
    final levelName = _getRiskLevelName(data.level);
    final backgroundColor = _getRiskLevelColor(data.level);
    final textColor = _getTextColor(backgroundColor);
    final sourceName = _getSourceName(data.source);

    final timeText =
        'Updated ${formatRelativeTime(utcNow: DateTime.now().toUtc(), updatedUtc: data.observedAt)}';

    return Semantics(
      label:
          'Current wildfire risk $levelName, $timeText, data from $sourceName',
      child: Card(
        elevation: kBannerElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kBannerRadius),
        ),
        color: backgroundColor,
        child: Padding(
          padding: kBannerPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main risk level title
              Text(
                'Wildfire Risk: ${levelName.toUpperCase()}',
                style: TextStyle(
                  color: textColor,
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8.0),

              // Location row (if locationLabel is provided)
              if (locationLabel != null) ...[
                Row(
                  children: [
                    Icon(Icons.location_on, color: textColor, size: 16.0),
                    const SizedBox(width: 4.0),
                    Expanded(
                      child: Text(
                        locationLabel!,
                        style: TextStyle(color: textColor, fontSize: 14.0),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
              ],

              // Timestamp
              Text(
                timeText,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.8),
                  fontSize: 14.0,
                ),
              ),

              const SizedBox(height: 4.0),

              // Data Source as plain text
              Text(
                'Data Source: $sourceName',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.8),
                  fontSize: 14.0,
                ),
              ),

              // Cached badge if applicable
              if (data.freshness == Freshness.cached) ...[
                const SizedBox(height: 8.0),
                const CachedBadge(),
              ],

              // Weather panel (if enabled)
              if (config.showWeatherPanel) ...[
                const SizedBox(height: 12.0),
                _buildWeatherPanel(textColor),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the weather panel with placeholder values
  Widget _buildWeatherPanel(Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(kBannerRadius - 4.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildWeatherItem('Temperature', '18°C', textColor),
          _buildWeatherItem('Humidity', '65%', textColor),
          _buildWeatherItem('Wind Speed', '12 mph', textColor),
        ],
      ),
    );
  }

  /// Builds individual weather items
  Widget _buildWeatherItem(String label, String value, Color textColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          label,
          style: TextStyle(
            color: textColor.withValues(alpha: 0.8),
            fontSize: 12.0,
          ),
        ),
      ],
    );
  }

  /// Builds the error state with retry option
  Widget _buildErrorState(String message, FireRisk? cached) {
    if (cached != null) {
      // Show cached data with error indication
      return _buildErrorWithCachedData(message, cached);
    } else {
      // Show error message with retry option
      return _buildErrorWithoutCachedData(message);
    }
  }

  /// Builds error state when cached data is available
  Widget _buildErrorWithCachedData(String message, FireRisk cached) {
    final levelName = _getRiskLevelName(cached.level);
    final backgroundColor = _getRiskLevelColor(
      cached.level,
    ).withValues(alpha: 0.6);
    final textColor = _getTextColor(backgroundColor);
    final sourceName = _getSourceName(cached.source);
    final timeText =
        'Updated ${formatRelativeTime(utcNow: DateTime.now().toUtc(), updatedUtc: cached.observedAt)}';

    return Semantics(
      label:
          'Error loading current data, showing cached $levelName wildfire risk from $timeText',
      child: Card(
        elevation: kBannerElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kBannerRadius),
          side: const BorderSide(color: RiskPalette.midGray, width: 2.0),
        ),
        color: backgroundColor,
        child: Padding(
          padding: kBannerPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error indicator
              const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: RiskPalette.midGray,
                    size: 20.0,
                  ),
                  SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      'Unable to load current data',
                      style: TextStyle(
                        color: RiskPalette.midGray,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8.0),

              // Cached risk level
              Text(
                'Wildfire Risk: ${levelName.toUpperCase()}',
                style: TextStyle(
                  color: textColor,
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8.0),

              // Location row (if locationLabel is provided)
              if (locationLabel != null) ...[
                Row(
                  children: [
                    Icon(Icons.location_on, color: textColor, size: 16.0),
                    const SizedBox(width: 4.0),
                    Expanded(
                      child: Text(
                        locationLabel!,
                        style: TextStyle(color: textColor, fontSize: 14.0),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
              ],

              // Timestamp
              Text(
                timeText,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.8),
                  fontSize: 14.0,
                ),
              ),

              const SizedBox(height: 4.0),

              // Data Source as plain text
              Text(
                'Data Source: $sourceName',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.8),
                  fontSize: 14.0,
                ),
              ),

              const SizedBox(height: 8.0),

              // Cached badge
              const CachedBadge(),

              const SizedBox(height: 12.0),

              // Retry button
              if (onRetry != null)
                SizedBox(
                  height: 44.0, // A11y minimum touch target
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 18.0),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RiskPalette.blueAccent,
                      foregroundColor: RiskPalette.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds error state when no cached data is available
  Widget _buildErrorWithoutCachedData(String message) {
    return Semantics(
      label: 'Unable to load wildfire risk data',
      child: Card(
        elevation: kBannerElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kBannerRadius),
          side: const BorderSide(color: RiskPalette.midGray, width: 1.0),
        ),
        color: RiskPalette.lightGray,
        child: Padding(
          padding: kBannerPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: RiskPalette.midGray,
                    size: 24.0,
                  ),
                  SizedBox(width: 12.0),
                  Expanded(
                    child: Text(
                      'Unable to load wildfire risk data',
                      style: TextStyle(
                        color: RiskPalette.darkGray,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8.0),

              Text(
                message,
                style: const TextStyle(
                  color: RiskPalette.midGray,
                  fontSize: 14.0,
                ),
              ),

              const SizedBox(height: 12.0),

              // Retry button
              if (onRetry != null)
                SizedBox(
                  height: 44.0, // A11y minimum touch target
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh, size: 18.0),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RiskPalette.blueAccent,
                      foregroundColor: RiskPalette.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Gets the display name for a risk level
  String _getRiskLevelName(RiskLevel level) {
    return switch (level) {
      RiskLevel.veryLow => 'Very Low',
      RiskLevel.low => 'Low',
      RiskLevel.moderate => 'Moderate',
      RiskLevel.high => 'High',
      RiskLevel.veryHigh => 'Very High',
      RiskLevel.extreme => 'Extreme',
    };
  }

  /// Gets the background color for a risk level using RiskPalette
  Color _getRiskLevelColor(RiskLevel level) {
    return switch (level) {
      RiskLevel.veryLow => RiskPalette.veryLow,
      RiskLevel.low => RiskPalette.low,
      RiskLevel.moderate => RiskPalette.moderate,
      RiskLevel.high => RiskPalette.high,
      RiskLevel.veryHigh => RiskPalette.veryHigh,
      RiskLevel.extreme => RiskPalette.extreme,
    };
  }

  /// Gets appropriate text color based on background color
  Color _getTextColor(Color backgroundColor) {
    // Use luminance to determine if we need dark or light text
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? RiskPalette.darkGray : RiskPalette.white;
  }

  /// Gets the display name for a data source
  String _getSourceName(DataSource source) {
    return switch (source) {
      DataSource.effis => 'EFFIS',
      DataSource.sepa => 'SEPA',
      DataSource.cache => 'Cache',
      DataSource.mock => 'Mock',
    };
  }
}
