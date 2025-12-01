import 'package:flutter/material.dart';

/// What3wordsWarningDialog: Awareness dialog when confirming without w3w
///
/// **Purpose**: Shows when user tries to confirm location while what3words
/// is still loading or unavailable. Gives user choice to wait or proceed.
///
/// **Design Decisions**:
/// - Title: "what3words Unavailable" (clear, concise)
/// - Two actions: "Confirm Anyway" (primary) and "Wait" (secondary)
/// - Explains coordinates will still work
///
/// **Constitution Compliance**:
/// - C3: All buttons ≥48dp touch target (standard AlertDialog buttons)
class What3wordsWarningDialog extends StatelessWidget {
  /// Creates a what3words warning dialog.
  ///
  /// [isLoading] - True if w3w is still loading, false if failed/unavailable
  const What3wordsWarningDialog({
    super.key,
    this.isLoading = false,
  });

  /// Whether what3words is currently loading (vs failed)
  final bool isLoading;

  /// Shows the dialog and returns true if user chose to confirm anyway
  static Future<bool> show(BuildContext context,
      {bool isLoading = false}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => What3wordsWarningDialog(isLoading: isLoading),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Text('what3words Unavailable'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isLoading
                ? 'The what3words address is still loading. You can wait for it to complete or confirm with just coordinates.'
                : 'The what3words address could not be retrieved. You can still confirm your location using coordinates.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Coordinates are always saved and can be used to locate this position.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          key: const Key('wait_button'),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Wait'),
        ),
        FilledButton(
          key: const Key('confirm_anyway_button'),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Confirm Anyway'),
        ),
      ],
    );
  }
}
