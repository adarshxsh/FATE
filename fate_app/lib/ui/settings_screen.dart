import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../logic/telemetry_provider.dart';
import 'theme.dart';

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
  bool _ignoreBatteryOptimizations = false;

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
    _ignoreBatteryOptimizations =
        await Permission.ignoreBatteryOptimizations.isGranted;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FateColors.bgDeep,
      body: Consumer<TelemetryProvider>(
        builder: (context, telemetry, child) {
          if (!_isInit && !telemetry.isLoadingSettings) {
            _sLoc = telemetry.spatialWeight * 100;
            _sSoc = telemetry.socialWeight * 100;
            _sDig = telemetry.digitalWeight * 100;
            _isInit = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() {});
            });
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 100,
                floating: true,
                pinned: false,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: Text(
                    'Settings',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Scoring Priorities ──
                    SectionHeader(
                      title: 'Scoring Priorities',
                      badge: '100% Total',
                      icon: Icons.tune_rounded,
                    ),
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildWeightSlider('Spatial Activity', _sLoc, (val) {
                            _updateSliders('loc', val);
                          }, FateColors.coolGradient),
                          const SizedBox(height: 8),
                          _buildWeightSlider('Social Engagement', _sSoc, (val) {
                            _updateSliders('soc', val);
                          }, FateColors.warmGradient),
                          const SizedBox(height: 8),
                          _buildWeightSlider('Digital Processing', _sDig, (
                            val,
                          ) {
                            _updateSliders('dig', val);
                          }, FateColors.purpleGradient),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: telemetry.isLoadingSettings
                                    ? null
                                    : FateColors.heroGradient,
                                color: telemetry.isLoadingSettings
                                    ? FateColors.bgElevated
                                    : null,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: telemetry.isLoadingSettings
                                      ? null
                                      : () async {
                                          final ok = await telemetry
                                              .saveSettings(
                                                _sLoc / 100.0,
                                                _sSoc / 100.0,
                                                _sDig / 100.0,
                                              );
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  ok
                                                      ? 'Configuration Saved ✓'
                                                      : 'Failed to save',
                                                  style: GoogleFonts.outfit(),
                                                ),
                                                backgroundColor: ok
                                                    ? const Color(
                                                        0xFF00E676,
                                                      ).withAlpha(200)
                                                    : const Color(0xFFFF5252),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                  child: Center(
                                    child: telemetry.isLoadingSettings
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: FateColors.primary,
                                            ),
                                          )
                                        : Text(
                                            'Save Parameters',
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Permissions ──
                    const SectionHeader(
                      title: 'Permissions',
                      icon: Icons.security_rounded,
                    ),
                    _buildPermissionTile(
                      title: 'Notification Access',
                      subtitle: 'Read message context & distractions',
                      icon: Icons.notifications_active_rounded,
                      value: telemetry.notificationEnabled,
                      gradient: FateColors.warmGradient,
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
                    const SizedBox(height: 10),
                    _buildPermissionTile(
                      title: 'App Usage Access',
                      subtitle: 'Monitor foreground app usage',
                      icon: Icons.app_blocking_rounded,
                      value: telemetry.usageEnabled,
                      gradient: FateColors.heroGradient,
                      onChanged: (val) async {
                        if (val) {
                          await _channel.invokeMethod('requestUsagePermission');
                          telemetry.setUsageEnabled(true);
                        } else {
                          telemetry.setUsageEnabled(false);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildPermissionTile(
                      title: 'Nearby Data Access',
                      subtitle: 'Discover social context & peers',
                      icon: Icons.bluetooth_connected_rounded,
                      value: _nearbyAccess,
                      gradient: FateColors.purpleGradient,
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
                    const SizedBox(height: 10),
                    _buildPermissionTile(
                      title: 'Location Context',
                      subtitle: 'Build geographical study habits',
                      icon: Icons.location_on_rounded,
                      value: _locationAccess,
                      gradient: FateColors.coolGradient,
                      onChanged: (val) async {
                        setState(() => _locationAccess = val);
                        if (val) {
                          await Permission.location.request();
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildPermissionTile(
                      title: 'Run Always in Background',
                      subtitle: 'Ensure tracking stays alive efficiently',
                      icon: Icons.battery_charging_full_rounded,
                      value: _ignoreBatteryOptimizations,
                      gradient: FateColors.warmGradient,
                      onChanged: (val) async {
                        setState(() => _ignoreBatteryOptimizations = val);
                        if (val) {
                          await Permission.ignoreBatteryOptimizations.request();
                        }
                      },
                    ),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
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
    LinearGradient gradient,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: FateColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${value.toStringAsFixed(0)}%',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: FateColors.primary,
            inactiveTrackColor: Colors.white.withAlpha(10),
            thumbColor: FateColors.primary,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            trackHeight: 4,
            overlayColor: FateColors.primary.withAlpha(30),
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value),
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOutCubic,
            builder: (context, animValue, _) {
              return Slider(
                value: animValue,
                min: 0,
                max: 100,
                onChanged: onChanged,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required LinearGradient gradient,
    required ValueChanged<bool> onChanged,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: FateColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: FateColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: FateColors.primary,
            activeTrackColor: FateColors.primary.withAlpha(80),
            inactiveTrackColor: Colors.white.withAlpha(15),
            inactiveThumbColor: FateColors.textMuted,
          ),
        ],
      ),
    );
  }
}
