import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class ProximityPanel extends StatefulWidget {
  const ProximityPanel({Key? key}) : super(key: key);

  @override
  State<ProximityPanel> createState() => _ProximityPanelState();
}

class _ProximityPanelState extends State<ProximityPanel> with SingleTickerProviderStateMixin {
  late AnimationController _sweepController;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Stack(
                children: [
                   Positioned.fill(
                    child: Opacity(
                      opacity: 0.1,
                      child: CustomPaint(
                        painter: _GridPainter(),
                      ),
                    ),
                  ),
                  _buildRadarSection(),
                ],
              ),
            ),
            _buildSignaturesSection(),
            _buildFooterStatus(),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.gridLines)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.grid_view, color: AppColors.textMuted, size: 28),
              ClipPath(
                clipper: _TopRightChamferClipper(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    border: Border.all(color: AppColors.secondary.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.radar, color: AppColors.secondary, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        'ZONE: LIBRARY_SILENT',
                        style: GoogleFonts.firaCode(
                          color: AppColors.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONTEXT MESH',
                    style: GoogleFonts.rajdhani(
                      color: AppColors.primary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'SENSORS: ACTIVE // BLE_SCAN_INTERVAL: 200ms',
                    style: GoogleFonts.firaCode(
                      color: Colors.grey[600],
                      fontSize: 9,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('NET_ID', style: GoogleFonts.firaCode(color: Colors.grey[600], fontSize: 10)),
                  Text('88:A2:X9', style: GoogleFonts.firaCode(color: Colors.white, fontSize: 14)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRadarSection() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.gridLines)),
      ),
      child: Center(
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gridLines),
          ),
          child: Stack(
            children: [
              // Rings
              Center(child: _buildRing(0.75, dashed: true)),
              Center(child: _buildRing(0.5)),
              Center(child: _buildRing(0.25, dotted: true)),
              
              // Crosshairs
              Center(child: Container(width: double.infinity, height: 1, color: AppColors.gridLines.withOpacity(0.5))),
              Center(child: Container(height: double.infinity, width: 1, color: AppColors.gridLines.withOpacity(0.5))),
              
              // Sweep
              AnimatedBuilder(
                animation: _sweepController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _sweepController.value * 2 * pi,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          center: Alignment.center,
                          startAngle: 0.0,
                          endAngle: pi / 2,
                          colors: [Colors.transparent, Color(0x9939FF14)],
                          stops: [0.0, 1.0],
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              // Center point
              Center(
                child: Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.white, blurRadius: 10)],
                  ),
                ),
              ),
              
              // Blips
              _buildBlip(0.4, 0.6, AppColors.primary, label: 'IPHONE_13_PRO'),
              _buildBlip(0.75, 0.3, AppColors.primary.withOpacity(0.8)),
              _buildBlip(0.15, 0.8, AppColors.primary.withOpacity(0.5)),
              _buildBlip(0.9, 0.55, AppColors.alert, label: 'UNKNOWN_TAG', pulse: true),
              
              // Axis labels
              Positioned(top: 4, left: 0, right: 0, child: Center(child: Text('0°', style: TextStyle(color: AppColors.gridLines, fontSize: 9)))),
              Positioned(right: 4, top: 0, bottom: 0, child: Center(child: Text('90°', style: TextStyle(color: AppColors.gridLines, fontSize: 9)))),
              Positioned(bottom: 4, left: 0, right: 0, child: Center(child: Text('180°', style: TextStyle(color: AppColors.gridLines, fontSize: 9)))),
              Positioned(left: 4, top: 0, bottom: 0, child: Center(child: Text('270°', style: TextStyle(color: AppColors.gridLines, fontSize: 9)))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRing(double scale, {bool dashed = false, bool dotted = false}) {
    return Container(
      width: 300 * scale,
      height: 300 * scale,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.gridLines.withOpacity(0.5),
          style: (dashed || dotted) ? BorderStyle.none : BorderStyle.solid,
        ),
      ),
      child: (dashed || dotted) ? CustomPaint(
        painter: _DashedCirclePainter(
          color: AppColors.gridLines.withOpacity(0.5),
          isDotted: dotted,
        ),
      ) : null,
    );
  }

  Widget _buildBlip(double top, double left, Color color, {String? label, bool pulse = false}) {
    return Positioned(
      top: 300 * top,
      left: 300 * left,
      child: Column(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color, blurRadius: 8)],
            ),
          ),
          if (label != null)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: color),
              ),
              child: Text(
                label,
                style: GoogleFonts.firaCode(color: color, fontSize: 8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSignaturesSection() {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.gridLines)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'DETECTED SIGNATURES (5)',
                  style: GoogleFonts.firaCode(color: Colors.grey[400], fontSize: 10, letterSpacing: 1.5),
                ),
                const Row(
                  children: [
                    Icon(Icons.filter_list, color: AppColors.textMuted, size: 16),
                    SizedBox(width: 8),
                    Icon(Icons.refresh, color: AppColors.textMuted, size: 16),
                  ],
                ),
              ],
            ),
          ),
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
               border: Border(bottom: BorderSide(color: AppColors.gridLines)),
            ),
            child: Row(
              children: [
                Expanded(flex: 5, child: Text('DEVICE ID (MASK)', style: GoogleFonts.firaCode(color: Colors.grey[600], fontSize: 10))),
                Expanded(flex: 3, child: Text('RSSI (DBM)', textAlign: TextAlign.right, style: GoogleFonts.firaCode(color: Colors.grey[600], fontSize: 10))),
                Expanded(flex: 4, child: Text('EST. DIST', textAlign: TextAlign.right, style: GoogleFonts.firaCode(color: Colors.grey[600], fontSize: 10))),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildSignatureRow('DE:4A:21:**', '-42', '1.2m', color: AppColors.primary, icon: Icons.smartphone, isHeader: true),
                _buildSignatureRow('77:1B:09:**', '-68', '4.5m', color: AppColors.secondary, icon: Icons.headphones),
                _buildSignatureRow('A2:99:FF:**', '-82', '8.0m', color: AppColors.textMuted, icon: Icons.watch),
                _buildSignatureRow('UNK_TAG_01', '-35', '0.5m', color: AppColors.alert, icon: Icons.warning, isAlert: true),
                _buildSignatureRow('C4:11:00:**', '-91', '12.4m', color: AppColors.textMuted, icon: Icons.laptop_mac),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureRow(String id, String rssi, String dist, {required Color color, required IconData icon, bool isHeader = false, bool isAlert = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isAlert ? AppColors.alert.withOpacity(0.05) : null,
        border: Border(
           bottom: BorderSide(color: AppColors.gridLines, width: 0.5),
           left: BorderSide(color: isHeader ? AppColors.primary : (isAlert ? AppColors.alert : Colors.transparent), width: 2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 8),
                Text(id, style: GoogleFonts.firaCode(color: color == AppColors.textMuted ? Colors.grey[400] : color, fontSize: 12)),
              ],
            ),
          ),
          Expanded(flex: 3, child: Text(rssi, textAlign: TextAlign.right, style: GoogleFonts.firaCode(color: color, fontSize: 12, fontWeight: FontWeight.bold))),
          Expanded(flex: 4, child: Text(dist, textAlign: TextAlign.right, style: GoogleFonts.firaCode(color: Colors.grey[300], fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildFooterStatus() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.gridLines)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('STATUS: MONITORING', style: GoogleFonts.firaCode(color: Colors.grey[600], fontSize: 10)),
          Text('MESH_VER: v2.0.4', style: GoogleFonts.firaCode(color: Colors.grey[600], fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () {},
      backgroundColor: AppColors.primary,
      shape: const RoundedRectangleBorder(),
      child: Icon(Icons.add, color: Colors.black, size: 32),
    );
  }
}

class _TopRightChamferClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const double chamferSize = 12.0;
    Path path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width - chamferSize, 0);
    path.lineTo(size.width, chamferSize);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final bool isDotted;
  _DashedCirclePainter({required this.color, this.isDotted = false});

  @override
  void paint(Canvas canvas, Size size) {
    double radius = size.width / 2;
    Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    double dashWidth = isDotted ? 2 : 5;
    double dashSpace = isDotted ? 4 : 5;
    double circumference = 2 * pi * radius;
    int dashCount = (circumference / (dashWidth + dashSpace)).floor();

    canvas.save();
    canvas.translate(radius, radius);
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius),
        i * (dashWidth + dashSpace) / radius,
        dashWidth / radius,
        false,
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gridLines.withOpacity(0.5)
      ..strokeWidth = 1;
    
    const double step = 40.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
