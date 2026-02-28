import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../main.dart'; // Added to access AuthWrapper

class FateLoadingScreen extends StatefulWidget {
  const FateLoadingScreen({Key? key}) : super(key: key);

  @override
  State<FateLoadingScreen> createState() => _FateLoadingScreenState();
}

class _FateLoadingScreenState extends State<FateLoadingScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _rotationController;
  
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  final List<String> _bootSequenceLogs = [
    "INITIALIZING KERNEL...",
    "ESTABLISHING SECURE NATIVE CHANNEL...",
    "MOUNTING USAGE_STATS LISTENER...",
    "CALIBRATING BLUETOOTH LE SCANNER...",
    "LOCKING FUSED LOCATION PROVIDER...",
    "WAKING GENERATIVE AI ENGINE...",
    "F.A.T.E. SYSTEM ONLINE."
  ];

  String _currentLog = "";
  int _logIndex = 0;
  Timer? _typewriterTimer;
  Timer? _sequenceTimer;

  @override
  void initState() {
    super.initState();

    // 1. Core Pulsing Animation (Breathing effect)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 2. Continuous Rotation for Orbital Scanner Rings
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // 3. Progress Bar Animation
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500), // Total loading time
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.decelerate),
    );

    _progressController.forward().then((_) {
      // Transition to Main App
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const AuthWrapper(),
          transitionDuration: const Duration(milliseconds: 1000),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });

    _startBootSequence();
  }

  void _startBootSequence() {
    _sequenceTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (_logIndex < _bootSequenceLogs.length) {
        _typewriteLog(_bootSequenceLogs[_logIndex]);
        _logIndex++;
      } else {
        timer.cancel();
      }
    });
  }

  void _typewriteLog(String fullString) {
    _currentLog = "";
    int charIndex = 0;
    _typewriterTimer?.cancel();
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 15), (timer) {
      if (charIndex < fullString.length) {
        setState(() {
          _currentLog += fullString[charIndex];
        });
        charIndex++;
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _progressController.dispose();
    _typewriterTimer?.cancel();
    _sequenceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Background Gradient Ambience
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Color(0xFF0A0E27),
                    AppColors.backgroundDark,
                  ],
                ),
              ),
            ),
          ),
          
          // Center Animation Matrix
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 280,
                  height: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer Rotating Telemetry Rings (Custom Painter)
                      AnimatedBuilder(
                        animation: _rotationController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotationController.value * 2 * math.pi,
                            child: CustomPaint(
                              size: const Size(280, 280),
                              painter: TelemetryOrbitalPainter(),
                            ),
                          );
                        },
                      ),
                      
                      // Counter-Rotating Inner Rings
                      AnimatedBuilder(
                        animation: _rotationController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: -_rotationController.value * 2 * math.pi * 1.5,
                            child: CustomPaint(
                              size: const Size(220, 220),
                              painter: TelemetryInnerPainter(),
                            ),
                          );
                        },
                      ),

                      // Core Pulsing SVG Logo
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.neonCyan.withOpacity(math.max(0.0, 0.3 * (_pulseAnimation.value - 0.8))),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                  BoxShadow(
                                    color: AppColors.neonPurple.withOpacity(math.max(0.0, 0.2 * (_pulseAnimation.value - 0.8))),
                                    blurRadius: 60,
                                    spreadRadius: 20,
                                  ),
                                ],
                              ),
                              child: SvgPicture.asset(
                                'assets/icons/fate_logo.svg',
                                width: 140,
                                height: 140,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 60),

                // Main Title
                Text(
                  "F A T E",
                  style: GoogleFonts.syncopate(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: 12.0,
                    shadows: [
                      const BoxShadow(
                        color: AppColors.neonCyan,
                        blurRadius: 10,
                      ),
                      const BoxShadow(
                        color: AppColors.deepPurple,
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Subtitle
                Text(
                  "Focus & Attention Telemetry Engine",
                  style: GoogleFonts.rajdhani(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.neonCyan.withOpacity(0.8),
                    letterSpacing: 2.0,
                  ),
                ),

                const SizedBox(height: 60),

                // Dynamic Tech Boot Logs
                SizedBox(
                  height: 20,
                  child: Text(
                    "> $_currentLog",
                    style: GoogleFonts.firaCode(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Cyber-styled Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50.0),
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "SYS_BOOT",
                                style: GoogleFonts.rajdhani(
                                  fontSize: 10,
                                  color: AppColors.neonCyan,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "${(_progressAnimation.value * 100).toInt()}%",
                                style: GoogleFonts.rajdhani(
                                  fontSize: 10,
                                  color: AppColors.neonCyan,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 4,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.backgroundCard,
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(color: AppColors.deepPurple.withOpacity(0.3), width: 0.5),
                            ),
                            child: Stack(
                              children: [
                                Container(
                                  width: (size.width - 100) * _progressAnimation.value,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(2),
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.deepPurple,
                                        AppColors.neonCyan,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.neonCyan.withOpacity(0.5),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CUSTOM PAINTERS FOR UI ORBITAL EFFECTS
// ============================================================================

class TelemetryOrbitalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer thin solid ring
    final paintThin = Paint()
      ..color = AppColors.deepPurple.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawCircle(center, radius, paintThin);

    // Thick dashed arc segments simulating data scanning
    final paintArc1 = Paint()
      ..shader = const SweepGradient(
        colors: [AppColors.neonCyan, AppColors.deepPurple, Colors.transparent],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final paintArc2 = Paint()
      ..shader = const SweepGradient(
        colors: [AppColors.neonPurple, AppColors.deepCyan, Colors.transparent],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // Draw three distinct arcs (120 degrees apart)
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 5), 0, math.pi / 2.5, false, paintArc1);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 5), math.pi * 0.8, math.pi / 3, false, paintArc2);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius - 5), math.pi * 1.5, math.pi / 2, false, paintArc1);
    
    // Draw targeting nodes on the outer ring
    final nodePaint = Paint()..color = AppColors.neonCyan;
    canvas.drawCircle(Offset(center.dx + (radius - 5) * math.cos(0), center.dy + (radius - 5) * math.sin(0)), 3, nodePaint);
    canvas.drawCircle(Offset(center.dx + (radius - 5) * math.cos(math.pi * 0.8), center.dy + (radius - 5) * math.sin(math.pi * 0.8)), 3, nodePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TelemetryInnerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paintDashed = Paint()
      ..color = AppColors.textSecondary.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw manual dashes for inner ring
    const int dashCount = 36;
    const double dashAngle = (2 * math.pi) / dashCount;
    const double dashSweep = dashAngle * 0.4; // 40% solid, 60% empty

    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * dashAngle,
        dashSweep,
        false,
        paintDashed,
      );
    }

    // Highlighted inner segments
    final highlightPaint = Paint()
      ..color = AppColors.neonCyan.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), 0, math.pi / 4, false, highlightPaint);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi, math.pi / 4, false, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
