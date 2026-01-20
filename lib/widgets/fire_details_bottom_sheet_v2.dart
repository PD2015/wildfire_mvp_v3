import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wildfire_mvp_v3/features/map/widgets/map_source_chip.dart';
import 'package:wildfire_mvp_v3/models/burnt_area.dart';
import 'package:wildfire_mvp_v3/models/fire_incident.dart';
import 'package:wildfire_mvp_v3/models/hotspot.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/services/models/fire_risk.dart';
import 'package:wildfire_mvp_v3/utils/distance_calculator.dart';

/// Display type for fire data in the bottom sheet
enum FireDataDisplayType {
  /// Standard fire incident (legacy)
  incident,

  /// Live hotspot (VIIRS satellite detection)
  hotspot,

  /// Verified burnt area (MODIS confirmed)
  burntArea,
}

/// V2 Bottom sheet for fire details with improved UX
///
/// Key improvements over V1:
/// - Dynamic header based on data type (not generic "Fire Incident Details")
/// - Summary card with key info at top
/// - Plain language descriptions (no jargon)
/// - Progressive disclosure (land cover hidden by default)
/// - "Learn More" link to help docs
/// - Improved time format: "X ago (HH:MM UK time)"
///
/// Usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   builder: (_) => FireDetailsBottomSheetV2.fromHotspot(
///     hotspot: hotspot,
///     userLocation: userLocation,
///   ),
/// );
/// ```
class FireDetailsBottomSheetV2 extends StatelessWidget {
  /// The fire incident being displayed
  final FireIncident? incident;

  /// User's current GPS location (for distance calculation)
  final LatLng? userLocation;

  /// Callback when close button is pressed
  final VoidCallback? onClose;

  /// Callback when retry button is pressed (error state only)
  final VoidCallback? onRetry;

  /// What type of fire data we're displaying
  final FireDataDisplayType displayType;

  /// Original Hotspot data (when created via fromHotspot factory)
  final Hotspot? hotspot;

  /// Original BurntArea data (when created via fromBurntArea factory)
  final BurntArea? burntArea;

  /// Whether the sheet is in loading state
  final bool isLoading;

  /// Error message to display (null if no error)
  final String? errorMessage;

  /// Optional callback for "Learn More" action
  /// If null, defaults to navigating to appropriate help doc
  final VoidCallback? onLearnMore;

  const FireDetailsBottomSheetV2({
    super.key,
    this.incident,
    this.userLocation,
    this.onClose,
    this.onRetry,
    this.displayType = FireDataDisplayType.incident,
    this.hotspot,
    this.burntArea,
    this.isLoading = false,
    this.errorMessage,
    this.onLearnMore,
  });

  /// Factory constructor for displaying a Hotspot
  factory FireDetailsBottomSheetV2.fromHotspot({
    Key? key,
    required Hotspot hotspot,
    LatLng? userLocation,
    VoidCallback? onClose,
    VoidCallback? onRetry,
    Freshness freshness = Freshness.live,
    VoidCallback? onLearnMore,
  }) {
    // Convert Hotspot to FireIncident for rendering
    final incident = FireIncident(
      id: hotspot.id,
      location: hotspot.location,
      source: DataSource.effis,
      freshness: freshness,
      timestamp: hotspot.detectedAt,
      intensity: hotspot.intensity,
      detectedAt: hotspot.detectedAt,
      sensorSource: 'VIIRS',
      confidence: hotspot.confidence,
      frp: hotspot.frp,
    );

    return FireDetailsBottomSheetV2(
      key: key,
      incident: incident,
      userLocation: userLocation,
      onClose: onClose,
      onRetry: onRetry,
      displayType: FireDataDisplayType.hotspot,
      hotspot: hotspot,
      onLearnMore: onLearnMore,
    );
  }

  /// Factory constructor for displaying a BurntArea
  factory FireDetailsBottomSheetV2.fromBurntArea({
    Key? key,
    required BurntArea burntArea,
    LatLng? userLocation,
    VoidCallback? onClose,
    VoidCallback? onRetry,
    Freshness freshness = Freshness.live,
    VoidCallback? onLearnMore,
  }) {
    // Convert BurntArea to FireIncident for rendering
    final incident = FireIncident(
      id: burntArea.id,
      location: burntArea.centroid,
      source: DataSource.effis,
      freshness: freshness,
      timestamp: burntArea.fireDate,
      intensity: burntArea.intensity,
      detectedAt: burntArea.fireDate,
      sensorSource: 'MODIS',
      areaHectares: burntArea.areaHectares,
      boundaryPoints: burntArea.boundaryPoints,
    );

    return FireDetailsBottomSheetV2(
      key: key,
      incident: incident,
      userLocation: userLocation,
      onClose: onClose,
      onRetry: onRetry,
      displayType: FireDataDisplayType.burntArea,
      burntArea: burntArea,
      onLearnMore: onLearnMore,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.2,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
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
              // Drag handle
              _buildDragHandle(context),

              // Dynamic header based on type
              _buildHeader(context),

              const Divider(height: 1),

              // Scrollable content based on state
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
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
    // Loading state
    if (isLoading) {
      return _buildLoadingState(context);
    }

    // Error state
    if (errorMessage != null) {
      return _buildErrorState(context);
    }

    // Incident must be provided for loaded state
    if (incident == null) {
      return const SizedBox.shrink();
    }

    // Loaded state with incident data
    return _buildLoadedState(context);
  }

  Widget _buildLoadingState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 32),
        Semantics(
          label: 'Loading fire details',
          child: const CircularProgressIndicator(),
        ),
        const SizedBox(height: 16),
        Text(
          'Loading details...',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context) {
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
          'Failed to Load Details',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          errorMessage ?? 'An error occurred',
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

  Widget _buildLoadedState(BuildContext context) {
    final inc = incident!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Educational label with plain language
        if (displayType != FireDataDisplayType.incident)
          _buildEducationalLabel(context),

        // Summary card at top with key info
        _buildSummaryCard(context, inc),

        const SizedBox(height: 20),

        // Location section
        _InfoSection(
          title: 'Location',
          icon: Icons.place_outlined,
          children: [
            _buildDetailRow(
              context: context,
              icon: userLocation != null ? Icons.gps_fixed : Icons.gps_off,
              label: 'Your location',
              value: userLocation != null
                  ? '${userLocation!.latitude.toStringAsFixed(2)}, ${userLocation!.longitude.toStringAsFixed(2)} (GPS)'
                  : 'Unknown (GPS unavailable)',
              semanticLabel: userLocation != null
                  ? 'Your GPS location: ${userLocation!.latitude.toStringAsFixed(2)} latitude, ${userLocation!.longitude.toStringAsFixed(2)} longitude'
                  : 'Your GPS location is unavailable',
            ),
            _buildDetailRow(
              context: context,
              icon: Icons.social_distance,
              label: 'Distance',
              value: userLocation != null
                  ? '${DistanceCalculator.formatDistanceAndDirection(userLocation!, inc.location)} away'
                  : 'Unable to calculate (GPS required)',
              semanticLabel: userLocation != null
                  ? 'Fire is ${DistanceCalculator.formatDistanceAndDirection(userLocation!, inc.location)} away from your location'
                  : 'Distance unavailable because GPS location is unknown',
            ),
            _buildDetailRow(
              context: context,
              icon: Icons.location_on,
              label: 'Coordinates',
              value:
                  '${inc.location.latitude.toStringAsFixed(4)}, ${inc.location.longitude.toStringAsFixed(4)}',
              semanticLabel:
                  'Coordinates: ${inc.location.latitude.toStringAsFixed(4)} latitude, ${inc.location.longitude.toStringAsFixed(4)} longitude',
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Detection section
        _InfoSection(
          title: 'Detection info',
          icon: Icons.satellite_alt,
          children: [
            _buildDetailRow(
              context: context,
              icon: Icons.access_time,
              label: 'When detected',
              value:
                  _formatRelativeTimeWithClock(inc.detectedAt ?? inc.timestamp),
              semanticLabel:
                  'Detected ${_formatRelativeTimeWithClock(inc.detectedAt ?? inc.timestamp)}',
            ),
            if (displayType == FireDataDisplayType.burntArea &&
                burntArea != null)
              _buildDetailRow(
                context: context,
                icon: Icons.calendar_month,
                label: 'Fire season',
                value: '${burntArea!.seasonYear}',
                semanticLabel: 'Fire season: ${burntArea!.seasonYear}',
              ),
            _buildDetailRow(
              context: context,
              icon: Icons.source,
              label: 'Data from',
              value: _formatDataSourceForType(inc.source, inc.freshness),
              semanticLabel:
                  'Data from: ${_formatDataSourceForType(inc.source, inc.freshness)}',
            ),
            _buildDetailRow(
              context: context,
              icon: Icons.satellite_alt,
              label: 'Detected by',
              value: _formatSensorName(inc.sensorSource),
              semanticLabel:
                  'Detected by: ${_formatSensorName(inc.sensorSource)}',
            ),
          ],
        ),

        // Progressive disclosure: More details section
        if (_hasMoreDetails()) ...[
          const SizedBox(height: 16),
          _buildMoreDetailsSection(context, inc),
        ],

        const SizedBox(height: 16),

        // Learn more link
        _buildLearnMoreLink(context),

        const SizedBox(height: 16),

        // Safety warning text (at bottom per user preference)
        _buildSafetyText(context),

        const SizedBox(height: 16),
      ],
    );
  }

  /// Build dynamic header based on display type
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor =
        theme.textTheme.titleLarge?.color ?? colorScheme.onSurface;

    // Dynamic title and icon based on type
    final (icon, title) = switch (displayType) {
      FireDataDisplayType.hotspot => (
          Icons.local_fire_department,
          'Active Hotspot',
        ),
      FireDataDisplayType.burntArea => (
          Icons.layers,
          'Burnt Area',
        ),
      FireDataDisplayType.incident => (
          Icons.local_fire_department,
          'Fire Details',
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Title section (left)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: textColor,
                semanticLabel: '',
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          // Demo chip centered in remaining space
          if (incident != null)
            Expanded(
              child: Center(
                child: _buildHeaderChip(context),
              ),
            )
          else
            const Spacer(),
          // Close button (right)
          Semantics(
            button: true,
            label: 'Close details',
            child: IconButton(
              icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
              onPressed: () {
                if (onClose != null) {
                  onClose!();
                } else {
                  Navigator.of(context).pop();
                }
              },
              tooltip: 'Close',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  /// Build compact chip for header (just source label)
  Widget _buildHeaderChip(BuildContext context) {
    if (incident == null) return const SizedBox.shrink();
    return MapSourceChip(
      source: incident!.freshness,
      lastUpdated: incident!.timestamp,
    );
  }

  /// Build summary card with key info at top
  Widget _buildSummaryCard(BuildContext context, FireIncident inc) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Build items based on display type
    final items = <_SummaryItem>[];

    if (displayType == FireDataDisplayType.hotspot) {
      // Hotspot: Fire power, Confidence, Distance
      if (inc.frp != null) {
        items.add(_SummaryItem(
          icon: Icons.bolt,
          label: 'Fire power',
          value: '${inc.frp!.toStringAsFixed(0)} MW',
        ));
      }
      if (inc.confidence != null) {
        items.add(_SummaryItem(
          icon: Icons.verified_outlined,
          label: 'Confidence',
          value: '${inc.confidence!.toStringAsFixed(0)}%',
        ));
      }
    } else if (displayType == FireDataDisplayType.burntArea) {
      // Burnt area: Size, Season
      if (inc.areaHectares != null) {
        items.add(_SummaryItem(
          icon: Icons.square_foot,
          label: 'Area burned',
          value: '${inc.areaHectares!.toStringAsFixed(1)} ha',
        ));
      }
      if (burntArea != null) {
        items.add(_SummaryItem(
          icon: Icons.calendar_month,
          label: 'Season',
          value: '${burntArea!.seasonYear}',
        ));
      }
    }

    // Always add distance if GPS available
    final location = userLocation;
    if (location != null) {
      items.add(_SummaryItem(
        icon: Icons.social_distance,
        label: 'Distance',
        value: _formatDistanceOnly(location, inc.location),
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // Use dark-mode aware colors like V1 _InfoSection
        color: isDark
            ? colorScheme.surfaceContainerHigh
            : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children:
            items.map((item) => _buildSummaryItem(context, item)).toList(),
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, _SummaryItem item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: '${item.label}: ${item.value}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, size: 20, color: colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            item.value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            item.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Build educational label with plain language
  Widget _buildEducationalLabel(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final (icon, title, description) = switch (displayType) {
      FireDataDisplayType.hotspot => (
          Icons.local_fire_department,
          'Live Hotspot',
          'A satellite picked up heat here, suggesting possible fire activity. '
              'This doesn\'t confirm flames on the ground.',
        ),
      FireDataDisplayType.burntArea => (
          Icons.layers,
          'Burnt Area',
          'Satellite images show this area has been affected by fire this season. '
              'The fire may no longer be active.',
        ),
      FireDataDisplayType.incident => (Icons.info_outline, '', ''),
    };

    if (title.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Semantics(
        label: '$title. $description',
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            // Use dark-mode aware colors like V1 _InfoSection
            color: isDark
                ? colorScheme.surfaceContainerHigh
                : colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colorScheme.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    String? semanticLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface,
            semanticLabel: '',
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
                        fontSize: 13,
                      ),
                ),
                const SizedBox(height: 2),
                Semantics(
                  label: semanticLabel,
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Check if there are more details to show
  bool _hasMoreDetails() {
    // Burnt areas with land cover, or areas with simplification notice
    if (displayType == FireDataDisplayType.burntArea && burntArea != null) {
      return (burntArea!.landCoverBreakdown?.isNotEmpty ?? false) ||
          burntArea!.isSimplified;
    }
    // Hotspots with intensity or fire ID
    if (displayType == FireDataDisplayType.hotspot) {
      return incident?.intensity != null || incident?.id != null;
    }
    return false;
  }

  /// Build expandable "More details" section
  Widget _buildMoreDetailsSection(BuildContext context, FireIncident inc) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          'More details',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        leading: Icon(
          Icons.expand_more,
          color: colorScheme.onSurfaceVariant,
        ),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8),
        children: [
          // Fire ID
          if (inc.id.isNotEmpty)
            _buildDetailRow(
              context: context,
              icon: Icons.fingerprint,
              label: 'Reference ID',
              value: inc.id,
              semanticLabel: 'Reference ID: ${inc.id}',
            ),

          // Fire intensity for hotspots
          if (displayType == FireDataDisplayType.hotspot &&
              inc.intensity.isNotEmpty)
            _buildDetailRow(
              context: context,
              icon: Icons.whatshot,
              label: 'Heat intensity',
              value: _formatIntensity(inc.intensity),
              semanticLabel:
                  'Heat intensity: ${_formatIntensity(inc.intensity)}',
            ),

          // Land cover for burnt areas
          if (displayType == FireDataDisplayType.burntArea &&
              burntArea?.landCoverBreakdown != null &&
              burntArea!.landCoverBreakdown!.isNotEmpty)
            _buildLandCoverSection(context),

          // Simplification notice
          if (displayType == FireDataDisplayType.burntArea &&
              burntArea != null &&
              burntArea!.isSimplified)
            _buildSimplificationNotice(context),
        ],
      ),
    );
  }

  /// Build land cover breakdown section
  Widget _buildLandCoverSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final breakdown = burntArea!.landCoverBreakdown!;

    // Sort by percentage descending
    final sortedEntries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.terrain,
                  size: 18, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'Land types affected',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final entry in sortedEntries)
            _buildLandCoverBar(
              context: context,
              label: _formatLandCoverLabel(entry.key),
              percentage: entry.value,
              color: _getLandCoverColor(entry.key, colorScheme),
            ),
        ],
      ),
    );
  }

  Widget _buildLandCoverBar({
    required BuildContext context,
    required String label,
    required double percentage,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Semantics(
        label: '$label: ${(percentage * 100).toStringAsFixed(0)} percent',
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(label, style: theme.textTheme.bodySmall),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: color.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 40,
              child: Text(
                '${(percentage * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimplificationNotice(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final originalCount = burntArea?.originalPointCount ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        label: 'Boundary simplified from $originalCount points for display',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.compress,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Boundary simplified (from $originalCount points)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build "Learn more" link
  Widget _buildLearnMoreLink(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final helpDocId = switch (displayType) {
      FireDataDisplayType.hotspot => 'hotspots',
      FireDataDisplayType.burntArea => 'burnt-area',
      FireDataDisplayType.incident => 'hotspots', // fallback
    };

    final linkText = switch (displayType) {
      FireDataDisplayType.hotspot => 'What is a hotspot?',
      FireDataDisplayType.burntArea => 'What is a burnt area?',
      FireDataDisplayType.incident => 'Learn more',
    };

    return Semantics(
      button: true,
      label: linkText,
      child: InkWell(
        onTap: () {
          if (onLearnMore != null) {
            onLearnMore!();
          } else {
            // Default: navigate to help doc
            context.push('/help/doc/$helpDocId');
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.help_outline,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                linkText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build safety warning text
  Widget _buildSafetyText(BuildContext context) {
    return Text(
      'Satellite data may lag behind real conditions. '
      'If you are in immediate danger, call 999.',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Formatting helpers
  // ─────────────────────────────────────────────────────────────

  /// Format distance only (without direction) for summary card
  String _formatDistanceOnly(LatLng from, LatLng to) {
    final distanceMeters = DistanceCalculator.distanceInMeters(from, to);
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    } else {
      final distanceKm = distanceMeters / 1000;
      return '${distanceKm.toStringAsFixed(1)} km';
    }
  }

  /// Format time as "X ago (HH:MM UK time)"
  String _formatRelativeTimeWithClock(DateTime detectedAt) {
    final now = DateTime.now().toUtc();
    final difference = now.difference(detectedAt.toUtc());

    // Format relative part
    String relativePart;
    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      relativePart = '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      relativePart = '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      relativePart = '$days ${days == 1 ? 'day' : 'days'} ago';
    } else {
      // For very old data, just show date
      return _formatDateOnly(detectedAt);
    }

    // Format UK time (local time for UK users)
    final ukTime = detectedAt.toLocal();
    final hour = ukTime.hour.toString().padLeft(2, '0');
    final minute = ukTime.minute.toString().padLeft(2, '0');
    final clockPart = '$hour:$minute UK time';

    return '$relativePart ($clockPart)';
  }

  String _formatDateOnly(DateTime dateTime) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final d = dateTime.toLocal();
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _formatIntensity(String intensity) {
    return intensity.substring(0, 1).toUpperCase() + intensity.substring(1);
  }

  String _formatSensorName(String? sensor) {
    if (sensor == null) return 'Unknown';
    return switch (sensor.toUpperCase()) {
      'VIIRS' => 'VIIRS satellite',
      'MODIS' => 'MODIS satellite',
      _ => sensor,
    };
  }

  String _formatDataSourceForType(DataSource source, Freshness freshness) {
    if (displayType == FireDataDisplayType.hotspot) {
      if (source == DataSource.mock || freshness == Freshness.mock) {
        return 'Demo Data';
      }
      return 'GWIS (EC JRC)';
    }

    if (displayType == FireDataDisplayType.burntArea) {
      if (source == DataSource.mock || freshness == Freshness.mock) {
        return 'Demo Data';
      }
      return 'EFFIS (EC JRC)';
    }

    switch (source) {
      case DataSource.effis:
        return 'EFFIS';
      case DataSource.sepa:
        return 'SEPA';
      case DataSource.cache:
        return 'Cached';
      case DataSource.mock:
        return 'Demo Data';
    }
  }

  String _formatLandCoverLabel(String key) {
    return switch (key.toLowerCase()) {
      'forest' => 'Forest',
      'shrubland' => 'Shrubland',
      'grassland' => 'Grassland',
      'agriculture' => 'Farmland',
      'wetland' => 'Wetland',
      'urban' => 'Urban',
      'other' => 'Other',
      _ => key.substring(0, 1).toUpperCase() + key.substring(1),
    };
  }

  Color _getLandCoverColor(String key, ColorScheme colorScheme) {
    return switch (key.toLowerCase()) {
      'forest' => Colors.green.shade700,
      'shrubland' => Colors.orange.shade600,
      'grassland' => Colors.lightGreen.shade500,
      'agriculture' => Colors.amber.shade600,
      'wetland' => Colors.blue.shade400,
      'urban' => Colors.grey.shade600,
      _ => colorScheme.primary,
    };
  }
}

/// Section wrapper for clearer grouping
class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.children, this.icon});

  final String title;
  final List<Widget> children;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

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
            color: isDark ? cs.surfaceContainerHigh : cs.surfaceContainerLowest,
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

/// Summary item data class
class _SummaryItem {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}
