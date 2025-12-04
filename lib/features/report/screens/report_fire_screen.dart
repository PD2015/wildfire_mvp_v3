import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/features/report/controllers/report_fire_controller.dart';
import 'package:wildfire_mvp_v3/features/report/models/emergency_contact.dart';
import 'package:wildfire_mvp_v3/features/report/widgets/emergency_button.dart';
import 'package:wildfire_mvp_v3/features/report/widgets/report_fire_location_card.dart';
import 'package:wildfire_mvp_v3/utils/url_launcher_utils.dart';

/// Report Fire Screen - A12b Implementation (Descriptive)
///
/// Displays Scotland-specific wildfire reporting guidance with clear visual hierarchy.
/// Uses Material 3 design with branded colors, 52dp touch targets, and semantic labels.
/// Preserves existing UrlLauncherUtils emergency calling infrastructure.
///
/// Features:
/// - Location helper card to assist with 999/101 calls
/// - Emergency call buttons for Fire Service, Police Scotland, Crimestoppers
/// - Safety tips with expandable guidance
///
/// Constitutional compliance:
/// - C3: All buttons ≥48dp touch target, semantic labels
/// - C4: Clear disclaimer that app doesn't contact emergency services
class ReportFireScreen extends StatefulWidget {
  /// Controller for managing location helper state
  final ReportFireController controller;

  const ReportFireScreen({super.key, required this.controller});

  @override
  State<ReportFireScreen> createState() => _ReportFireScreenState();
}

class _ReportFireScreenState extends State<ReportFireScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Brand-aware colors (Material 3 theme)
    final bannerBg = cs.tertiaryContainer;
    final bannerFg = cs.onTertiaryContainer;

    return Scaffold(
      appBar: AppBar(title: const Text('Report a Fire'), centerTitle: true),
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

          // Location helper card - uses shared LocationCard for consistent UX
          _buildLocationCard(context, cs, textTheme),
          const SizedBox(height: 8),

          // Disclaimer - app doesn't contact services
          _buildDisclaimer(context, cs),
          const SizedBox(height: 16),

          // Emergency Actions Card - Groups all three contact options
          Semantics(
            container: true,
            label: 'Emergency contact options',
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 2.0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section heading inside card
                    Semantics(
                      header: true,
                      label: 'Who to call about this fire',
                      child: Text(
                        'Who to call about this fire',
                        style: textTheme.titleMedium?.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Step 1 — Emergency (999)
                    Semantics(
                      header: true,
                      label: 'Step 1: If the fire is spreading or unsafe',
                      child: Text(
                        '1) If the fire is spreading or unsafe:',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label:
                          'Instructions: Call 999 and ask for the Fire Service. Give your location, what is burning, and a safe access point.',
                      child: Text(
                        'Call 999 and ask for the Fire Service.\n'
                        'Give your location, what\'s burning, and a safe access point.',
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 12),
                    EmergencyButton(
                      contact: EmergencyContact.fireService,
                      onPressed: () => _handleEmergencyCall(
                        context,
                        EmergencyContact.fireService,
                      ),
                    ),

                    const SizedBox(height: 16),
                    Divider(
                      height: 32,
                      thickness: 1.25,
                      color: cs.outlineVariant,
                    ),
                    const SizedBox(height: 16),

                    // Step 2 — Police Scotland (101)
                    Semantics(
                      header: true,
                      label:
                          'Step 2: If someone is lighting a fire irresponsibly',
                      child: Text(
                        '2) If someone is lighting a fire irresponsibly:',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'Instructions: Call Police Scotland on 101',
                      child: Text(
                        'Call Police Scotland on 101.',
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 12),
                    EmergencyButton(
                      contact: EmergencyContact.policeScotland,
                      onPressed: () => _handleEmergencyCall(
                        context,
                        EmergencyContact.policeScotland,
                      ),
                    ),

                    const SizedBox(height: 16),
                    Divider(
                      height: 32,
                      thickness: 1.25,
                      color: cs.outlineVariant,
                    ),
                    const SizedBox(height: 16),

                    // Step 3 — Crimestoppers (0800 555 111)
                    Semantics(
                      header: true,
                      label: 'Step 3: Want to report anonymously?',
                      child: Text(
                        '3) Want to report anonymously?',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Semantics(
                      label: 'Instructions: Call Crimestoppers on 0800 555 111',
                      child: Text(
                        'Call Crimestoppers on 0800 555 111.',
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 12),
                    EmergencyButton(
                      contact: EmergencyContact.crimestoppers,
                      onPressed: () => _handleEmergencyCall(
                        context,
                        EmergencyContact.crimestoppers,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Tips card
          _TipsCard(cs: cs, textTheme: textTheme),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Builds the location card using fire-specific ReportFireLocationCard
  ///
  /// The ReportFireLocationCard widget handles all state rendering internally
  /// with fire-specific content (5dp coords, emergency context, copy button).
  Widget _buildLocationCard(
    BuildContext context,
    ColorScheme cs,
    TextTheme textTheme,
  ) {
    return ReportFireLocationCard(
      locationState: widget.controller.locationState,
      onChangeLocation: () => widget.controller.openLocationPicker(context),
      onUseGps: () => widget.controller.useGpsLocation(),
    );
  }

  /// Builds the emergency services disclaimer
  Widget _buildDisclaimer(BuildContext context, ColorScheme cs) {
    return Semantics(
      label:
          'Important: This app does not contact emergency services. Always phone 999, 101 or Crimestoppers yourself.',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              size: 14,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'This app does not contact emergency services. Always phone 999, 101 or Crimestoppers yourself.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handles emergency call attempts with error handling and user feedback
  /// Uses existing UrlLauncherUtils infrastructure
  Future<void> _handleEmergencyCall(
    BuildContext context,
    EmergencyContact contact,
  ) async {
    await UrlLauncherUtils.handleEmergencyCall(
      contact: contact,
      onFailure: (errorMessage) =>
          _showCallFailureSnackBar(context, errorMessage, contact),
    );
  }

  /// Shows SnackBar when emergency call fails with manual dialing option
  void _showCallFailureSnackBar(
    BuildContext context,
    String errorMessage,
    EmergencyContact contact,
  ) {
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
      liveRegion: true,
      container: true,
      label: '$title. $subtitle',
      child: Card(
        elevation: 1.0,
        color: background,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                          height: 1.1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: foreground.withValues(alpha: 0.92),
                          height: 1.3),
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
}

/// Tips card widget with lightbulb icon and safety guidance
class _TipsCard extends StatelessWidget {
  const _TipsCard({required this.cs, required this.textTheme});

  final ColorScheme cs;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      color: cs
          .secondaryContainer, // Material 3: secondaryContainer for informational cards
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with icon
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb, color: cs.onSecondaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Safety Tips',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Use What3Words or GPS for your location\n'
                        '• Never fight wildfires yourself\n'
                        '• If smoke approaches, move uphill and upwind\n'
                        '• Keep vehicle access clear for fire engines',
                        style: textTheme.bodyMedium?.copyWith(
                          color: cs.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Expandable "More Safety Guidance" section
            Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(
                  left: 16,
                  top: 8,
                  bottom: 4,
                ),
                iconColor: cs.onSecondaryContainer,
                collapsedIconColor: cs.onSecondaryContainer,
                title: Text(
                  'More Safety Guidance',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSecondaryContainer,
                  ),
                ),
                children: [
                  Text(
                    '• Move children, pets, and vulnerable people to safety\n'
                    '• Keep a safe distance upwind of smoke\n'
                    '• Note landmarks, terrain features (moorland, forestry, hillside)\n'
                    '• Describe what\'s burning (gorse, heather, trees)\n'
                    '• Mention if fire is spreading or threatening property/livestock\n'
                    '• In immediate danger, call 999 without delay',
                    style: textTheme.bodyMedium?.copyWith(
                      color: cs.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
