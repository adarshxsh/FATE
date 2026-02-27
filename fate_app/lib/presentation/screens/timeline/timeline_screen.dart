import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({Key? key}) : super(key: key);

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Grid
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: CustomPaint(
                painter: _GridPainter(color: AppColors.primary),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildHistogram(),
                Expanded(
                  child: Stack(
                    children: [
                      // Vertical Time Column BG
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: 0,
                        width: 64,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(0x4D0F1110), // AppColors.surface.withOpacity(0.3)
                            border: Border(right: BorderSide(color: AppColors.gridLines)),
                          ),
                        ),
                      ),
                      
                      ListView(
                        padding: const EdgeInsets.only(top: 24, bottom: 84, left: 8, right: 16),
                        children: [
                          _buildTimelineItem(
                            time: "09:00",
                            icon: Icons.terminal,
                            title: "VS CODE",
                            tag: "DEV_ENV",
                            subtitle: "Project: Neural_Net_v2",
                            duration: "45m 20s",
                            color: AppColors.primary,
                            isLong: true,
                          ),
                          _buildTimelineItem(
                            time: "09:45",
                            icon: Icons.storage,
                            title: "POSTGRES",
                            tag: "DB_OPS",
                            subtitle: "Query Analysis",
                            duration: "12m 15s",
                            color: AppColors.primary,
                          ),
                          _buildDashedTimelineItem(
                            time: "10:12",
                            icon: Icons.alternate_email,
                            title: "TWITTER",
                            subtitle: "com.twitter.android",
                            duration: "42s",
                            color: AppColors.alert,
                          ),
                          _buildDashedTimelineItem(
                            time: "10:14",
                            icon: Icons.camera_alt,
                            title: "INSTAGRAM",
                            subtitle: "com.instagram.android",
                            duration: "1m 04s",
                            color: AppColors.alert,
                          ),
                          _buildTimelineItem(
                            time: "10:20",
                            icon: Icons.forum,
                            title: "SLACK",
                            tag: "COMM",
                            subtitle: "#engineering-team",
                            duration: "14m 12s",
                            color: AppColors.primary,
                          ),
                          _buildFutureState(),
                        ],
                      ),
                      
                      // Scrubber Line
                      Positioned(
                        top: 220,
                        left: 0,
                        right: 0,
                        child: Row(
                          children: [
                            Expanded(child: Container(height: 1, color: Colors.white.withOpacity(0.5))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: const Text("SCRUB: 10:15", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Drawer Overlay (Event Details)
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: _buildEventDetailsDrawer(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFF0A0C0B),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.arrow_back, color: Colors.white),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("TEMPORAL GRID", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 16)),
                  Text("SESSION ID: 294-AX-99", 
                    style: GoogleFonts.firaCode(
                      color: AppColors.primary, 
                      fontSize: 10, 
                      letterSpacing: 1.5
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("SYS TIME", 
                    style: GoogleFonts.rajdhani(
                      color: AppColors.textMuted, 
                      fontSize: 10, 
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text("14:02:45", 
                    style: GoogleFonts.firaCode(
                      color: Colors.white, 
                      fontSize: 14, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border.all(color: AppColors.gridLines),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Icon(Icons.calendar_today, color: AppColors.primary, size: 16),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHistogram() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("NOTIFICATION DENSITY [PINGS/HR]", style: TextStyle(color: AppColors.secondary, fontSize: 10, letterSpacing: 1.5)),
              Text("MAX: 42", style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 64,
            child: Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(4, (index) => Container(
                    height: 1,
                    width: double.infinity,
                    color: AppColors.secondary.withOpacity(0.2),
                  )),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBar(0.1, false),_buildBar(0.15, false),_buildBar(0.05, false),_buildBar(0.3, false),_buildBar(0.45, false),
                    _buildBar(0.8, true),_buildBar(0.65, false),_buildBar(0.25, false),_buildBar(0.15, false),_buildBar(0.1, false),
                    _buildBar(0.05, false),_buildBar(0.4, false),_buildBar(0.9, true),_buildBar(0.55, false),_buildBar(0.2, false),
                    _buildBar(0.05, false),
                  ],
                ),
                  Positioned(
                    right: 120,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 1,
                      color: Colors.white,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Transform.rotate(
                          angle: 0.785,
                          child: Transform.translate(
                            offset: const Offset(0, -3),
                            child: Container(width: 6, height: 6, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("08:00", style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
              Text("10:00", style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
              Text("12:00", style: GoogleFonts.firaCode(color: AppColors.textMuted, fontSize: 10)),
              Text("14:00", style: GoogleFonts.firaCode(color: Colors.white, fontSize: 10)),
              Text("16:00", style: GoogleFonts.firaCode(color: AppColors.textMuted, fontSize: 10)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBar(double heightFactor, bool isHighlight) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        height: 64 * heightFactor,
        decoration: BoxDecoration(
          color: isHighlight ? AppColors.secondary : AppColors.secondary.withOpacity(heightFactor * 0.8 + 0.1),
          borderRadius: BorderRadius.circular(1),
          boxShadow: isHighlight ? [
            BoxShadow(color: AppColors.secondary.withOpacity(0.5), blurRadius: 4, spreadRadius: 1)
          ] : null,
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required String time,
    required IconData icon,
    required String title,
    required String tag,
    required String subtitle,
    required String duration,
    required Color color,
    bool isLong = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 56,
          child: Padding(
            padding: const EdgeInsets.only(top: 8, right: 12),
            child: Text(time, textAlign: TextAlign.right, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ),
        ),
        SizedBox(
          width: 24,
          child: Column(
            children: [
              Container(
                width: 2,
                height: isLong ? 100 : 70,
                color: color,
              )
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipPath(
                  clipper: _HexClipper(),
                  child: Container(
                    width: 40,
                    height: 40,
                    color: AppColors.primary,
                    child: Container(
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipPath(
                    clipper: _ChamferClipper(),
                    child: Container(
                      color: AppColors.surface,
                      padding: const EdgeInsets.all(12),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      border: Border.all(color: color.withOpacity(0.3)),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: Text(tag, style: TextStyle(color: color, fontSize: 10)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(subtitle, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                  Text(duration, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                          if (isLong)
                            Positioned(
                              bottom: -12,
                              left: -12,
                              right: -12,
                              child: Container(
                                height: 2,
                                color: color.withOpacity(0.2),
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: 0.85,
                                  child: Container(color: color),
                                ),
                              ),
                            )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashedTimelineItem({
    required String time,
    required IconData icon,
    required String title,
    required String subtitle,
    required String duration,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 56,
          child: Padding(
            padding: const EdgeInsets.only(top: 8, right: 12),
            child: Text(time, textAlign: TextAlign.right, style: TextStyle(color: color, fontSize: 12)),
          ),
        ),
        SizedBox(
          width: 24,
          child: Column(
            children: [
              Container(width: 2, height: 10, color: color),
              const SizedBox(height: 4),
              Container(width: 2, height: 10, color: color),
              const SizedBox(height: 4),
              Container(width: 2, height: 10, color: color),
              const SizedBox(height: 4),
              Container(width: 2, height: 30, color: color),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipPath(
                  clipper: _HexClipper(),
                  child: Container(
                    width: 32,
                    height: 32,
                    color: color,
                    child: Container(
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(color: AppColors.surface),
                      child: Icon(icon, color: color, size: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipPath(
                    clipper: _ChamferClipper(chamferSize: 8.0),
                    child: Container(
                      color: AppColors.surface,
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                              const SizedBox(width: 8),
                              Text(subtitle, style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                            ],
                          ),
                          Text(duration, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFutureState() {
    return Opacity(
      opacity: 0.5,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 56,
            child: Padding(
              padding: EdgeInsets.only(top: 8, right: 12),
              child: Text("10:45", textAlign: TextAlign.right, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ),
          ),
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, Colors.transparent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: FadeTransition(
                opacity: _pulseController,
                child: Text("RECORDING STREAM...", 
                  style: GoogleFonts.firaCode(
                    color: AppColors.primary, 
                    fontSize: 10, 
                    letterSpacing: 2
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetailsDrawer() {
    return ClipPath(
      clipper: _ChamferClipper(),
      child: Container(
        color: AppColors.surface.withOpacity(0.95),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 4, width: double.infinity, color: AppColors.primary),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.primary, blurRadius: 4)]),
                            ),
                            const SizedBox(width: 8),
                            const Text("EVENT_DETAILS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow("Package", "com.slack.mobile", AppColors.primary),
                        _buildDetailRow("Start", "10:20:04.452", Colors.white),
                        _buildDetailRow("End", "10:34:16.110", Colors.white),
                        _buildDetailRow("Interrupts", "0 (High Focus)", AppColors.secondary),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(Icons.forum, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Text("CLOSE", style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      )
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(width: 4, height: 4, color: AppColors.gridLines, margin: const EdgeInsets.only(right: 4, bottom: 8)),
                Container(width: 4, height: 4, color: AppColors.gridLines, margin: const EdgeInsets.only(right: 4, bottom: 8)),
                Container(width: 4, height: 4, color: AppColors.gridLines, margin: const EdgeInsets.only(right: 8, bottom: 8)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label.toUpperCase(), style: TextStyle(color: AppColors.textMuted, fontSize: 10))),
          Text(value, style: TextStyle(color: valueColor, fontSize: 12)),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter({this.color = const Color(0xFF1A2220)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.2)
      ..strokeWidth = 1.0;

    const double spacing = 20.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ChamferClipper extends CustomClipper<Path> {
  final double chamferSize;

  _ChamferClipper({this.chamferSize = 12.0});

  @override
  Path getClip(Size size) {
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

class _HexClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height * 0.25);
    path.lineTo(size.width, size.height * 0.75);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(0, size.height * 0.75);
    path.lineTo(0, size.height * 0.25);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
