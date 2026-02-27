import 'package:flutter/material.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class RecommendationPanel extends StatefulWidget {
  const RecommendationPanel({Key? key}) : super(key: key);

  @override
  State<RecommendationPanel> createState() => _RecommendationPanelState();
}

class _RecommendationPanelState extends State<RecommendationPanel> with SingleTickerProviderStateMixin {
  late AnimationController _cursorController;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
       vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Scanlines overlay (subtle)
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: CustomPaint(painter: _ScanlinePainter()),
              ),
            ),
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildPredictiveModel(),
                      const SizedBox(height: 24),
                      _buildInsightsSection(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xF2050505), // AppColors.background.withOpacity(0.95)
        border: Border(bottom: BorderSide(color: AppColors.gridLines)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.terminal, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '> GEMINI_UPLINK',
                    style: GoogleFonts.firaCode(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.primary, blurRadius: 4)],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('LIVE', style: GoogleFonts.firaCode(color: AppColors.primary, fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('> ESTABLISHING SECURE HANDSHAKE... [OK]', style: GoogleFonts.firaCode(color: AppColors.textMuted, fontSize: 10)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('LATENCY: ', style: GoogleFonts.firaCode(color: AppColors.textMuted, fontSize: 10)),
              Text('12ms', style: GoogleFonts.firaCode(color: AppColors.secondary, fontSize: 10)),
              const SizedBox(width: 16),
              Text('BITRATE: ', style: GoogleFonts.firaCode(color: AppColors.textMuted, fontSize: 10)),
              Text('128kbps', style: GoogleFonts.firaCode(color: AppColors.secondary, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPredictiveModel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('PREDICTIVE FOCUS MODEL', style: GoogleFonts.firaCode(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            Text('CONFIDENCE: 94%', style: GoogleFonts.firaCode(color: AppColors.primary, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.gridLines),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('08:00', style: GoogleFonts.firaCode(color: AppColors.textMuted, fontSize: 10)),
                  Text('12:00', style: GoogleFonts.firaCode(color: AppColors.textMuted, fontSize: 10)),
                  Text('16:00', style: GoogleFonts.firaCode(color: AppColors.textMuted, fontSize: 10)),
                  Text('20:00', style: GoogleFonts.firaCode(color: AppColors.textMuted, fontSize: 10)),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                height: 32,
                width: double.infinity,
                decoration: BoxDecoration(color: Color(0xFF0A0C0B)),
                child: Stack(
                  children: [
                    // Zones
                    Positioned(left: 40, width: 60, top: 8, bottom: 8, child: Container(decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), border: Border.symmetric(vertical: BorderSide(color: AppColors.primary.withOpacity(0.3)))))),
                    Positioned(left: 140, width: 100, top: 4, bottom: 4, child: Container(
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.4), border: Border.all(color: AppColors.primary)),
                      child: Center(child: Text('PEAK WINDOW', style: GoogleFonts.rajdhani(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 8, backgroundColor: AppColors.primary))),
                    )),
                    Positioned(left: 280, width: 80, top: 12, bottom: 12, child: Container(decoration: BoxDecoration(color: AppColors.alert.withOpacity(0.2), border: Border(bottom: BorderSide(color: AppColors.alert.withOpacity(0.5)))))),
                    
                    // Current marker
                    Positioned(left: 260, top: 0, bottom: 0, child: Container(
                      width: 1, color: AppColors.alert,
                      child: Align(alignment: Alignment.topCenter, child: Transform.rotate(angle: pi/4, child: Container(width: 6, height: 6, color: AppColors.alert))),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_graph, color: AppColors.primary, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Upcoming peak window predicted at 14:00 - 16:30. Recommend scheduling deep work blocks.',
                      style: GoogleFonts.rajdhani(color: Colors.grey[300], fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('INCOMING TRANSMISSION', style: GoogleFonts.firaCode(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        _buildInsightCard(
          title: 'ALERT // CONTEXT_FRACTURE',
          description: 'Context switching velocity exceeds baseline by 40% when in proximity to [User_ID_X]. Focus integrity compromised.',
          time: '14:02:45',
          color: AppColors.alert,
          icon: Icons.warning,
          actions: ['[ACKNOWLEDGE]', '[IGNORE]'],
        ),
        const SizedBox(height: 16),
        _buildInsightCard(
          title: 'PATTERN // DEEP_WORK',
          description: 'Sustained focus of 45m detected. Dopamine regulation appears stable.\n> RECOMMENDATION: Extend session by 15m.',
          time: '13:15:22',
          color: AppColors.primary,
          icon: Icons.check_circle,
          actions: ['[ACCEPT_GOAL]'],
        ),
        const SizedBox(height: 16),
        _buildInsightCard(
          title: 'ENV // NOISE_FLOOR',
          description: 'Ambient noise levels dropped below 40dB. Ideal conditions for cognitive tasks initiated.',
          time: '12:48:10',
          color: AppColors.secondary,
          icon: Icons.graphic_eq,
          actions: ['[LOG_ENTRY]', '[DISMISS]'],
        ),
        const SizedBox(height: 16),
        // Cursor
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Row(
            children: [
              Text('>', style: GoogleFonts.firaCode(color: AppColors.primary, fontSize: 12)),
              const SizedBox(width: 8),
              FadeTransition(
                opacity: _cursorController,
                child: Container(width: 8, height: 16, color: AppColors.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String description,
    required String time,
    required Color color,
    required IconData icon,
    required List<String> actions,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.gridLines),
      ),
      child: Stack(
        children: [
          Positioned(left: 0, top: 0, bottom: 0, width: 4, child: Container(color: color)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: color, size: 14),
                        const SizedBox(width: 8),
                        Text(title, style: GoogleFonts.rajdhani(color: color, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
                      ],
                    ),
                    Text(time, style: GoogleFonts.firaCode(color: AppColors.textMuted, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: GoogleFonts.firaCode(color: Colors.grey[300], fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 16),
                Row(
                  children: actions.map((action) => Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Text(action, style: GoogleFonts.firaCode(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
