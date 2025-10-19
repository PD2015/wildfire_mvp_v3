import 'package:flutter/material.dart';
import 'package:wildfire_mvp_v3/features/map/controllers/map_controller.dart';
import 'package:wildfire_mvp_v3/features/map/widgets/risk_result_chip.dart';
import 'package:wildfire_mvp_v3/models/map_state.dart';

/// RiskCheckButton allows users to check fire risk at their current location
///
/// FloatingActionButton that triggers MapController.checkRiskAt()
/// and displays result in a bottom sheet.
///
/// Constitutional compliance:
/// - C3: ≥44dp touch target with semantic label
/// - C4: Uses theme colors
class RiskCheckButton extends StatelessWidget {
  final MapController controller;

  const RiskCheckButton({
    super.key,
    required this.controller,
  });

  Future<void> _checkRisk(BuildContext context) async {
    final state = controller.state;
    
    // Get current map center location
    if (state is! MapSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for map to load')),
      );
      return;
    }

    final location = state.centerLocation;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Check risk
    final result = await controller.checkRiskAt(location);

    // Close loading indicator
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    // Show result
    if (!context.mounted) return;

    result.fold(
      (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      },
      (fireRisk) {
        showModalBottomSheet(
          context: context,
          builder: (context) => Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Fire Risk Assessment',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                RiskResultChip(fireRisk: fireRisk),
                const SizedBox(height: 16),
                Text(
                  'Location: ${location.latitude.toStringAsFixed(2)}, ${location.longitude.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Check fire risk at this location',
      button: true,
      child: FloatingActionButton(
        onPressed: () => _checkRisk(context),
        tooltip: 'Check Fire Risk',
        child: const Icon(Icons.local_fire_department),
      ),
    );
  }
}
