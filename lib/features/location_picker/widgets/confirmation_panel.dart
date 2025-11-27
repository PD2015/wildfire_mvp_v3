import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/features/location_picker/models/location_picker_mode.dart';

/// Bottom panel with confirm/cancel buttons (T021)
///
/// Adapts button text based on LocationPickerMode:
/// - riskLocation: "Use this location" / "Cancel"
/// - fireReport: "Confirm location" / "Cancel"
class ConfirmationPanel extends StatelessWidget {
  final LocationPickerMode mode;
  final VoidCallback? onConfirm;
  final VoidCallback onCancel;
  final bool isConfirmEnabled;
  final bool showEmergencyBanner;

  const ConfirmationPanel({
    super.key,
    required this.mode,
    required this.onConfirm,
    required this.onCancel,
    this.isConfirmEnabled = true,
    this.showEmergencyBanner = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Emergency banner for fire report mode
          if (mode.showEmergencyBanner) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: colorScheme.onErrorContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Call 999 for emergencies',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Action buttons
          Row(
            children: [
              // Cancel button
              Expanded(
                child: OutlinedButton(
                  key: const Key('cancel_location_button'),
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: colorScheme.outline),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),

              // Confirm button
              Expanded(
                flex: 2,
                child: FilledButton(
                  key: const Key('confirm_location_button'),
                  onPressed: isConfirmEnabled ? onConfirm : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(mode.confirmButtonText),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
