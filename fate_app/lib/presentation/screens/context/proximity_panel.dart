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
                      opacity: 0.03,
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.background,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: AppColors.neumorphicDecoration(radius: 12),
                child: Icon(Icons.grid_view_rounded, color: AppColors.textPrimary, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: AppColors.neumorphicPressedDecoration(radius: 20),
                child: Row(
                  children: [
                    Icon(Icons.radar, color: AppColors.secondary, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      'ZONE: LIBRARY',
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
            ],
          ),
          const SizedBox(height: 24),
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
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'SENSORS: ACTIVE // BLE_SCAN: 200ms',
                    style: GoogleFonts.firaCode(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('NET_ID', style: GoogleFonts.firaCode(color: AppColors.textMuted, fontSize: 10)),
                  Text('88:A2:X9', style: GoogleFonts.firaCode(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold)),
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
      child: Center(
        child: Container(
          width: 300,
          height: 300,
          decoration: AppColors.neumorphicPressedDecoration(radius: 150),
          child: Stack(
            children: [
              // Rings - styled softly instead of sharp lines
              Center(child: _buildRing(0.75, dashed: true)),
              Center(child: _buildRing(0.5)),
              Center(child: _buildRing(0.25, dotted: true)),
              
              // Crosshairs
              Center(child: Container(width: double.infinity, height: 1, color: AppColors.gridLines)),
              Center(child: Container(height: double.infinity, width: 1, color: AppColors.gridLines)),
              
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
                          colors: [Colors.transparent, AppColors.primary.withOpacity(0.3)],
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
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(color: AppColors.shadowDark, offset: Offset(2, 2), blurRadius: 4),
                      BoxShadow(color: AppColors.shadowLight, offset: Offset(-2, -2), blurRadius: 4),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    ),
                  ),
                ),
              ),
              
              // Blips
              _buildBlip(0.35, 0.65, AppColors.primary, label: 'IPHONE_13_PRO'),
              _buildBlip(0.75, 0.3, AppColors.secondary),
              _buildBlip(0.15, 0.8, AppColors.primary.withOpacity(0.5)),
              _buildBlip(0.85, 0.55, AppColors.alert, label: 'UNKNOWN_TAG', pulse: true),
              
              // Axis labels
              Positioned(top: 8, left: 0, right: 0, child: Center(child: Text('0°', style: GoogleFonts.firaCode(color: AppColors.textMuted, fontSize: 9)))),
              Positioned(right: 8, top: 0, bottom: 0, child: Center(child: Text('90°', style: GoogleFonts.firaCode(color: AppColors.textMuted, fontSize: 9)))),
              Positioned(bottom: 8, left: 0, right: 0, child: Center(child: Text('180°', style: GoogleFonts.firaCode(color: AppColors.textMuted, fontSize: 9)))),
              Positioned(left: 8, top: 0, bottom: 0, child: Center(child: Text('270°', style: GoogleFonts.firaCode(color: AppColors.textMuted, fontSize: 9)))),
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
          color: AppColors.gridLines,
          width: 1,
          style: (dashed || dotted) ? BorderStyle.none : BorderStyle.solid,
        ),
      ),
      child: (dashed || dotted) ? CustomPaint(
        painter: _DashedCirclePainter(
          color: AppColors.gridLines,
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
            width: 12, height: 12,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(color: AppColors.shadowDark, offset: Offset(2, 2), blurRadius: 4),
                BoxShadow(color: AppColors.shadowLight, offset: Offset(-2, -2), blurRadius: 4),
              ],
            ),
            child: Center(
              child: Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: color.withOpacity(0.8), blurRadius: 6)],
                ),
              ),
            ),
          ),
          if (label != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: AppColors.neumorphicPressedDecoration(radius: 8),
                child: Text(
                  label,
                  style: GoogleFonts.firaCode(color: color, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSignaturesSection() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Container(
          decoration: AppColors.neumorphicDecoration(radius: 24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.shadowDark.withOpacity(0.5))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DETECTED SIGNATURES',
                      style: GoogleFonts.firaCode(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: AppColors.neumorphicPressedDecoration(radius: 8),
                      child: Text('5', style: GoogleFonts.firaCode(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildSignatureRow('DE:4A:21:**', '-42', '1.2m', color: AppColors.primary, icon: Icons.smartphone),
                    _buildSignatureRow('77:1B:09:**', '-68', '4.5m', color: AppColors.secondary, icon: Icons.headphones),
                    _buildSignatureRow('A2:99:FF:**', '-82', '8.0m', color: AppColors.textMuted, icon: Icons.watch),
                    _buildSignatureRow('UNK_TAG_01', '-35', '0.5m', color: AppColors.alert, icon: Icons.warning_rounded),
                    _buildSignatureRow('C4:11:00:**', '-91', '12.4m', color: AppColors.textMuted, icon: Icons.laptop_mac),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignatureRow(String id, String rssi, String dist, {required Color color, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: AppColors.neumorphicPressedDecoration(radius: 16),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHighlight.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 14),
                  ),
                  const SizedBox(width: 12),
                  Text(id, style: GoogleFonts.firaCode(color: AppColors.textPrimary, fontSize: 12)),
                ],
              ),
            ),
            Expanded(flex: 3, child: Text(rssi, textAlign: TextAlign.center, style: GoogleFonts.firaCode(color: color, fontSize: 12, fontWeight: FontWeight.bold))),
            Expanded(flex: 3, child: Text(dist, textAlign: TextAlign.right, style: GoogleFonts.firaCode(color: AppColors.textMuted, fontSize: 12))),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 4)])),
              const SizedBox(width: 8),
              Text('MONITORING', style: GoogleFonts.firaCode(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          Text('MESH_v2.0.4', style: GoogleFonts.firaCode(color: AppColors.textMuted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, right: 8),
      decoration: AppColors.neumorphicDecoration(radius: 30),
      child: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.surface,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Icon(Icons.add, color: AppColors.primary, size: 28),
      ),
    );
  }
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

    double dashWidth = isDotted ? 2 : 6;
    double dashSpace = isDotted ? 6 : 8;
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
