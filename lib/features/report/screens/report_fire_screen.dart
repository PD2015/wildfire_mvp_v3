import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/widgets/app_bar_actions.dart';
import 'package:wildfire_mvp_v3/features/report/controllers/report_fire_controller.dart';
import 'package:wildfire_mvp_v3/features/report/models/emergency_contact.dart';
import 'package:wildfire_mvp_v3/features/report/widgets/collapsible_location_card.dart';
import 'package:wildfire_mvp_v3/features/report/widgets/emergency_hero_card.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report a Fire'),
        centerTitle: true,
        actions: const [AppBarActions()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Emergency Hero Card - combines banner + emergency contacts + disclaimer
          EmergencyHeroCard(
            onCall999: () => _handleEmergencyCall(
              context,
              EmergencyContact.fireService,
            ),
            onCall101: () => _handleEmergencyCall(
              context,
              EmergencyContact.policeScotland,
            ),
            onCallCrimestoppers: () => _handleEmergencyCall(
              context,
              EmergencyContact.crimestoppers,
            ),
          ),
          const SizedBox(height: 16),

          // Collapsible Location Card - for emergency call assistance
          // Copy logic is handled internally by the widget
          CollapsibleLocationCard(
            locationState: widget.controller.locationState,
            onUpdateLocation: () =>
                widget.controller.openLocationPicker(context),
            onUseGps: () => widget.controller.useGpsLocation(),
          ),
          const SizedBox(height: 16),

          // Tips card - unchanged
          _TipsCard(cs: cs, textTheme: textTheme),

          const SizedBox(height: 32),
        ],
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
            // Safety Tips header and content (no icon)
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
              '• Keep vehicle access clear for fire engines',
              style: textTheme.bodyMedium?.copyWith(
                color: cs.onSecondaryContainer,
              ),
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
