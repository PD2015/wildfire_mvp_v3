import 'package:flutter/material.dart';

/// Notifications settings screen with "Coming soon" placeholders.
///
/// This screen shows the intended notification settings UI but with
/// all controls disabled. The actual push notification infrastructure
/// is not yet implemented.
class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert Settings'),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            // Coming soon banner
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Push notifications are coming soon. These settings will allow you to receive alerts about nearby fire activity.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Master toggle (disabled)
            const _DisabledSettingsTile(
              icon: Icons.notifications_outlined,
              title: 'Enable Fire Alerts',
              subtitle: 'Get notified about fire activity near you',
              trailing: Switch(
                value: false,
                onChanged: null, // Disabled
              ),
            ),

            const Divider(indent: 16, endIndent: 16),

            // Alert types section
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  'ALERT TYPES',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            const _DisabledSettingsTile(
              icon: Icons.local_fire_department_outlined,
              title: 'Active Fire Alerts',
              subtitle: 'New fires detected in your area',
              trailing: Checkbox(
                value: false,
                onChanged: null, // Disabled
              ),
            ),

            const _DisabledSettingsTile(
              icon: Icons.warning_amber_outlined,
              title: 'High Risk Alerts',
              subtitle: 'When fire danger becomes high or extreme',
              trailing: Checkbox(
                value: false,
                onChanged: null, // Disabled
              ),
            ),

            const Divider(indent: 16, endIndent: 16),

            // Distance setting section
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Semantics(
                header: true,
                child: Text(
                  'ALERT RADIUS',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            const _DisabledSettingsTile(
              icon: Icons.social_distance_outlined,
              title: 'Alert Distance',
              subtitle: 'Receive alerts within 25 km',
              trailing: Icon(Icons.chevron_right),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// A disabled settings tile for "Coming soon" features.
class _DisabledSettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _DisabledSettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabledColor = theme.colorScheme.onSurface.withValues(alpha: 0.38);

    return ListTile(
      leading: Icon(
        icon,
        color: disabledColor,
      ),
      title: Text(
        title,
        style: TextStyle(color: disabledColor),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: disabledColor,
        ),
      ),
      trailing: trailing,
      enabled: false,
    );
  }
}
