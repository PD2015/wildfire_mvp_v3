import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/widgets/location_card.dart';

import '../controllers/home_controller.dart';
import '../models/home_state.dart';
import '../widgets/risk_banner.dart';
import '../widgets/risk_guidance_card.dart';
import '../widgets/manual_location_dialog.dart';
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
      appBar: AppBar(title: const Text('Wildfire Risk'), centerTitle: true),
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
                    // Location display GPS/manual
                    _buildLocationCard(),
                    const SizedBox(height: 16.0),
                    // Main risk banner display
                    _buildRiskBanner(),

                    const SizedBox(height: 24.0),

                    // Action buttons
                    _buildActionButtons(),

                    const SizedBox(height: 16.0),

                    // Risk guidance card
                    _buildRiskGuidance(),

                    const SizedBox(height: 16.0),

                    // Additional info based on state
                    _buildStateInfo(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds the main risk banner based on current HomeState
  Widget _buildRiskBanner() {
    final homeState = _controller.state;

    switch (homeState) {
      case HomeStateLoading():
        return const RiskBanner(state: RiskBannerLoading());

      case HomeStateSuccess(:final riskData, :final location):
        // Format location with privacy-compliant 2-decimal precision (C2)
        final locationLabel = LocationUtils.logRedact(
          location.latitude,
          location.longitude,
        );

        return RiskBanner(
          state: RiskBannerSuccess(riskData),
          locationLabel: locationLabel,
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
            ),
            if (cachedData != null) ...[
              const SizedBox(height: 8.0),
              _buildCachedDataInfo(cachedData),
            ],
          ],
        );
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

  /// Builds action buttons for retry and manual location entry
  Widget _buildActionButtons() {
    final isLoading = _controller.isLoading;
    final homeState = _controller.state;
    final canRetry = homeState is HomeStateError && homeState.canRetry;

    return Row(
      children: [
        // Retry button - only shown in error states
        if (canRetry) ...[
          Expanded(
            child: Semantics(
              label: isLoading
                  ? 'Retry disabled while loading'
                  : 'Retry loading fire risk data',
              button: true,
              enabled: !isLoading,
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
          ),
          const SizedBox(width: 12.0),
        ],

        // Manual location button (M3: FilledButton.tonal for secondary action)
        Expanded(
          child: Semantics(
            label: 'Set manual location for fire risk assessment',
            button: true,
            enabled: !isLoading,
            child: FilledButton.icon(
              onPressed: isLoading ? null : _showManualLocationDialog,
              icon: const Icon(Icons.location_on),
              label: const Text('Set Location'),
              style: FilledButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.secondaryContainer,
                foregroundColor:
                    Theme.of(context).colorScheme.onSecondaryContainer,
                minimumSize: const Size(0, 44.0), // C3: ≥44dp touch target
              ),
            ),
          ),
        ),
      ],
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
      HomeStateSuccess(:final riskData) =>
        RiskGuidanceCard(level: riskData.level),

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

  /// Builds the location card based on current HomeState
  Widget _buildLocationCard() {
    final state = _controller.state;

    switch (state) {
      case HomeStateLoading(:final lastKnownLocation):
        return LocationCard(
          coordinatesLabel: lastKnownLocation != null
              ? LocationUtils.logRedact(
                  lastKnownLocation.latitude,
                  lastKnownLocation.longitude,
                )
              : null,
          subtitle: lastKnownLocation != null
              ? 'Using last known location while we fetch an update...'
              : 'Determining your location…',
          isLoading: true,
          onChangeLocation: _showManualLocationDialog,
        );

      case HomeStateSuccess(:final location):
        return LocationCard(
          coordinatesLabel: LocationUtils.logRedact(
            location.latitude,
            location.longitude,
          ),
          subtitle: 'Current location (GPS)',
          onChangeLocation: _showManualLocationDialog,
        );

      case HomeStateError(:final cachedLocation) when cachedLocation != null:
        return LocationCard(
          coordinatesLabel: LocationUtils.logRedact(
            cachedLocation.latitude,
            cachedLocation.longitude,
          ),
          subtitle: 'Using last known location (offline)',
          onChangeLocation: _showManualLocationDialog,
        );

      case HomeStateError():
        return LocationCard(
          coordinatesLabel: null,
          subtitle: 'Location not available. Set a manual location.',
          onChangeLocation: _showManualLocationDialog,
        );
    }
  }

  /// Shows the manual location dialog and handles the result
  Future<void> _showManualLocationDialog() async {
    final coordinates = await ManualLocationDialog.show(context);

    if (coordinates != null && mounted) {
      // Call the controller's setManualLocation which will save via LocationResolver
      await _controller.setManualLocation(coordinates);
    }
  }
}
