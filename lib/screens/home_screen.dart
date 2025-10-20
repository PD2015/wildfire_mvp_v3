import 'package:flutter/material.dart';

import '../controllers/home_controller.dart';
import '../models/home_state.dart';
import '../widgets/risk_banner.dart';
import '../widgets/manual_location_dialog.dart';
import '../services/models/fire_risk.dart';
import '../utils/time_format.dart';

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
  const HomeScreen({
    super.key,
    required this.controller,
  });

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
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Main risk banner display
                  _buildRiskBanner(),

                  const SizedBox(height: 24.0),

                  // Action buttons
                  _buildActionButtons(),

                  const SizedBox(height: 16.0),

                  // Additional info based on state
                  _buildStateInfo(),
                ],
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
        return const RiskBanner(
          state: RiskBannerLoading(),
        );

      case HomeStateSuccess(:final riskData, :final lastUpdated):
        return Column(
          children: [
            RiskBanner(
              state: RiskBannerSuccess(riskData),
            ),
            const SizedBox(height: 8.0),
            _buildTimestampInfo(riskData, lastUpdated),
          ],
        );

      case HomeStateError(:final errorMessage, :final cachedData):
        return Column(
          children: [
            RiskBanner(
              state: RiskBannerError(
                errorMessage,
                cached: cachedData,
              ),
            ),
            if (cachedData != null) ...[
              const SizedBox(height: 8.0),
              _buildCachedDataInfo(cachedData),
            ],
          ],
        );
    }
  }

  /// Builds timestamp and source information for successful states
  Widget _buildTimestampInfo(FireRisk riskData, DateTime lastUpdated) {
    final relativeTime = formatRelativeTime(
      utcNow: DateTime.now().toUtc(),
      updatedUtc: lastUpdated.toUtc(),
    );

    return Semantics(
      label:
          'Data updated $relativeTime from ${_getSourceDisplayName(riskData.source)}',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.access_time,
            size: 14.0,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4.0),
          Text(
            'Updated $relativeTime',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(width: 8.0),
          _buildSourceChip(riskData.source),
        ],
      ),
    );
  }

  /// Builds cached data information for error states with cached data
  Widget _buildCachedDataInfo(FireRisk cachedData) {
    return Semantics(
      label:
          'Showing cached data from ${_getSourceDisplayName(cachedData.source)}',
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
          const SizedBox(width: 8.0),
          _buildSourceChip(cachedData.source, isCached: true),
        ],
      ),
    );
  }

  /// Builds source chip for data attribution
  Widget _buildSourceChip(DataSource source, {bool isCached = false}) {
    final displayName = _getSourceDisplayName(source);
    final chipColor = isCached
        ? Theme.of(context).colorScheme.secondaryContainer
        : Theme.of(context).colorScheme.primaryContainer;
    final textColor = isCached
        ? Theme.of(context).colorScheme.onSecondaryContainer
        : Theme.of(context).colorScheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        isCached ? 'Cached' : displayName,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
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
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : () => _controller.retry(),
                icon: isLoading
                    ? const SizedBox(
                        width: 16.0,
                        height: 16.0,
                        child: CircularProgressIndicator(strokeWidth: 2.0),
                      )
                    : const Icon(Icons.refresh),
                label: Text(isLoading ? 'Loading...' : 'Retry'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 44.0), // C3: ≥44dp touch target
                ),
              ),
            ),
          ),
          const SizedBox(width: 12.0),
        ],

        // Manual location button - always available
        Expanded(
          child: Semantics(
            label: 'Set manual location for fire risk assessment',
            button: true,
            enabled: !isLoading,
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : _showManualLocationDialog,
              icon: const Icon(Icons.location_on),
              label: const Text('Set Location'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44.0), // C3: ≥44dp touch target
              ),
            ),
          ),
        ),
      ],
    );
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
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer,
                                  ),
                        ),
                        if (cachedData == null) ...[
                          const SizedBox(height: 4.0),
                          Text(
                            errorMessage,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer,
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

  /// Shows the manual location dialog and handles the result
  Future<void> _showManualLocationDialog() async {
    final coordinates = await ManualLocationDialog.show(context);

    if (coordinates != null && mounted) {
      // Call the controller's setManualLocation which will save via LocationResolver
      await _controller.setManualLocation(coordinates);
    }
  }

  /// Converts DataSource enum to display-friendly name
  String _getSourceDisplayName(DataSource source) {
    switch (source) {
      case DataSource.effis:
        return 'EFFIS';
      case DataSource.sepa:
        return 'SEPA';
      case DataSource.cache:
        return 'Cache';
      case DataSource.mock:
        return 'Mock';
    }
  }
}
