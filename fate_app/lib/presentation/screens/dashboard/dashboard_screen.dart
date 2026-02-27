import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late AnimationController _blinkController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
       vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    _pulseController = AnimationController(
       vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                   painter: _GridPainter(),
                ),
              ),
            ),
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                    child: Column(
                      children: [
                        _buildFocusRing(),
                        const SizedBox(height: 40),
                        _buildFragmentationWidget(),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSecondaryMetric(
                                title: 'Attention Drift',
                                value: '+12%',
                                subValue: 'Variance > 1h',
                                valueColor: AppColors.secondary,
                                icon: Icons.trending_up,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildActiveSensorsMetric(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSystemLogs(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.8),
        border: const Border(bottom: BorderSide(color: AppColors.gridLines)),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              FadeTransition(
                opacity: _blinkController,
                child: const Icon(Icons.terminal, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'NEURALCORE // V.1.0',
                style: GoogleFonts.rajdhani(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
          Row(
            children: [
              FadeTransition(
                 opacity: _blinkController,
                 child: Container(
                   width: 8, height: 8,
                   decoration: const BoxDecoration(
                     color: AppColors.primary,
                     shape: BoxShape.circle,
                     boxShadow: [BoxShadow(color: AppColors.primary, blurRadius: 8)],
                   ),
                 ),
              ),
              const SizedBox(width: 8),
              Text(
                'SYS:ONLINE',
                style: GoogleFonts.firaCode(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ]
          )
        ],
      ),
    );
  }

  Widget _buildFocusRing() {
    return Center(
      child: Container(
        width: 280,
        height: 280,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _DashedRingPainter()),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 0.86),
              duration: const Duration(seconds: 2),
              builder: (context, value, child) {
                return CircularProgressIndicator(
                  value: value,
                  strokeWidth: 4,
                  backgroundColor: Colors.transparent,
                  color: AppColors.primary,
                );
              },
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      Text(
                        '86',
                        style: GoogleFonts.rajdhani(
                          color: AppColors.textPrimary,
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                         '%',
                         style: GoogleFonts.rajdhani(
                          color: AppColors.primary.withOpacity(0.8),
                          fontSize: 24,
                        ),
                      ),
                   ],
                ),
                Text(
                  'FOCUS INTEGRITY',
                  style: GoogleFonts.firaCode(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'OPTIMAL STATE',
                  style: GoogleFonts.firaCode(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFragmentationWidget() {
    return CustomPaint(
      painter: _ChamferedPainter(
        color: AppColors.surface,
        borderColor: AppColors.gridLines,
      ),
      child: ClipPath(
        clipper: _ChamferedClipper(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                        Text(
                          'FRAGMENTATION',
                          style: GoogleFonts.firaCode(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                           crossAxisAlignment: CrossAxisAlignment.baseline,
                           textBaseline: TextBaseline.alphabetic,
                           children: [
                              Text(
                                '2.4',
                                style: GoogleFonts.rajdhani(
                                  color: AppColors.textPrimary,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'sw/min',
                                style: GoogleFonts.firaCode(
                                  color: AppColors.alert,
                                  fontSize: 12,
                                ),
                              ),
                           ],
                        )
                     ],
                  ),
                  Icon(Icons.broken_image, color: AppColors.alert.withOpacity(0.8), size: 24),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 64,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(40, (index) {
                    final heightRandom = Random(index).nextDouble();
                    final isAlert = index == 12 || index == 25 || index == 26 || index == 35;
                    final heightPercentage = isAlert ? 0.9 + (heightRandom * 0.1) : (heightRandom * 0.4 + 0.1);
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        height: 64 * heightPercentage,
                        decoration: BoxDecoration(
                           color: isAlert ? AppColors.alert : AppColors.primary.withOpacity(0.4),
                           boxShadow: isAlert ? [const BoxShadow(color: AppColors.alert, blurRadius: 8)] : null,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryMetric({
    required String title,
    required String value,
    required String subValue,
    required Color valueColor,
    required IconData icon,
  }) {
    return CustomPaint(
      painter: _ChamferedPainter(
        color: AppColors.surface,
        borderColor: AppColors.gridLines,
        chamferSize: 8.0,
      ),
      child: ClipPath(
        clipper: _ChamferedClipper(chamferSize: 8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                    Text(
                      title.toUpperCase(),
                      style: GoogleFonts.firaCode(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Icon(icon, color: AppColors.secondary, size: 16),
                 ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.rajdhani(
                  color: valueColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subValue,
                style: GoogleFonts.firaCode(
                  color: Colors.grey[400],
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSensorsMetric() {
     return CustomPaint(
      painter: _ChamferedPainter(
        color: AppColors.surface,
        borderColor: AppColors.gridLines,
        chamferSize: 8.0,
      ),
      child: ClipPath(
        clipper: _ChamferedClipper(chamferSize: 8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ACTIVE SENSORS',
                style: GoogleFonts.firaCode(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                 mainAxisAlignment: MainAxisAlignment.start,
                 children: [
                    _buildStatusDot(true),
                    const SizedBox(width: 8),
                    _buildStatusDot(true),
                    const SizedBox(width: 8),
                    _buildStatusDot(true),
                    const SizedBox(width: 8),
                    _buildStatusDot(false),
                 ],
              ),
              const SizedBox(height: 12),
              Text(
                '3/4 ONLINE',
                style: GoogleFonts.firaCode(
                  color: AppColors.primary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusDot(bool active) {
     return Container(
        width: 8, height: 8,
        decoration: BoxDecoration(
           shape: BoxShape.circle,
           color: active ? AppColors.primary : AppColors.gridLines,
           boxShadow: active ? [const BoxShadow(color: AppColors.primary, blurRadius: 4)] : null,
        ),
     );
  }

  Widget _buildSystemLogs() {
     return Container(
        height: 100,
        decoration: BoxDecoration(
           color: Colors.black.withOpacity(0.5),
           border: const Border(top: BorderSide(color: AppColors.gridLines, width: 1)),
        ),
        child: Stack(
           children: [
              Positioned(
                 left: 0, top: 0, bottom: 0,
                 child: Container(width: 4, color: AppColors.primary.withOpacity(0.3)),
              ),
              Padding(
                 padding: const EdgeInsets.all(12),
                 child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                       Text('> INITIATING NEURAL LINK...', style: GoogleFonts.firaCode(color: AppColors.textMuted, fontSize: 10)),
                       Text('> SENSOR ARRAY [BLE_01] CONNECTED', style: GoogleFonts.firaCode(color: AppColors.textMuted, fontSize: 10)),
                       Text('> DETECTING AMBIENT NOISE: 42dB', style: GoogleFonts.firaCode(color: AppColors.textMuted, fontSize: 10)),
                       Text('> FOCUS STATE LOCKED', style: GoogleFonts.firaCode(color: AppColors.primary, fontSize: 10)),
                       FadeTransition(
                          opacity: _blinkController,
                          child: Text('> AWAITING INPUT...', style: GoogleFonts.firaCode(color: AppColors.textMuted, fontSize: 10)),
                       ),
                    ],
                 ),
              )
           ],
        ),
     );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.gridLines, width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            'LIVE FEED',
            style: GoogleFonts.firaCode(
              color: AppColors.primary,
              fontSize: 10,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 24,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(30, (index) {
                  return AnimatedBuilder(
                     animation: _pulseController,
                     builder: (context, _) {
                         final heightRandom = Random(index * DateTime.now().millisecondsSinceEpoch).nextDouble();
                         return Expanded(
                           child: Container(
                           margin: const EdgeInsets.symmetric(horizontal: 1),
                           height: 24 * (heightRandom * 0.7 + 0.3),
                           color: AppColors.primary.withOpacity(0.8),
                           ),
                        );
                     },
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChamferedClipper extends CustomClipper<Path> {
  final double chamferSize;
  _ChamferedClipper({this.chamferSize = 12.0});

  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, chamferSize)
      ..lineTo(chamferSize, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - chamferSize)
      ..lineTo(size.width - chamferSize, size.height)
      ..lineTo(0, size.height)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ChamferedPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final double chamferSize;

  _ChamferedPainter({required this.color, required this.borderColor, this.chamferSize = 12.0});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, chamferSize)
      ..lineTo(chamferSize, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - chamferSize)
      ..lineTo(size.width - chamferSize, size.height)
      ..lineTo(0, size.height)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashedRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double radius = size.width / 2;
    Paint paint = Paint()
      ..color = AppColors.gridLines
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    double dashWidth = 4;
    double dashSpace = 4;
    double circumference = 2 * pi * radius;
    int dashCount = (circumference / (dashWidth + dashSpace)).floor();
    
    canvas.save();
    canvas.translate(radius, radius);
    for (int i = 0; i < dashCount; i++) {
      canvas.drawLine(Offset(0, -radius), Offset(0, -radius + paint.strokeWidth), paint);
      canvas.rotate(2 * pi / dashCount);
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
