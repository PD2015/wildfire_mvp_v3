import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/features/report/models/emergency_contact.dart';
import 'package:wildfire_mvp_v3/features/report/widgets/emergency_button.dart';
import 'package:wildfire_mvp_v3/utils/url_launcher_utils.dart';

/// Report Fire Screen - A12 MVP Implementation
///
/// Displays emergency contact options for reporting fires in Scotland.
/// Provides three contact methods: 999 Fire Service, 101 Police Scotland,
/// and 0800 555 111 Crimestoppers with proper accessibility and theming.
class ReportFireScreen extends StatelessWidget {
  const ReportFireScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report a Fire'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header section with guidance
              _buildHeader(),

              const SizedBox(height: 32.0),

              // Emergency contacts section
              Expanded(
                child: _buildEmergencyContacts(context),
              ),

              const SizedBox(height: 16.0),

              // Footer with safety reminder
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the header section with title and guidance
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary heading
      const Text(
        'Emergency Contacts',
        style: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.bold,
        ),
        semanticsLabel: 'Emergency Contacts for fire reporting',
      ),        const SizedBox(height: 8.0),

        // Guidance text
        Text(
          'Act fast — stay safe.',
          style: TextStyle(
            fontSize: 16.0,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          semanticsLabel: 'Guidance: Act fast, stay safe when reporting fires',
        ),
      ],
    );
  }

  /// Builds the emergency contacts section with all three buttons
  Widget _buildEmergencyContacts(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 999 Fire Service - Highest priority
          EmergencyButton(
            contact: EmergencyContact.fireService,
            onPressed: () =>
                _handleEmergencyCall(context, EmergencyContact.fireService),
          ),

          const SizedBox(height: 16.0),

          // 101 Police Scotland - Non-emergency
          EmergencyButton(
            contact: EmergencyContact.policeScotland,
            onPressed: () =>
                _handleEmergencyCall(context, EmergencyContact.policeScotland),
          ),

          const SizedBox(height: 16.0),

          // 0800 555 111 Crimestoppers - Anonymous reporting
          EmergencyButton(
            contact: EmergencyContact.crimestoppers,
            onPressed: () =>
                _handleEmergencyCall(context, EmergencyContact.crimestoppers),
          ),
        ],
      ),
    );
  }

  /// Builds the footer section with safety reminder
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.grey[600],
            size: 20.0,
            semanticLabel: 'Information',
          ),
          const SizedBox(height: 8.0),
          Text(
            'If you are in immediate danger, call 999 without delay. '
            'For non-emergency incidents or anonymous reporting, '
            'use the appropriate contact above.',
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
            semanticsLabel:
                'Safety reminder: Call 999 for immediate danger, use other contacts for non-emergency or anonymous reporting',
          ),
        ],
      ),
    );
  }

  /// Handles emergency call attempts with error handling and user feedback
  Future<void> _handleEmergencyCall(
      BuildContext context, EmergencyContact contact) async {
    // Use UrlLauncherUtils to handle the complete flow
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

    // Clear any existing SnackBars
    messenger.clearSnackBars();

    // Show error message with manual dialing information
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
        duration: const Duration(
            seconds: 6), // Longer duration for manual dialing info
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
