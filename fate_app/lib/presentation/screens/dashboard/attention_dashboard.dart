import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../state/dashboard_bloc.dart';

class AttentionDashboard extends StatefulWidget {
  const AttentionDashboard({Key? key}) : super(key: key);

  @override
  State<AttentionDashboard> createState() => _AttentionDashboardState();
}

class _AttentionDashboardState extends State<AttentionDashboard> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Decorative Grid Background
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter(color: AppColors.gridLines.withOpacity(0.2))),
          ),
          
          SafeArea(
            child: BlocBuilder<DashboardBloc, DashboardState>(
              builder: (context, state) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header
                      _buildHeader(),
                      
                      // Hero Section: Focus Ring
                      const SizedBox(height: 24),
                      _NeuralFocusRing(
                        casScore: state.metrics.currentCAS,
                        rotationController: _rotationController,
                      ),
                      
                      const SizedBox(height: 32),
                      // Cognitive Load status
                      _buildStatusIndicator(),
                      
                      const SizedBox(height: 24),
                      // Metrics Grid
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            _FragmentationCard(switches: state.metrics.contextSwitches),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: _SecondaryMetricCard(
                                  title: 'Attention Drift',
                                  value: '+12%',
                                  subtitle: 'Variance > 1h',
                                  icon: Icons.trending_up,
                                  color: AppColors.secondary,
                                )),
                                const SizedBox(width: 16),
                                Expanded(child: _SensorStatusCard()),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      // System Logs
                      _SystemLogTerminal(),
                      
                      const SizedBox(height: 100), // Bottom padding
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.8),
        border: const Border(bottom: BorderSide(color: AppColors.gridLines)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.terminal, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: 'NEURAL', style: GoogleFonts.rajdhani(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 2)),
                    TextSpan(text: 'CORE', style: GoogleFonts.rajdhani(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 2)),
                    TextSpan(text: ' // V.1.0', style: GoogleFonts.rajdhani(color: AppColors.textMuted, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.primary, blurRadius: 8)],
                ),
              ),
              const SizedBox(width: 8),
              Text('SYS:ONLINE', style: GoogleFonts.firaCode(color: AppColors.primary, fontSize: 10, letterSpacing: 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        border: Border.all(color: AppColors.gridLines),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.psychology, color: AppColors.primary, size: 14),
          const SizedBox(width: 12),
          RichText(
            text: TextSpan(
              style: GoogleFonts.firaCode(color: Colors.grey[400], fontSize: 10),
              children: [
                const TextSpan(text: 'COGNITIVE LOAD: '),
                TextSpan(text: 'STABLE', style: TextStyle(color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NeuralFocusRing extends StatelessWidget {
  final double casScore;
  final AnimationController rotationController;

  const _NeuralFocusRing({
    Key? key, 
    required this.casScore,
    required this.rotationController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated Spinners
          AnimatedBuilder(
            animation: rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: rotationController.value * 2 * math.pi,
                child: Container(
                  width: 270,
                  height: 270,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: -rotationController.value * 1.5 * math.pi,
                child: CustomPaint(
                  size: const Size(230, 230),
                  painter: _DashedCirclePainter(color: AppColors.primary.withOpacity(0.05)),
                ),
              );
            },
          ),
          
          // Progress SVG-style Ring
          SizedBox(
            width: 260,
            height: 260,
            child: CustomPaint(
              painter: _RingPainter(
                progress: casScore / 100,
                color: AppColors.primary,
                trackColor: AppColors.gridLines,
              ),
            ),
          ),
          
          // Inner Data
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: casScore.toInt().toString(), style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 72, fontWeight: FontWeight.bold)),
                    TextSpan(text: '%', style: GoogleFonts.rajdhani(color: AppColors.primary.withOpacity(0.8), fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.primary.withOpacity(0.3)))),
                child: Text('FOCUS INTEGRITY', style: GoogleFonts.firaCode(color: AppColors.primary, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 4),
              Text('OPTIMAL STATE', style: GoogleFonts.firaCode(color: AppColors.textMuted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FragmentationCard extends StatelessWidget {
  final int switches;
  const _FragmentationCard({Key? key, required this.switches}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: ChamferedClipper(chamferSize: 12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.gridLines),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fragmentation'.toUpperCase(), style: GoogleFonts.firaCode(color: AppColors.textMuted, fontSize: 10, letterSpacing: 2)),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('2.4', style: GoogleFonts.rajdhani(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Text('sw/min', style: GoogleFonts.firaCode(color: AppColors.alert, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const Icon(Icons.broken_image, color: AppColors.alert, size: 24),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 64,
              width: double.infinity,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(32, (index) {
                  final double hFactor = (math.Random().nextDouble() * 0.4) + (index == 10 || index == 11 ? 0.5 : 0.1);
                  final Color barColor = (index == 10 || index == 11) ? AppColors.alert : AppColors.primary;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      height: 64 * hFactor,
                      decoration: BoxDecoration(
                        color: barColor.withOpacity(hFactor > 0.4 ? 1.0 : 0.2),
                        boxShadow: hFactor > 0.4 ? [BoxShadow(color: barColor, blurRadius: 4)] : null,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SecondaryMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SecondaryMetricCard({
    Key? key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: ChamferedClipper(chamferSize: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.gridLines),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title.toUpperCase(), style: GoogleFonts.firaCode(color: AppColors.textMuted, fontSize: 9, letterSpacing: 1)),
                const SizedBox(height: 8),
                Text(value, style: GoogleFonts.rajdhani(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: GoogleFonts.firaCode(color: Colors.grey[400], fontSize: 9)),
              ],
            ),
            Positioned(
              right: -4,
              top: -4,
              child: Icon(icon, color: color, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _SensorStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: ChamferedClipper(chamferSize: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.gridLines),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Active Sensors'.toUpperCase(), style: GoogleFonts.firaCode(color: AppColors.textMuted, fontSize: 9, letterSpacing: 1)),
            const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.primary, blurRadius: 4)],
                    ),
                  ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.gridLines,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('3/4 ONLINE', style: GoogleFonts.firaCode(color: AppColors.primary, fontSize: 9)),
          ],
        ),
      ),
    );
  }
}

class _SystemLogTerminal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 100,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        border: const Border(top: BorderSide(color: AppColors.gridLines)),
      ),
      child: Stack(
        children: [
          Positioned(left: 0, top: 0, bottom: 0, width: 2, child: Container(color: AppColors.primary.withOpacity(0.3))),
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(), // Just showing static content as visual
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _logLine('> INITIATING NEURAL LINK...', AppColors.textMuted),
                    _logLine('> SENSOR ARRAY [BLE_01] CONNECTED', AppColors.textMuted),
                    _logLine('> DETECTING AMBIENT NOISE: 42dB', AppColors.textMuted),
                    _logLine('> FOCUS STATE LOCKED', AppColors.primary),
                    _logLine('> AWAITING INPUT...', AppColors.primary, animate: true),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 32,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, AppColors.background.withOpacity(0.9)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logLine(String text, Color color, {bool animate = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(text, style: GoogleFonts.firaCode(color: color, fontSize: 10)),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _RingPainter({required this.progress, required this.color, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    
    // Draw track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // Draw dashed track
    const dashCount = 60;
    const dashWidth = 0.05;
    for (var i = 0; i < dashCount; i++) {
      final angle = (i * 2 * math.pi / dashCount);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        angle,
        dashWidth,
        false,
        trackPaint,
      );
    }
    
    // Draw Progress
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.butt;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint..maskFilter = null,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.progress != progress;
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);
    
    const dashWidth = 10.0;
    const dashSpace = 5.0;
    double currentAngle = 0;
    
    while (currentAngle < 2 * math.pi) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        dashWidth / radius,
        false,
        paint,
      );
      currentAngle += (dashWidth + dashSpace) / radius;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (var i = 0.0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (var i = 0.0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ChamferedClipper extends CustomClipper<Path> {
  final double chamferSize;
  ChamferedClipper({this.chamferSize = 12});

  @override
  Path getClip(Size size) {
    final path = Path();
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
