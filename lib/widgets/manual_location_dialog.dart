import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/location_models.dart';

/// Manual location entry dialog with coordinate validation and accessibility compliance.
///
/// Provides two text fields for latitude and longitude input with:
/// - Real-time validation for coordinate ranges
/// - Input formatters for numeric decimal input
/// - ≥44dp touch targets with semantic labels (Gate C3)
/// - Clear error messages for invalid input
///
/// Returns LatLng on successful save, null on cancel.
class ManualLocationDialog extends StatefulWidget {
  const ManualLocationDialog({super.key});

  @override
  State<ManualLocationDialog> createState() => _ManualLocationDialogState();

  /// Show the manual location dialog and return the entered coordinates
  static Future<LatLng?> show(BuildContext context) {
    return showDialog<LatLng>(
      context: context,
      builder: (context) => const ManualLocationDialog(),
    );
  }
}

class _ManualLocationDialogState extends State<ManualLocationDialog> {
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _validationError;
  bool _isValidInput = false;

  @override
  void initState() {
    super.initState();
    // Add listeners for real-time validation
    _latController.addListener(_validateInput);
    _lonController.addListener(_validateInput);
  }

  @override
  void dispose() {
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  /// Real-time validation of coordinate input
  void _validateInput() {
    final latText = _latController.text.trim();
    final lonText = _lonController.text.trim();

    if (latText.isEmpty || lonText.isEmpty) {
      setState(() {
        _validationError = null;
        _isValidInput = false;
      });
      return;
    }

    final lat = double.tryParse(latText);
    final lon = double.tryParse(lonText);

    if (lat == null || lon == null) {
      setState(() {
        _validationError = 'Please enter valid numbers';
        _isValidInput = false;
      });
      return;
    }

    if (lat < -90.0 || lat > 90.0) {
      setState(() {
        _validationError = 'Latitude must be between -90 and 90 degrees';
        _isValidInput = false;
      });
      return;
    }

    if (lon < -180.0 || lon > 180.0) {
      setState(() {
        _validationError = 'Longitude must be between -180 and 180 degrees';
        _isValidInput = false;
      });
      return;
    }

    setState(() {
      _validationError = null;
      _isValidInput = true;
    });
  }

  /// Handle save button press
  void _handleSave() {
    if (!_isValidInput) return;

    final lat = double.parse(_latController.text.trim());
    final lon = double.parse(_lonController.text.trim());

    final latLng = LatLng(lat, lon);
    Navigator.of(context).pop(latLng);
  }

  /// Handle cancel button press
  void _handleCancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter Location'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Latitude input field
            Semantics(
              label: 'Latitude coordinate input',
              child: TextField(
                key: const Key('latitude_field'),
                controller: _latController,
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  hintText: 'Enter latitude (-90 to 90)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.-]')),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Longitude input field
            Semantics(
              label: 'Longitude coordinate input',
              child: TextField(
                key: const Key('longitude_field'),
                controller: _lonController,
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  hintText: 'Enter longitude (-180 to 180)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.-]')),
                ],
              ),
            ),

            // Error message display
            if (_validationError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _validationError!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        // Cancel button
        Semantics(
          label: 'Cancel',
          button: true,
          child: OutlinedButton(
            key: const Key('cancel_button'),
            onPressed: _handleCancel,
            child: const Text('Cancel'),
          ),
        ),
        // Save button
        Semantics(
          label: 'Save manual location',
          button: true,
          child: ElevatedButton(
            key: const Key('save_button'),
            onPressed: _isValidInput ? _handleSave : null,
            child: const Text('Save Location'),
          ),
        ),
      ],
    );
  }
}
