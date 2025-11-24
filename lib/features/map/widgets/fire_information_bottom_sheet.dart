import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/utils/distance_calculator.dart';

/// Fire information bottom sheet widget
///
/// Displays detailed fire incident information when user taps a map marker.
/// Shows detection time, source, confidence, FRP, distance, and metadata.
///
/// Constitutional compliance:
/// - C3: Accessibility with semantic labels and ≥44dp touch targets
/// - C4: Uses Material Design with clear, organized data presentation
class FireInformationBottomSheet extends StatelessWidget {
  /// Fire incident to display
  final FireIncident incident;

  /// User's current location for distance/bearing calculation
  final LatLng? userLocation;

  /// Optional callback when close button is tapped
  final VoidCallback? onClose;

  const FireInformationBottomSheet({
    super.key,
    required this.incident,
    this.userLocation,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, -4),
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
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),

              // Header with close button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          color: cs.onSurface,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Fire incident details',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
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
              const Divider(height: 16),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _buildLoadedContent(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadedContent(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final distanceAndDirection = userLocation != null
        ? DistanceCalculator.formatDistanceAndDirection(
            userLocation!,
            incident.location,
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LOCATION FIRST: what the user cares about most
        _InfoSection(
          title: 'Location',
          icon: Icons.place_outlined,
          children: [
            if (distanceAndDirection != null)
              _buildInfoRow(
                context,
                icon: Icons.navigation,
                label: 'Distance & direction',
                value: distanceAndDirection,
              ),
            _buildInfoRow(
              context,
              icon: Icons.location_on,
              label: 'Coordinates',
              value:
                  '${incident.location.latitude.toStringAsFixed(4)}, ${incident.location.longitude.toStringAsFixed(4)}',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // DETECTION & SOURCE
        _InfoSection(
          title: 'Detection & source',
          icon: Icons.access_time,
          children: [
            _buildInfoRow(
              context,
              icon: Icons.access_time,
              label: 'Detected',
              value: _formatDateTime(
                incident.detectedAt ?? incident.timestamp,
              ),
            ),
            _buildInfoRow(
              context,
              icon: Icons.source,
              label: 'Data source',
              value: incident.source.name.toUpperCase(),
            ),
            _buildInfoRow(
              context,
              icon: Icons.satellite_alt,
              label: 'Sensor',
              value: incident.sensorSource ?? 'Unknown sensor',
            ),
            if (incident.lastUpdate != null)
              _buildInfoRow(
                context,
                icon: Icons.update,
                label: 'Last updated',
                value: _formatDateTime(incident.lastUpdate!),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // FIRE CHARACTERISTICS / RISK
        _InfoSection(
          title: 'Fire characteristics',
          icon: Icons.local_fire_department_outlined,
          children: [
            _buildInfoRow(
              context,
              icon: Icons.warning_amber,
              label: 'Risk level',
              value: _formatIntensity(incident.intensity),
            ),
            if (incident.confidence != null)
              _buildInfoRow(
                context,
                icon: Icons.verified,
                label: 'Detection confidence',
                value: '${incident.confidence!.toStringAsFixed(0)}%',
              ),
            if (incident.frp != null)
              _buildInfoRow(
                context,
                icon: Icons.power,
                label: 'Fire power (FRP)',
                value: '${incident.frp!.toStringAsFixed(0)} MW',
              ),
            if (incident.areaHectares != null)
              _buildInfoRow(
                context,
                icon: Icons.square_foot,
                label: 'Estimated burned area',
                value:
                    '${incident.areaHectares!.toStringAsFixed(1)} hectares (ha)',
              ),
            // Fire ID is useful but low-priority for non-experts → last row
            _buildInfoRow(
              context,
              icon: Icons.fingerprint,
              label: 'Fire ID',
              value: incident.id,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Small explanatory note for non-experts (optional)
        Text(
          'These details come from satellite detections and may lag behind real-world conditions. '
          'If you are in immediate danger, call 999 without delay.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final utcTime = dateTime.toUtc();
    return '${utcTime.year}-${utcTime.month.toString().padLeft(2, '0')}-${utcTime.day.toString().padLeft(2, '0')} '
        '${utcTime.hour.toString().padLeft(2, '0')}:${utcTime.minute.toString().padLeft(2, '0')} UTC';
  }

  String _formatIntensity(String intensity) {
    return intensity.substring(0, 1).toUpperCase() + intensity.substring(1);
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: cs.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
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
}

/// Section wrapper for clearer grouping of fire details
class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.children,
    this.icon,
  });

  final String title;
  final List<Widget> children;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
            ],
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
