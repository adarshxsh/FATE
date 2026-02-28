import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/channels/native_telemetry_bridge.dart';

class PermissionControlScreen extends StatefulWidget {
  const PermissionControlScreen({Key? key}) : super(key: key);

  @override
  State<PermissionControlScreen> createState() => _PermissionControlScreenState();
}

class _PermissionControlScreenState extends State<PermissionControlScreen> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  final ScrollController _logScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
        vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final NativeTelemetryBridge bridge = NativeTelemetryBridge();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                children: [
                  _buildPermissionGatewayNote(),
                  const SizedBox(height: 24),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 24, // Increased spacing for shadows
                    crossAxisSpacing: 24,
                    children: [
                      _buildProtocolCard(
                        title: 'GPS_TELEMETRY',
                        subtitle: 'UPLINK_01',
                        icon: Icons.satellite_alt,
                        isActive: true,
                        onTap: () => bridge.requestUsagePermissions(),
                      ),
                      _buildProtocolCard(
                        title: 'BT_PROXIMITY',
                        subtitle: 'SCAN_RATE_HI',
                        icon: Icons.bluetooth_searching,
                        isActive: true,
                        onTap: () => bridge.requestUsagePermissions(),
                      ),
                      _buildProtocolCard(
                        title: 'USAGE_STATS',
                        subtitle: 'PERM_REQ',
                        icon: Icons.data_usage,
                        isActive: false,
                        onTap: () => bridge.requestUsagePermissions(),
                      ),
                      _buildProtocolCard(
                        title: 'NOTIF_LISTENER',
                        subtitle: 'INTERCEPT_ON',
                        icon: Icons.notifications_active,
                        isActive: true,
                        onTap: () => bridge.requestNotificationPermissions(),
                      ),
                      _buildProtocolCard(
                        title: 'BG_PROCESS',
                        subtitle: 'WAKE_LOCK',
                        icon: Icons.memory,
                        isActive: true,
                        onTap: () {},
                      ),
                      _buildProtocolCard(
                        title: 'GEMINI_UPLINK',
                        subtitle: 'LATENCY_ERR',
                        icon: Icons.psychology_alt,
                        isActive: false,
                        isError: true,
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            _buildSysLog(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: BoxDecoration(
        color: AppColors.background,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('FATE_OS v2.4', style: GoogleFonts.firaCode(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Icon(Icons.wifi, color: AppColors.primary, size: 14),
                  const SizedBox(width: 8),
                  Icon(Icons.battery_charging_full, color: AppColors.primary, size: 14),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: AppColors.neumorphicDecoration(radius: 12),
                    child: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 16),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SYSTEM ACCESS', style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      Text('HARDWARE PROTOCOLS', style: GoogleFonts.firaCode(color: AppColors.textMuted, fontSize: 10, letterSpacing: 1.2)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: AppColors.neumorphicDecoration(radius: 12),
                child: Icon(Icons.sync, color: AppColors.primary, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionGatewayNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppColors.neumorphicPressedDecoration(radius: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(color: AppColors.shadowDark, offset: Offset(4, 4), blurRadius: 8),
                BoxShadow(color: AppColors.shadowLight, offset: Offset(-4, -4), blurRadius: 8),
              ],
            ),
            child: Icon(Icons.shield_outlined, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PERMISSION GATEWAY', style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.0)),
                const SizedBox(height: 4),
                Text(
                  'Manage active sensors to conserve battery.',
                  style: GoogleFonts.firaCode(color: AppColors.textMuted, fontSize: 11, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolCard({
    required String title,
    required String subtitle,
    required IconData icon,
    bool isActive = false,
    bool isError = false,
    required VoidCallback onTap,
  }) {
    final Color color = isError ? AppColors.alert : (isActive ? AppColors.primary : AppColors.textMuted);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: AppColors.neumorphicDecoration(radius: 20),
        child: Stack(
          children: [
            if (isActive || isError)
              Positioned(
                top: 16, right: 16,
                child: Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Icon(icon, color: color, size: 36),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(subtitle, style: GoogleFonts.firaCode(color: color.withOpacity(0.7), fontSize: 9)),
                      const SizedBox(height: 4),
                      Text(title, style: GoogleFonts.rajdhani(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSysLog() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        boxShadow: const [
          BoxShadow(color: AppColors.shadowDark, offset: Offset(0, -6), blurRadius: 16),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SYS_LOG.LOG', style: GoogleFonts.firaCode(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              _buildBlinkingDot(),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: AppColors.neumorphicPressedDecoration(radius: 12),
              child: ListView(
                controller: _logScrollController,
                children: [
                  _buildLogLine('14:02:05', 'SERVICE_STARTED: GPS_Provider initiated successfully.', AppColors.primary),
                  _buildLogLine('14:02:08', 'PERMISSION_GRANT: BT_Admin rights verified.', AppColors.primary),
                  _buildLogLine('14:02:12', 'INFO: Notification_Listener attached to stream.', AppColors.secondary),
                  _buildLogLine('14:02:15', 'DEBUG: Wakelock acquired::Screen_Dim.', AppColors.textMuted),
                  _buildLogLine('14:02:55', 'WARN: Gemini_Uplink latency > 200ms. Retrying...', AppColors.alert),
                  _buildLogLine('14:03:01', 'STATUS: Core systems nominal.', AppColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogLine(String time, String message, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.firaCode(fontSize: 10),
          children: [
            TextSpan(text: '[$time] ', style: TextStyle(color: AppColors.textSecondary)),
            TextSpan(text: message, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildBlinkingDot() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Opacity(
          opacity: _shimmerController.value > 0.5 ? 1.0 : 0.0,
          child: Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 4)])),
        );
      },
    );
  }
}
