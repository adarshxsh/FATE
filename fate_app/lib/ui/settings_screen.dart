import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationAccess = false;
  bool _usageAccess = false;
  bool _nearbyAccess = false;
  bool _locationAccess = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permissions & Privacy')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildPermissionTile(
            title: 'Notification Access',
            subtitle: 'Required to read message context and distractions',
            icon: Icons.notifications_active_rounded,
            value: _notificationAccess,
            onChanged: (val) => setState(() => _notificationAccess = val),
          ),
          const SizedBox(height: 16),
          _buildPermissionTile(
            title: 'App Usage Access',
            subtitle: 'Required to monitor foreground application usage',
            icon: Icons.app_blocking_rounded,
            value: _usageAccess,
            onChanged: (val) => setState(() => _usageAccess = val),
          ),
          const SizedBox(height: 16),
          _buildPermissionTile(
            title: 'Nearby Data Access',
            subtitle: 'Required to discover social context & peers',
            icon: Icons.bluetooth_connected_rounded,
            value: _nearbyAccess,
            onChanged: (val) => setState(() => _nearbyAccess = val),
          ),
          const SizedBox(height: 16),
          _buildPermissionTile(
            title: 'Location Context',
            subtitle: 'Required to build geographical study habits',
            icon: Icons.location_on_rounded,
            value: _locationAccess,
            onChanged: (val) => setState(() => _locationAccess = val),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      child: SwitchListTile(
        secondary: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(
          context,
        ).colorScheme.secondary, // fallback if needed
        activeTrackColor: Theme.of(
          context,
        ).colorScheme.secondary.withAlpha(100),
      ),
    );
  }
}
