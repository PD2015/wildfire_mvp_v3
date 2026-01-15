import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:wildfire_mvp_v3/widgets/app_bar_actions.dart';
import 'package:wildfire_mvp_v3/widgets/location_card.dart';
import 'package:wildfire_mvp_v3/widgets/location_chip_with_panel.dart';

import '../config/feature_flags.dart';
import '../controllers/home_controller.dart';
import '../models/home_state.dart';
import '../models/location_models.dart';
import '../models/risk_level.dart';
import '../widgets/risk_banner.dart';
import '../widgets/risk_guidance_card.dart';
import '../features/location_picker/models/location_picker_mode.dart';
import '../features/location_picker/models/picked_location.dart';
import '../services/models/fire_risk.dart';
import '../utils/location_utils.dart';

/// Home screen that displays wildfire risk information with user controls
///
/// Features:
/// - RiskBanner integration showing current fire risk status
/// - Retry button for error recovery (disabled during loading)
/// - Manual location entry via A4 ManualLocationDialog
/// - Accessibility compliance (≥44dp touch targets, semantic labels)
/// - Timestamp and source display for transparency (C4)
/// - Loading, success, and error state handling
///
/// Constitutional compliance:
/// - C3: Accessibility with semantic labels and proper touch targets
/// - C4: Transparency with timestamp, source attribution, cached badges
/// - C1: Clean code with proper state management integration
class HomeScreen extends StatefulWidget {
  /// Home screen with required controller dependency injection
  const HomeScreen({super.key, required this.controller});

  /// HomeController for state management and data operations
  final HomeController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeController _controller;

  @override
  void initState() {
    super.initState();

    // Use the provided controller
    _controller = widget.controller;

    // Start initial data load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wildfire Risk'),
        centerTitle: true,
        actions: const [AppBarActions()],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Main risk banner display (includes location chip)
                    _buildRiskBanner(),

                    // Conditionally include action buttons section
                    // Only add spacing when retry button is actually shown
                    if (_controller.state is HomeStateError &&
                        (_controller.state as HomeStateError).canRetry) ...[
                      const SizedBox(height: 16.0),
                      _buildActionButtons(),
                      const SizedBox(height: 16.0),
                    ] else
                      const SizedBox(height: 16.0),

                    // Risk guidance card
                    _buildRiskGuidance(),

                    const SizedBox(height: 16.0),

                    // Additional info based on state
                    _buildStateInfo(),

                    const SizedBox(height: 24.0),

                    // Disclaimer footer
                    _buildDisclaimerFooter(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds the disclaimer footer with emergency info
  ///
  /// Displays legal disclaimer that this app is for information only
  /// and provides emergency contact guidance.
  Widget _buildDisclaimerFooter() {
    return Semantics(
      container: true,
      label: 'App disclaimer',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          'For information only. Dial 999 in an emergency.',
          key: const Key('disclaimer_text'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Builds the main risk banner based on current HomeState
  Widget _buildRiskBanner() {
    final homeState = _controller.state;

    switch (homeState) {
      case HomeStateLoading():
        return RiskBanner(
          state: const RiskBannerLoading(),
          locationChip: _buildLocationChip(),
        );

      case HomeStateSuccess(
          :final riskData,
          :final location,
          :final formattedLocation,
        ):
        // Prefer human-readable location name, fallback to coordinates (C2 compliant)
        final locationLabel = formattedLocation ??
            LocationUtils.logRedact(location.latitude, location.longitude);

        return RiskBanner(
          state: RiskBannerSuccess(riskData),
          locationLabel: locationLabel,
          locationChip: _buildLocationChip(),
        );

      case HomeStateError(
          :final errorMessage,
          :final cachedData,
          :final cachedLocation,
        ):
        // Format cached location with privacy-compliant 2-decimal precision (C2)
        final locationLabel = cachedLocation != null
            ? LocationUtils.logRedact(
                cachedLocation.latitude,
                cachedLocation.longitude,
              )
            : null;

        return Column(
          children: [
            RiskBanner(
              state: RiskBannerError(errorMessage, cached: cachedData),
              locationLabel: locationLabel,
              locationChip: _buildLocationChip(),
            ),
            if (cachedData != null) ...[
              const SizedBox(height: 8.0),
              _buildCachedDataInfo(cachedData),
            ],
          ],
        );
    }
  }

  /// Builds compact location chip with expandable panel for RiskBanner integration
  ///
  /// Creates a [LocationChipWithPanel] based on current HomeState:
  /// - Loading: Shows chip with cached location (if available) in loading mode
  /// - Success: Shows chip with current location, source, and expandable panel
  /// - Error: Shows chip with cached location (if available) or placeholder
  ///
  /// The chip appears inside the RiskBanner below the RiskScale, allowing
  /// users to see location context without it dominating the visual hierarchy.
  Widget? _buildLocationChip() {
    final state = _controller.state;

    switch (state) {
      case HomeStateLoading(:final lastKnownLocation):
        if (lastKnownLocation == null) {
          // No location to display yet
          return null;
        }
        final coordsLabel = LocationUtils.logRedact(
          lastKnownLocation.latitude,
          lastKnownLocation.longitude,
        );
        return LocationChipWithPanel(
          locationName: coordsLabel,
          coordinatesLabel: coordsLabel,
          locationSource: LocationSource.cached,
          parentBackgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          isLoading: true,
          onChangeLocation: _showManualLocationDialog,
          embeddedInRiskBanner: true,
        );

      case HomeStateSuccess(
          :final riskData,
          :final location,
          :final locationSource,
          :final placeName,
          :final what3words,
          :final formattedLocation,
          :final isWhat3wordsLoading,
        ):
        // Build static map URL for preview
        final staticMapUrl = _buildStaticMapUrl(
          location.latitude,
          location.longitude,
        );

        // Use place name, formatted location, or coordinates as display name
        final coordsLabel = LocationUtils.logRedact(
          location.latitude,
          location.longitude,
        );
        final locationName = placeName ?? formattedLocation ?? coordsLabel;

        return LocationChipWithPanel(
          locationName: locationName,
          coordinatesLabel: coordsLabel,
          locationSource: locationSource,
          formattedLocation: formattedLocation,
          parentBackgroundColor: riskData.level.color,
          what3words: what3words,
          isWhat3wordsLoading: isWhat3wordsLoading,
          staticMapUrl: staticMapUrl,
          onChangeLocation: _showManualLocationDialog,
          onCopyWhat3words: what3words != null
              ? () => _handleCopyWhat3words(what3words)
              : null,
          onUseGps: locationSource == LocationSource.manual
              ? () => _controller.useGpsLocation()
              : null,
          embeddedInRiskBanner: true,
        );

      case HomeStateError(:final cachedLocation, :final cachedData)
          when cachedLocation != null:
        final coordsLabel = LocationUtils.logRedact(
          cachedLocation.latitude,
          cachedLocation.longitude,
        );
        // Use cached risk color if available, otherwise use surface color
        final backgroundColor = cachedData?.level.color ??
            Theme.of(context).colorScheme.surfaceContainerHighest;
        return LocationChipWithPanel(
          locationName: coordsLabel,
          coordinatesLabel: coordsLabel,
          locationSource: LocationSource.cached,
          parentBackgroundColor: backgroundColor,
          onChangeLocation: _showManualLocationDialog,
          embeddedInRiskBanner: true,
        );

      case HomeStateError():
        // No location available in error state
        return null;
    }
  }

  /// Builds cached data indicator for error states with cached data
  Widget _buildCachedDataInfo(FireRisk cachedData) {
    return Semantics(
      label: 'Showing cached data',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cached,
            size: 14.0,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4.0),
          Text(
            'Showing cached data',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  /// Builds action button for retry when in error state
  ///
  /// Returns empty widget when retry is not available.
  /// Location entry is now handled exclusively via LocationCard button.
  Widget _buildActionButtons() {
    final isLoading = _controller.isLoading;
    final homeState = _controller.state;
    final canRetry = homeState is HomeStateError && homeState.canRetry;

    // Hide action buttons when retry is not available
    if (!canRetry) {
      return const SizedBox.shrink();
    }

    // Show full-width retry button
    return Semantics(
      label: isLoading
          ? 'Retry disabled while loading'
          : 'Retry loading fire risk data',
      button: true,
      enabled: !isLoading,
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: isLoading ? null : () => _controller.retry(),
          icon: isLoading
              ? const SizedBox(
                  width: 16.0,
                  height: 16.0,
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                )
              : const Icon(Icons.refresh),
          label: Text(isLoading ? 'Loading...' : 'Retry'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 44.0), // C3: ≥44dp touch target
          ),
        ),
      ),
    );
  }

  /// Builds risk guidance card based on current risk level
  ///
  /// Shows Scotland-specific wildfire safety advice for the current risk level.
  /// Falls back to generic guidance when risk level is unavailable.
  /// Hides completely during loading state for cleaner UX.
  Widget _buildRiskGuidance() {
    final homeState = _controller.state;

    return switch (homeState) {
      // Success state: Show guidance for current risk level
      HomeStateSuccess(:final riskData) => RiskGuidanceCard(
          level: riskData.level,
        ),

      // Error state with cached data: Show guidance for cached risk level
      HomeStateError(:final cachedData) when cachedData != null =>
        RiskGuidanceCard(level: cachedData.level),

      // Error state without cache: Show generic guidance
      HomeStateError() => const RiskGuidanceCard(level: null),

      // Loading state: Hide card completely
      HomeStateLoading() => const SizedBox.shrink(),
    };
  }

  /// Builds additional state-specific information
  Widget _buildStateInfo() {
    final homeState = _controller.state;

    switch (homeState) {
      case HomeStateLoading(:final isRetry, :final startTime):
        final elapsed = DateTime.now().difference(startTime);
        return Semantics(
          liveRegion: true,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16.0,
                    height: 16.0,
                    child: CircularProgressIndicator(strokeWidth: 2.0),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Text(
                      isRetry
                          ? 'Retrying... (${elapsed.inSeconds}s)'
                          : 'Loading fire risk data... (${elapsed.inSeconds}s)',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

      case HomeStateError(:final errorMessage, :final cachedData):
        return Semantics(
          liveRegion: true,
          child: Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unable to load current data',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onErrorContainer,
                                  ),
                        ),
                        if (cachedData == null) ...[
                          const SizedBox(height: 4.0),
                          Text(
                            errorMessage,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onErrorContainer,
                                    ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

      case HomeStateSuccess():
        // No additional info needed for success state
        return const SizedBox.shrink();
    }
  }

  /// Builds a Google Static Maps URL for the given coordinates
  ///
  /// Uses 2-decimal precision for privacy compliance (C2).
  /// Returns null if no API key is configured.
  String? _buildStaticMapUrl(double lat, double lon) {
    final apiKey = FeatureFlags.googleMapsApiKey;
    if (apiKey.isEmpty) {
      return null;
    }

    // Round to 2 decimal places for privacy (C2)
    final roundedLat = (lat * 100).round() / 100;
    final roundedLon = (lon * 100).round() / 100;

    final url =
        Uri.parse('https://maps.googleapis.com/maps/api/staticmap').replace(
      queryParameters: {
        'center': '$roundedLat,$roundedLon',
        'zoom': '14',
        'size': '600x300',
        'markers': 'color:red|$roundedLat,$roundedLon',
        'key': apiKey,
        'scale': '2',
        'maptype': 'roadmap',
      },
    );

    return url.toString();
  }

  /// Handles copying what3words address to clipboard with snackbar feedback
  void _handleCopyWhat3words(String what3words) {
    Clipboard.setData(ClipboardData(text: what3words));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied $what3words to clipboard'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Builds the location card based on current HomeState
  ///
  /// @deprecated This method is no longer used after spec 023 Phase 2 integration.
  /// Location display is now handled by [_buildLocationChip] inside RiskBanner.
  /// Will be removed in Phase 4 cleanup.
  // ignore: unused_element
  Widget _buildLocationCard() {
    final state = _controller.state;

    switch (state) {
      case HomeStateLoading(:final lastKnownLocation, :final isLocationStale):
        // Determine subtitle based on staleness
        String subtitle;
        if (lastKnownLocation != null) {
          subtitle = isLocationStale
              ? 'Using last known location (may be outdated)...'
              : 'Using last known location while we fetch an update...';
        } else {
          subtitle = 'Determining your location…';
        }

        return LocationCard(
          coordinatesLabel: lastKnownLocation != null
              ? LocationUtils.logRedact(
                  lastKnownLocation.latitude,
                  lastKnownLocation.longitude,
                )
              : null,
          subtitle: subtitle,
          isLoading: true,
          onChangeLocation: _showManualLocationDialog,
          locationSource: lastKnownLocation != null
              ? LocationSource.cached
              : null, // No source for "Determining..."
        );

      case HomeStateSuccess(
          :final location,
          :final locationSource,
          :final placeName,
          :final what3words,
          :final formattedLocation,
          :final isWhat3wordsLoading,
          :final isGeocodingLoading,
        ):
        // Build trust-building subtitle with combination approach
        final String subtitle = switch (locationSource) {
          LocationSource.gps => 'Current location (GPS)',
          LocationSource.manual when placeName != null =>
            '$placeName (set by you)',
          LocationSource.manual => 'Your chosen location',
          LocationSource.cached => 'Last known location',
          LocationSource.defaultFallback => 'Default location (Scotland)',
        };

        // Build static map URL for preview
        final staticMapUrl = _buildStaticMapUrl(
          location.latitude,
          location.longitude,
        );

        return LocationCard(
          coordinatesLabel: LocationUtils.logRedact(
            location.latitude,
            location.longitude,
          ),
          subtitle: subtitle,
          onChangeLocation: _showManualLocationDialog,
          locationSource: locationSource,
          // Enhanced properties from T043
          what3words: what3words,
          isWhat3wordsLoading: isWhat3wordsLoading,
          formattedLocation: formattedLocation,
          isGeocodingLoading: isGeocodingLoading,
          staticMapUrl: staticMapUrl,
          onCopyWhat3words: what3words != null
              ? () => _handleCopyWhat3words(what3words)
              : null,
          // onUseGps enables "Use GPS" button when manual location is active
          // When not manual, button shows "Change Location" using onChangeLocation
          onUseGps: locationSource == LocationSource.manual
              ? () => _controller.useGpsLocation()
              : null,
        );

      case HomeStateError(:final cachedLocation) when cachedLocation != null:
        return LocationCard(
          coordinatesLabel: LocationUtils.logRedact(
            cachedLocation.latitude,
            cachedLocation.longitude,
          ),
          subtitle: 'Using last known location (offline)',
          onChangeLocation: _showManualLocationDialog,
          locationSource: LocationSource.cached,
        );

      case HomeStateError():
        return LocationCard(
          coordinatesLabel: null,
          subtitle: 'Location not available. Set a manual location.',
          onChangeLocation: _showManualLocationDialog,
          locationSource: null,
        );
    }
  }

  /// Opens the location picker screen and handles the result
  ///
  /// Uses go_router navigation to the full-screen location picker.
  /// Returns PickedLocation via Navigator.pop when user confirms.
  /// Passes current location so map centers on user's current position.
  Future<void> _showManualLocationDialog() async {
    // Get current location from controller state to center map there
    final currentState = _controller.state;
    final LatLng? currentLocation;
    final String? currentPlaceName;

    if (currentState is HomeStateSuccess) {
      currentLocation = currentState.location;
      currentPlaceName = currentState.placeName;
    } else {
      currentLocation = null;
      currentPlaceName = null;
    }

    final result = await context.push<PickedLocation>(
      '/location-picker',
      extra: LocationPickerExtras(
        mode: LocationPickerMode.riskLocation,
        initialLocation: currentLocation,
        initialPlaceName: currentPlaceName,
      ),
    );

    if (result != null && mounted) {
      // Call the controller's setManualLocation which will save via LocationResolver
      await _controller.setManualLocation(
        result.coordinates,
        placeName: result.placeName,
      );
    }
  }
}
