import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../logic/telemetry_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const MethodChannel _channel = MethodChannel(
    'com.ate.telemetry/channel',
  );

  bool _nearbyAccess = false;
  bool _locationAccess = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    _locationAccess = await Permission.location.isGranted;
    _nearbyAccess = await Permission.bluetoothScan.isGranted;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permissions & Privacy')),
      body: Consumer<TelemetryProvider>(
        builder: (context, telemetry, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildRadioPermissionSection(
                title: 'Notification Access',
                subtitle: 'Required to read message context and distractions',
                icon: Icons.notifications_active_rounded,
                value: telemetry.notificationEnabled,
                onChanged: (val) async {
                  if (val == true) {
                    await _channel.invokeMethod(
                      'requestNotificationPermission',
                    );
                    telemetry.setNotificationEnabled(true);
                  } else {
                    telemetry.setNotificationEnabled(false);
                  }
                },
              ),
              const SizedBox(height: 24),
              _buildRadioPermissionSection(
                title: 'App Usage Access',
                subtitle: 'Required to monitor foreground application usage',
                icon: Icons.app_blocking_rounded,
                value: telemetry.usageEnabled,
                onChanged: (val) async {
                  if (val == true) {
                    await _channel.invokeMethod('requestUsagePermission');
                    telemetry.setUsageEnabled(true);
                  } else {
                    telemetry.setUsageEnabled(false);
                  }
                },
              ),
              const Divider(height: 48),
              _buildPermissionTile(
                title: 'Nearby Data Access',
                subtitle: 'Required to discover social context & peers',
                icon: Icons.bluetooth_connected_rounded,
                value: _nearbyAccess,
                onChanged: (val) async {
                  setState(() => _nearbyAccess = val);
                  if (val) {
                    await [
                      Permission.bluetoothScan,
                      Permission.bluetoothConnect,
                      Permission.bluetoothAdvertise,
                      Permission.nearbyWifiDevices,
                    ].request();
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildPermissionTile(
                title: 'Location Context',
                subtitle: 'Required to build geographical study habits',
                icon: Icons.location_on_rounded,
                value: _locationAccess,
                onChanged: (val) async {
                  setState(() => _locationAccess = val);
                  if (val) {
                    await Permission.location.request();
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRadioPermissionSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('Granted'),
                value: true,
                groupValue: value,
                onChanged: onChanged,
                activeColor: Theme.of(context).colorScheme.secondary,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('Denied'),
                value: false,
                groupValue: value,
                onChanged: onChanged,
                activeColor: Colors.redAccent,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
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
        activeColor: Theme.of(context).colorScheme.secondary,
        activeTrackColor: Theme.of(
          context,
        ).colorScheme.secondary.withAlpha(100),
      ),
    );
  }
}
