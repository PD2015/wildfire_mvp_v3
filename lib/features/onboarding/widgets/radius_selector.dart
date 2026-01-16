import 'package:flutter/material.dart';

import 'package:wildfire_mvp_v3/models/consent_record.dart';

/// Segmented button for selecting notification radius.
///
/// Options: Off (0), 5km, 10km, 25km, 50km
/// Minimum 48dp touch targets for accessibility.
class RadiusSelector extends StatelessWidget {
  /// Currently selected radius in kilometers.
  final int selectedRadius;

  /// Callback when selection changes.
  final ValueChanged<int> onChanged;

  const RadiusSelector({
    required this.selectedRadius,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: OnboardingConfig.validRadiusOptions.map((radius) {
        final isSelected = radius == selectedRadius;
        final label = radius == 0 ? 'Off' : '${radius}km';

        return Semantics(
          label: radius == 0
              ? 'No notifications'
              : 'Notify about fires within $radius kilometers',
          selected: isSelected,
          child: ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => onChanged(radius),
            // Ensure minimum 48dp touch target
            materialTapTargetSize: MaterialTapTargetSize.padded,
          ),
        );
      }).toList(),
    );
  }
}
