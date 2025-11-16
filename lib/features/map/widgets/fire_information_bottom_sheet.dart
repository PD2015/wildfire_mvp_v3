import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/models/bottom_sheet_state.dart';

/// Fire information bottom sheet widget
///
/// Displays detailed fire incident information when user taps a map marker.
/// Supports loading, error, and data states with comprehensive fire details.
///
/// Constitutional compliance:
/// - C3: Accessibility with semantic labels and ≥44dp touch targets
/// - C4: Uses Material Design with clear data presentation
class FireInformationBottomSheet extends StatelessWidget {
  final BottomSheetState state;
  final VoidCallback? onClose;
  final VoidCallback? onRetry;

  const FireInformationBottomSheet({
    super.key,
    required this.state,
    this.onClose,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header with close button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Fire Incident Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (onClose != null)
                      Semantics(
                        label: 'Close fire details',
                        child: IconButton(
                          onPressed: onClose,
                          icon: const Icon(Icons.close),
                          constraints: const BoxConstraints(
                            minWidth: 48, // C3: ≥44dp touch targets
                            minHeight: 48,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildContent(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (state) {
      case BottomSheetHidden():
        return const SizedBox.shrink();

      case BottomSheetLoading():
        return _buildLoadingContent(context, state as BottomSheetLoading);

      case BottomSheetLoaded():
        return _buildLoadedContent(context, state as BottomSheetLoaded);

      case BottomSheetError():
        return _buildErrorContent(context, state as BottomSheetError);

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLoadingContent(BuildContext context, BottomSheetLoading state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 32),
        Semantics(
          label: 'Loading fire incident details',
          child: const CircularProgressIndicator(),
        ),
        const SizedBox(height: 16),
        Text(
          state.loadingMessage ?? 'Loading fire details...',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildLoadedContent(BuildContext context, BottomSheetLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fire ID and timestamp
        _buildInfoRow(
          context,
          icon: Icons.local_fire_department,
          label: 'Fire ID',
          value: state.fireIncident.id,
        ),
        const SizedBox(height: 12),

        // Detection time
        _buildInfoRow(
          context,
          icon: Icons.access_time,
          label: 'Detected',
          value: _formatDateTime(state.fireIncident.detectedAt),
        ),
        const SizedBox(height: 12),

        // Data source
        _buildInfoRow(
          context,
          icon: Icons.source,
          label: 'Data Source',
          value: state.fireIncident.source.name.toUpperCase(),
        ),
        const SizedBox(height: 12),

        // Confidence
        if (state.fireIncident.confidence != null) ...[
          _buildInfoRow(
            context,
            icon: Icons.verified,
            label: 'Confidence',
            value: state.confidenceDisplay,
          ),
          const SizedBox(height: 12),
        ],

        // Fire Radiative Power (FRP)
        if (state.fireIncident.frp != null) ...[
          _buildInfoRow(
            context,
            icon: Icons.power,
            label: 'Fire Power (FRP)',
            value: state.frpDisplay,
          ),
          const SizedBox(height: 12),
        ],

        // Area affected
        if (state.fireIncident.areaHectares != null) ...[
          _buildInfoRow(
            context,
            icon: Icons.straighten,
            label: 'Area Affected',
            value:
                '${state.fireIncident.areaHectares!.toStringAsFixed(1)} hectares',
          ),
          const SizedBox(height: 12),
        ],

        // Intensity/Risk Level
        _buildInfoRow(
          context,
          icon: Icons.warning_amber,
          label: 'Risk Level',
          value: state.riskLevel,
        ),
        const SizedBox(height: 12),

        // Distance and direction (if available)
        if (state.hasLocationInfo) ...[
          _buildInfoRow(
            context,
            icon: Icons.navigation,
            label: 'Distance',
            value: state.distanceAndDirection!,
          ),
          const SizedBox(height: 12),
        ],

        // Sensor source
        _buildInfoRow(
          context,
          icon: Icons.satellite,
          label: 'Sensor',
          value: state.fireIncident.sensorSource,
        ),
        const SizedBox(height: 12),

        // Location coordinates
        _buildInfoRow(
          context,
          icon: Icons.location_on,
          label: 'Coordinates',
          value:
              '${state.fireIncident.location.latitude.toStringAsFixed(4)}, ${state.fireIncident.location.longitude.toStringAsFixed(4)}',
        ),

        const SizedBox(height: 24),

        // Last updated info
        if (state.fireIncident.lastUpdate != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.update,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Last updated: ${_formatDateTime(state.fireIncident.lastUpdate!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildErrorContent(BuildContext context, BottomSheetError state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 32),
        Icon(
          Icons.error_outline,
          size: 48,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 16),
        Text(
          'Failed to Load Fire Details',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          state.message,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (onRetry != null)
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(120, 48), // C3: ≥44dp touch targets
            ),
          ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final utcTime = dateTime.toUtc();
    return '${utcTime.year}-${utcTime.month.toString().padLeft(2, '0')}-${utcTime.day.toString().padLeft(2, '0')} '
        '${utcTime.hour.toString().padLeft(2, '0')}:${utcTime.minute.toString().padLeft(2, '0')} UTC';
  }
}
