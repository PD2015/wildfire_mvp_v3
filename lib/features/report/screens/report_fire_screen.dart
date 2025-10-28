import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/features/report/models/emergency_contact.dart';
import 'package:wildfire_mvp_v3/utils/url_launcher_utils.dart';

/// Report Fire Screen - A12b Implementation (Descriptive)
///
/// Displays Scotland-specific wildfire reporting guidance with clear visual hierarchy.
/// Uses Material 3 design with branded colors, 52dp touch targets, and semantic labels.
/// Preserves existing UrlLauncherUtils emergency calling infrastructure.
class ReportFireScreen extends StatelessWidget {
  const ReportFireScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Brand-aware colors (Material 3 theme)
    final bannerBg = cs.tertiaryContainer;
    final bannerFg = cs.onTertiaryContainer;
    final dangerBg = cs.error; // 999 emergency
    final dangerFg = cs.onError;
    final primaryBg = cs.primary; // 101 Police Scotland
    final primaryFg = cs.onPrimary;
    final neutralBg = cs.surfaceVariant; // Crimestoppers
    final neutralFg = cs.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report a Fire'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Banner(
            background: bannerBg,
            foreground: bannerFg,
            title: 'See smoke, flames, or a campfire?',
            subtitle: 'Act fast — stay safe.',
            icon: Icons.local_fire_department,
          ),
          const SizedBox(height: 16),

          // Step 1 — Emergency (999)
          Text(
            '1) If the fire is spreading or unsafe:',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Call 999 and ask for the Fire Service.\n'
            'Give your location, what\'s burning, and a safe access point.',
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          _CallButton(
            label: 'Call 999 — Fire Service',
            contact: EmergencyContact.fireService,
            background: dangerBg,
            foreground: dangerFg,
            semanticsLabel: 'Call emergency services, 999, Fire Service',
            onPressed: () => _handleEmergencyCall(context, EmergencyContact.fireService),
          ),

          const SizedBox(height: 24),

          // Step 2 — Police Scotland (101)
          Text(
            '2) If someone is lighting a fire irresponsibly:',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text('Call Police Scotland on 101.', style: textTheme.bodyLarge),
          const SizedBox(height: 12),
          _CallButton(
            label: 'Call 101 — Police Scotland',
            contact: EmergencyContact.policeScotland,
            background: primaryBg,
            foreground: primaryFg,
            semanticsLabel: 'Call Police Scotland non-emergency number 101',
            onPressed: () => _handleEmergencyCall(context, EmergencyContact.policeScotland),
          ),

          const SizedBox(height: 24),

          // Step 3 — Crimestoppers (0800 555 111)
          Text(
            '3) Want to report anonymously?',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text('Call Crimestoppers on 0800 555 111.', style: textTheme.bodyLarge),
          const SizedBox(height: 12),
          _CallButton(
            label: 'Call 0800 555 111 — Crimestoppers',
            contact: EmergencyContact.crimestoppers,
            background: neutralBg,
            foreground: neutralFg,
            semanticsLabel: 'Call Crimestoppers anonymous line 0800 555 111',
            onPressed: () => _handleEmergencyCall(context, EmergencyContact.crimestoppers),
          ),

          const SizedBox(height: 24),

          // Tips card
          _TipsCard(cs: cs, textTheme: textTheme),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Handles emergency call attempts with error handling and user feedback
  /// Uses existing UrlLauncherUtils infrastructure
  Future<void> _handleEmergencyCall(
      BuildContext context, EmergencyContact contact) async {
    await UrlLauncherUtils.handleEmergencyCall(
      contact: contact,
      onFailure: (errorMessage) =>
          _showCallFailureSnackBar(context, errorMessage, contact),
    );
  }

  /// Shows SnackBar when emergency call fails with manual dialing option
  void _showCallFailureSnackBar(
      BuildContext context, String errorMessage, EmergencyContact contact) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              errorMessage,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4.0),
            Text(
              'Manual dial: ${contact.phoneNumber}',
              style: const TextStyle(fontSize: 13.0),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'OK',
          textColor: Theme.of(context).colorScheme.onError,
          onPressed: () => messenger.hideCurrentSnackBar(),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16.0),
      ),
    );
  }
}

/// Banner widget for visual emphasis at top of screen
class _Banner extends StatelessWidget {
  const _Banner({
    required this.background,
    required this.foreground,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final Color background;
  final Color foreground;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Wildfire report instructions',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: foreground, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: foreground),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

/// Call button widget with consistent 52dp height and semantic labels
class _CallButton extends StatelessWidget {
  const _CallButton({
    required this.label,
    required this.contact,
    required this.background,
    required this.foreground,
    required this.semanticsLabel,
    required this.onPressed,
  });

  final String label;
  final EmergencyContact contact;
  final Color background;
  final Color foreground;
  final String semanticsLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          onPressed: onPressed,
          icon: const Icon(Icons.call),
          label: Text(label),
        ),
      ),
    );
  }
}

/// Tips card widget with lightbulb icon and safety guidance
class _TipsCard extends StatelessWidget {
  const _TipsCard({required this.cs, required this.textTheme});
  
  final ColorScheme cs;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Use What3Words or GPS for your location.\n'
                  'Never fight wildfires yourself.\n'
                  'If smoke approaches, move uphill and upwind.',
                  style: textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Static factory methods for common use cases
extension ReportFireScreenFactory on ReportFireScreen {
  /// Creates ReportFireScreen with custom AppBar title
  static Widget withTitle(String title) {
    return Builder(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: Text(title),
          centerTitle: true,
        ),
        body: const ReportFireScreen(),
      ),
    );
  }

  /// Creates ReportFireScreen without AppBar (for embedding in other screens)
  static Widget withoutAppBar() {
    return const SafeArea(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: ReportFireScreen(),
      ),
    );
  }
}
