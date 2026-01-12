import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/models/location_models.dart';
import 'package:wildfire_mvp_v3/widgets/expandable_location_panel.dart';
import 'package:wildfire_mvp_v3/widgets/location_chip.dart';

/// Composite widget combining LocationChip and ExpandableLocationPanel.
///
/// Manages expand/collapse animation state internally. Tap the chip to
/// toggle the expanded panel. The panel animates in/out smoothly with
/// a slide-and-fade transition.
///
/// ## Usage
/// ```dart
/// LocationChipWithPanel(
///   locationName: 'Near Aviemore, Highland',
///   coordinatesLabel: '57.20, -3.83',
///   locationSource: LocationSource.gps,
///   parentBackgroundColor: RiskPalette.moderate,
///   onChangeLocation: () => _showLocationPicker(),
///   onUseGps: () => _returnToGps(),
/// )
/// ```
///
/// ## Design Decisions
/// - Internal state management: widget controls expand/collapse
/// - Animation: 250ms slide + fade, Material easing curve
/// - Panel appears below chip with 8dp gap
/// - Chip chevron rotates 180° when expanded
///
/// ## Constitutional Compliance
/// - C3: All touch targets ≥44dp, semantic labels
/// - C4: Uses theme tokens, no hardcoded colors
class LocationChipWithPanel extends StatefulWidget {
  /// Display name for the location (place name or coordinates fallback)
  final String locationName;

  /// Coordinates label (e.g., "57.20, -3.83")
  final String? coordinatesLabel;

  /// what3words address (e.g., "///daring.lion.race")
  final String? what3words;

  /// Whether what3words is currently loading
  final bool isWhat3wordsLoading;

  /// Formatted location from reverse geocoding
  final String? formattedLocation;

  /// Whether geocoding is currently loading
  final bool isGeocodingLoading;

  /// Static map URL for preview
  final String? staticMapUrl;

  /// Whether map is loading
  final bool isMapLoading;

  /// Location source for icon and badge display
  final LocationSource? locationSource;

  /// Background color of parent container for contrast calculation
  final Color parentBackgroundColor;

  /// Whether chip is in loading state
  final bool isLoading;

  /// Callback when "Change Location" is tapped
  final VoidCallback? onChangeLocation;

  /// Callback when "Use GPS" is tapped
  final VoidCallback? onUseGps;

  /// Callback when what3words copy button is tapped
  final VoidCallback? onCopyWhat3words;

  /// Callback when coordinates copy button is tapped
  final VoidCallback? onCopyCoordinates;

  /// Whether to show map preview in expanded panel
  final bool showMapPreview;

  /// Whether to show action buttons in expanded panel
  final bool showActions;

  /// Initial expanded state (defaults to collapsed)
  final bool initiallyExpanded;

  /// Callback when expand state changes
  final ValueChanged<bool>? onExpandedChanged;

  const LocationChipWithPanel({
    super.key,
    required this.locationName,
    this.coordinatesLabel,
    this.what3words,
    this.isWhat3wordsLoading = false,
    this.formattedLocation,
    this.isGeocodingLoading = false,
    this.staticMapUrl,
    this.isMapLoading = false,
    this.locationSource,
    required this.parentBackgroundColor,
    this.isLoading = false,
    this.onChangeLocation,
    this.onUseGps,
    this.onCopyWhat3words,
    this.onCopyCoordinates,
    this.showMapPreview = true,
    this.showActions = true,
    this.initiallyExpanded = false,
    this.onExpandedChanged,
  });

  @override
  State<LocationChipWithPanel> createState() => _LocationChipWithPanelState();
}

class _LocationChipWithPanelState extends State<LocationChipWithPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeAnimation;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
    );

    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }

    widget.onExpandedChanged?.call(_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // The compact chip (always visible)
        LocationChip(
          locationName: widget.locationName,
          locationSource: widget.locationSource,
          parentBackgroundColor: widget.parentBackgroundColor,
          onTap: _toggleExpanded,
          isExpanded: _isExpanded,
          isLoading: widget.isLoading,
          coordinates: widget.coordinatesLabel,
        ),

        // Animated expanded panel
        SizeTransition(
          sizeFactor: _expandAnimation,
          axisAlignment: -1.0, // Align to top for smooth expansion
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ExpandableLocationPanel(
                formattedLocation: widget.formattedLocation,
                isGeocodingLoading: widget.isGeocodingLoading,
                coordinatesLabel: widget.coordinatesLabel,
                what3words: widget.what3words,
                isWhat3wordsLoading: widget.isWhat3wordsLoading,
                staticMapUrl: widget.staticMapUrl,
                isMapLoading: widget.isMapLoading,
                locationSource: widget.locationSource,
                parentBackgroundColor: widget.parentBackgroundColor,
                onChangeLocation: widget.onChangeLocation,
                onUseGps: widget.onUseGps,
                onCopyWhat3words: widget.onCopyWhat3words,
                onCopyCoordinates: widget.onCopyCoordinates,
                showMapPreview: widget.showMapPreview,
                showActions: widget.showActions,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Controller to programmatically control LocationChipWithPanel expansion.
///
/// Use this when you need external control over the expand/collapse state,
/// such as collapsing when navigating away or expanding from a parent widget.
///
/// ## Usage
/// ```dart
/// final controller = LocationChipPanelController();
///
/// // In your widget
/// LocationChipWithPanelControlled(
///   controller: controller,
///   // ... other properties
/// )
///
/// // Programmatic control
/// controller.expand();
/// controller.collapse();
/// controller.toggle();
/// ```
class LocationChipPanelController extends ChangeNotifier {
  bool _isExpanded = false;

  bool get isExpanded => _isExpanded;

  void expand() {
    if (!_isExpanded) {
      _isExpanded = true;
      notifyListeners();
    }
  }

  void collapse() {
    if (_isExpanded) {
      _isExpanded = false;
      notifyListeners();
    }
  }

  void toggle() {
    _isExpanded = !_isExpanded;
    notifyListeners();
  }
}

/// Version of LocationChipWithPanel that accepts external controller.
///
/// Use this variant when you need programmatic control over expansion.
class LocationChipWithPanelControlled extends StatefulWidget {
  /// External controller for programmatic expand/collapse
  final LocationChipPanelController controller;

  /// Display name for the location
  final String locationName;

  /// Coordinates label (e.g., "57.20, -3.83")
  final String? coordinatesLabel;

  /// what3words address
  final String? what3words;

  /// Whether what3words is loading
  final bool isWhat3wordsLoading;

  /// Formatted location from geocoding
  final String? formattedLocation;

  /// Whether geocoding is loading
  final bool isGeocodingLoading;

  /// Static map URL
  final String? staticMapUrl;

  /// Whether map is loading
  final bool isMapLoading;

  /// Location source
  final LocationSource? locationSource;

  /// Parent background color for contrast
  final Color parentBackgroundColor;

  /// Whether chip is loading
  final bool isLoading;

  /// Callback for Change Location button
  final VoidCallback? onChangeLocation;

  /// Callback for Use GPS button
  final VoidCallback? onUseGps;

  /// Callback for what3words copy
  final VoidCallback? onCopyWhat3words;

  /// Callback for coordinates copy
  final VoidCallback? onCopyCoordinates;

  /// Whether to show map preview
  final bool showMapPreview;

  /// Whether to show action buttons
  final bool showActions;

  const LocationChipWithPanelControlled({
    super.key,
    required this.controller,
    required this.locationName,
    this.coordinatesLabel,
    this.what3words,
    this.isWhat3wordsLoading = false,
    this.formattedLocation,
    this.isGeocodingLoading = false,
    this.staticMapUrl,
    this.isMapLoading = false,
    this.locationSource,
    required this.parentBackgroundColor,
    this.isLoading = false,
    this.onChangeLocation,
    this.onUseGps,
    this.onCopyWhat3words,
    this.onCopyCoordinates,
    this.showMapPreview = true,
    this.showActions = true,
  });

  @override
  State<LocationChipWithPanelControlled> createState() =>
      _LocationChipWithPanelControlledState();
}

class _LocationChipWithPanelControlledState
    extends State<LocationChipWithPanelControlled>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
    );

    // Sync with controller
    widget.controller.addListener(_onControllerChanged);
    if (widget.controller.isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(LocationChipWithPanelControlled oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (widget.controller.isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        LocationChip(
          locationName: widget.locationName,
          locationSource: widget.locationSource,
          parentBackgroundColor: widget.parentBackgroundColor,
          onTap: widget.controller.toggle,
          isExpanded: widget.controller.isExpanded,
          isLoading: widget.isLoading,
          coordinates: widget.coordinatesLabel,
        ),
        SizeTransition(
          sizeFactor: _expandAnimation,
          axisAlignment: -1.0,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ExpandableLocationPanel(
                formattedLocation: widget.formattedLocation,
                isGeocodingLoading: widget.isGeocodingLoading,
                coordinatesLabel: widget.coordinatesLabel,
                what3words: widget.what3words,
                isWhat3wordsLoading: widget.isWhat3wordsLoading,
                staticMapUrl: widget.staticMapUrl,
                isMapLoading: widget.isMapLoading,
                locationSource: widget.locationSource,
                parentBackgroundColor: widget.parentBackgroundColor,
                onChangeLocation: widget.onChangeLocation,
                onUseGps: widget.onUseGps,
                onCopyWhat3words: widget.onCopyWhat3words,
                onCopyCoordinates: widget.onCopyCoordinates,
                showMapPreview: widget.showMapPreview,
                showActions: widget.showActions,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
