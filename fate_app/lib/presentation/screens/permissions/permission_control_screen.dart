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
        child: Stack(
          children: [
            // Scanlines
            Positioned.fill(child: Opacity(opacity: 0.1, child: CustomPaint(painter: _ScanlinePainter()))),
            Column(
              children: [
                _buildHeader(),
                _buildShimmerLine(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildPermissionGatewayNote(),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
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
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                _buildSysLog(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.background,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('FATE_OS v2.4', style: GoogleFonts.firaCode(color: AppColors.primary.withOpacity(0.6), fontSize: 10)),
              Row(
                children: [
                  Icon(Icons.wifi, color: AppColors.primary.withOpacity(0.6), size: 14),
                  const SizedBox(width: 8),
                  Icon(Icons.battery_charging_full, color: AppColors.primary.withOpacity(0.6), size: 14),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SYSTEM_ACCESS', style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      Text('HARDWARE PROTOCOLS // ADMIN', style: GoogleFonts.firaCode(color: AppColors.textMuted, fontSize: 9, letterSpacing: 1.2)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Text('REFRESH', style: GoogleFonts.rajdhani(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Icon(Icons.sync, color: AppColors.primary, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLine() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          height: 2,
          width: double.infinity,
          color: AppColors.gridLines,
          child: Stack(
            children: [
              Positioned(
                left: _shimmerController.value * MediaQuery.of(context).size.width,
                width: MediaQuery.of(context).size.width * 0.3,
                top: 0, bottom: 0,
                child: Container(color: AppColors.primary),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPermissionGatewayNote() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.primary, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PERMISSION GATEWAY', style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Text(
            'Active sensors are consuming battery. Grant access only to required modules.',
            style: GoogleFonts.firaCode(color: Colors.grey[400], fontSize: 10, height: 1.4),
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
      child: ClipPath(
        clipper: _ChamferClipper(),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: color.withOpacity(isError || isActive ? 1.0 : 0.3)),
            boxShadow: isActive || isError ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10)] : null,
          ),
          child: Stack(
            children: [
              if (isActive || isError)
                Positioned(
                  top: 12, right: 12,
                  child: Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: color, blurRadius: 8)],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Center(
                        child: Icon(icon, color: color, size: 48),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(subtitle, style: GoogleFonts.firaCode(color: color.withOpacity(0.7), fontSize: 9)),
                        Text(title, style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
              // Corner accents
              Positioned(bottom: 0, left: 0, child: Container(width: 12, height: 12, decoration: BoxDecoration(border: Border(left: BorderSide(color: color), bottom: BorderSide(color: color))))),
              Positioned(top: 0, right: 0, child: Container(width: 12, height: 12, decoration: BoxDecoration(border: Border(right: BorderSide(color: color), top: BorderSide(color: color))))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSysLog() {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFF080A08),
        border: Border(top: BorderSide(color: AppColors.gridLines)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                color: AppColors.primary.withOpacity(0.1),
                child: Text('SYS_LOG.LOG', style: GoogleFonts.firaCode(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ),
              _buildBlinkingDot(),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              controller: _logScrollController,
              children: [
                _buildLogLine('14:02:05', 'SERVICE_STARTED: GPS_Provider initiated successfully.', AppColors.primary),
                _buildLogLine('14:02:08', 'PERMISSION_GRANT: BT_Admin rights verified.', AppColors.primary),
                _buildLogLine('14:02:12', 'INFO: Notification_Listener attached to stream.', AppColors.secondary),
                _buildLogLine('14:02:15', 'DEBUG: Wakelock acquired::Screen_Dim.', Colors.grey[700]!),
                _buildLogLine('14:02:55', 'WARN: Gemini_Uplink latency > 200ms. Retrying handshake...', AppColors.alert),
                _buildLogLine('14:03:01', 'STATUS: Core systems nominal. Waiting for user input_', AppColors.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogLine(String time, String message, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.firaCode(fontSize: 9),
          children: [
            TextSpan(text: '[$time] ', style: TextStyle(color: AppColors.primary)),
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
          child: Container(width: 6, height: 6, decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
        );
      },
    );
  }
}

class _ChamferClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const double chamferSize = 12.0;
    Path path = Path();
    path.moveTo(chamferSize, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - chamferSize);
    path.lineTo(size.width - chamferSize, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, chamferSize);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..strokeWidth = 1;
    
    for (double i = 0; i < size.height; i += 4) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
