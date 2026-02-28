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

  // Local state for the interdependent sliders
  double _sLoc = 30.0;
  double _sSoc = 30.0;
  double _sDig = 40.0;

  bool _isInit = false;

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
      appBar: AppBar(title: const Text('Settings & Privacy')),
      body: Consumer<TelemetryProvider>(
        builder: (context, telemetry, child) {
          // Initialize local sliders from backend ONCE when it loads
          if (!_isInit && !telemetry.isLoadingSettings) {
            _sLoc = telemetry.spatialWeight * 100;
            _sSoc = telemetry.socialWeight * 100;
            _sDig = telemetry.digitalWeight * 100;
            _isInit = true;
            // Prevent frame collision
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() {});
            });
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Scoring Priorities (100% Total)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildWeightSlider('Spatial Activity', _sLoc, (val) {
                        _updateSliders('loc', val);
                      }, Colors.blueAccent),
                      _buildWeightSlider('Social Engagement', _sSoc, (val) {
                        _updateSliders('soc', val);
                      }, Colors.orangeAccent),
                      _buildWeightSlider('Digital Processing', _sDig, (val) {
                        _updateSliders('dig', val);
                      }, Colors.purpleAccent),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: telemetry.isLoadingSettings
                              ? null
                              : () async {
                                  final ok = await telemetry.saveSettings(
                                    _sLoc / 100.0,
                                    _sSoc / 100.0,
                                    _sDig / 100.0,
                                  );
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          ok
                                              ? 'Configuration Saved'
                                              : 'Failed to save',
                                        ),
                                        backgroundColor: ok
                                            ? Colors.green
                                            : Colors.redAccent,
                                      ),
                                    );
                                  }
                                },
                          child: telemetry.isLoadingSettings
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Save Parameters'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Permissions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
              _buildPermissionTile(
                title: 'Notification Access',
                subtitle: 'Required to read message context and distractions',
                icon: Icons.notifications_active_rounded,
                value: telemetry.notificationEnabled,
                onChanged: (val) async {
                  if (val) {
                    await _channel.invokeMethod(
                      'requestNotificationPermission',
                    );
                    telemetry.setNotificationEnabled(true);
                  } else {
                    telemetry.setNotificationEnabled(false);
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildPermissionTile(
                title: 'App Usage Access',
                subtitle: 'Required to monitor foreground application usage',
                icon: Icons.app_blocking_rounded,
                value: telemetry.usageEnabled,
                onChanged: (val) async {
                  if (val) {
                    await _channel.invokeMethod('requestUsagePermission');
                    telemetry.setUsageEnabled(true);
                  } else {
                    telemetry.setUsageEnabled(false);
                  }
                },
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
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
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  void _updateSliders(String changed, double newValue) {
    setState(() {
      double diff;
      if (changed == 'loc') {
        diff = newValue - _sLoc;
        _sLoc = newValue;
        // Distribute opposite
        final totalOther = _sSoc + _sDig;
        if (totalOther > 0) {
          _sSoc = (_sSoc - diff * (_sSoc / totalOther)).clamp(0, 100);
          _sDig = (_sDig - diff * (_sDig / totalOther)).clamp(0, 100);
        } else {
          _sSoc = (100 - _sLoc) / 2;
          _sDig = (100 - _sLoc) / 2;
        }
      } else if (changed == 'soc') {
        diff = newValue - _sSoc;
        _sSoc = newValue;
        final totalOther = _sLoc + _sDig;
        if (totalOther > 0) {
          _sLoc = (_sLoc - diff * (_sLoc / totalOther)).clamp(0, 100);
          _sDig = (_sDig - diff * (_sDig / totalOther)).clamp(0, 100);
        } else {
          _sLoc = (100 - _sSoc) / 2;
          _sDig = (100 - _sSoc) / 2;
        }
      } else if (changed == 'dig') {
        diff = newValue - _sDig;
        _sDig = newValue;
        final totalOther = _sLoc + _sSoc;
        if (totalOther > 0) {
          _sLoc = (_sLoc - diff * (_sLoc / totalOther)).clamp(0, 100);
          _sSoc = (_sSoc - diff * (_sSoc / totalOther)).clamp(0, 100);
        } else {
          _sLoc = (100 - _sDig) / 2;
          _sSoc = (100 - _sDig) / 2;
        }
      }

      // Final clamping safety pass
      final sum = _sLoc + _sSoc + _sDig;
      if ((sum - 100).abs() > 0.1) {
        final scale = 100 / sum;
        _sLoc *= scale;
        _sSoc *= scale;
        _sDig *= scale;
      }
    });
  }

  Widget _buildWeightSlider(
    String label,
    double value,
    ValueChanged<double> onChanged,
    Color activeColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
              '${value.toStringAsFixed(0)}%',
              style: TextStyle(color: activeColor, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 100,
          activeColor: activeColor,
          onChanged: onChanged,
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        secondary: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(40),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: Theme.of(context).colorScheme.primary,
        activeTrackColor: Theme.of(context).colorScheme.primary.withAlpha(100),
      ),
    );
  }
}
