import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/features/report/models/emergency_contact.dart';
import 'package:wildfire_mvp_v3/features/report/widgets/emergency_button.dart';
import 'package:wildfire_mvp_v3/utils/url_launcher_utils.dart';

/// Report Fire Screen - A12b Implementation (Descriptive)
///
/// Displays detailed Scotland-specific guidance for wildfire reporting.
/// Provides three-step process with descriptive text, emergency contacts,
/// and expanded safety tips. Enhances A12 MVP with educational content.
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Optional: Add offline banner here when connectivity status is available
                // if (!isConnected) const _OfflineBanner(),
                
                // Header section with descriptive guidance
                _buildHeader(),

                const SizedBox(height: 32.0),

                // Emergency contacts section
                _buildEmergencyContacts(context),

                const SizedBox(height: 16.0),

                // Footer with expanded safety tips
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the header section with detailed guidance
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'If you see a wildfire:',
          style: const TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.bold,
          ),
          semanticsLabel: 'If you see a wildfire',
        ),
        const SizedBox(height: 24),
        // Step 1
        Text(
          '1. Keep safe — move away from smoke and flames',
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w600,
          ),
          semanticsLabel: 'Step 1: Keep safe, move away from smoke and flames',
        ),
        const SizedBox(height: 12),
        Text(
          'Your safety is the top priority. Do not attempt to fight the fire yourself. Move to a safe distance upwind of the smoke, and ensure children, pets, and vulnerable people are also clear of danger.',
          style: const TextStyle(fontSize: 16.0),
          semanticsLabel: 'Your safety is the top priority. Do not attempt to fight the fire yourself. Move to a safe distance upwind of the smoke, and ensure children, pets, and vulnerable people are also clear of danger.',
        ),
        const SizedBox(height: 20),
        // Step 2
        Text(
          '2. Note your location as precisely as you can',
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w600,
          ),
          semanticsLabel: 'Step 2: Note your location as precisely as you can',
        ),
        const SizedBox(height: 12),
        Text(
          'Try to identify landmarks, road names, or nearby features. If you have a What3Words location or GPS coordinates, note them down. Describe the terrain (e.g., moorland, forestry, hillside) to help emergency services find the fire quickly.',
          style: const TextStyle(fontSize: 16.0),
          semanticsLabel: 'Try to identify landmarks, road names, or nearby features. If you have a What3Words location or GPS coordinates, note them down. Describe the terrain to help emergency services find the fire quickly.',
        ),
        const SizedBox(height: 20),
        // Step 3
        Text(
          '3. Call 999 and ask for the Fire Service',
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w600,
          ),
          semanticsLabel: 'Step 3: Call 999 and ask for the Fire Service',
        ),
        const SizedBox(height: 12),
        Text(
          'Provide as much detail as possible about the fire\'s location, size, and any immediate dangers. Mention if the fire is spreading, what it\'s burning (e.g., gorse, heather, trees), and whether people, livestock, or property are at risk.',
          style: const TextStyle(fontSize: 16.0),
          semanticsLabel: 'Provide as much detail as possible about the fire location, size, and any immediate dangers. Mention if the fire is spreading, what it is burning, and whether people, livestock, or property are at risk.',
        ),
      ],
    );
  }

  /// Builds the emergency contacts section with all three buttons
  Widget _buildEmergencyContacts(BuildContext context) {
    return Column(
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
    );
  }

  /// Builds the footer section with expanded safety tips
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.grey[600],
                size: 20.0,
                semanticLabel: 'Information',
              ),
              const SizedBox(width: 8.0),
              Text(
                'Safety Tips',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Text(
            '• Never attempt to fight a wildfire yourself',
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.grey[700],
            ),
            semanticsLabel: 'Never attempt to fight a wildfire yourself',
          ),
          const SizedBox(height: 8.0),
          Text(
            '• Keep vehicle access clear for fire engines',
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.grey[700],
            ),
            semanticsLabel: 'Keep vehicle access clear for fire engines',
          ),
          const SizedBox(height: 8.0),
          Text(
            '• If you are in immediate danger, call 999 without delay',
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.grey[700],
            ),
            semanticsLabel: 'If you are in immediate danger, call 999 without delay',
          ),
          const SizedBox(height: 8.0),
          Text(
            '• For non-emergency incidents or anonymous reporting, use the appropriate contact above',
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.grey[700],
            ),
            semanticsLabel: 'For non-emergency incidents or anonymous reporting, use the appropriate contact above',
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

/// Optional offline banner widget for future connectivity status integration
///
/// Displays when device is offline to inform user that dialing may still work
/// through cellular network even without data connection.
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wifi_off,
            color: Colors.orange[700],
            size: 20.0,
            semanticLabel: 'No internet connection',
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              'No internet connection. Emergency calling still works.',
              style: TextStyle(
                fontSize: 14.0,
                color: Colors.orange[900],
                fontWeight: FontWeight.w500,
              ),
              semanticsLabel: 'No internet connection. Emergency calling still works.',
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
