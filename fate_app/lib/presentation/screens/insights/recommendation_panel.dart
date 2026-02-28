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
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                children: [
                  _buildPredictiveModel(),
                  const SizedBox(height: 32),
                  _buildInsightsSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.background,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppColors.neumorphicPressedDecoration(radius: 16),
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
                    const SizedBox(width: 6),
                    Text('LIVE', style: GoogleFonts.firaCode(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('> ESTABLISHING SECURE HANDSHAKE... [OK]', style: GoogleFonts.firaCode(color: AppColors.textMuted, fontSize: 10)),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('LATENCY: ', style: GoogleFonts.firaCode(color: AppColors.textMuted, fontSize: 10)),
                Text('12ms', style: GoogleFonts.firaCode(color: AppColors.textPrimary, fontSize: 10)),
                const SizedBox(width: 16),
                Text('BITRATE: ', style: GoogleFonts.firaCode(color: AppColors.textMuted, fontSize: 10)),
                Text('128kbps', style: GoogleFonts.firaCode(color: AppColors.textPrimary, fontSize: 10)),
              ],
            ),
          ],
        ),
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
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppColors.neumorphicDecoration(radius: 24),
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
              const SizedBox(height: 12),
              Container(
                height: 32,
                width: double.infinity,
                decoration: AppColors.neumorphicPressedDecoration(radius: 16),
                child: Stack(
                  children: [
                    // Zones
                    Positioned(left: 40, width: 60, top: 4, bottom: 4, child: Container(decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(8)))),
                    Positioned(left: 140, width: 100, top: 2, bottom: 2, child: Container(
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 4)]),
                      child: Center(child: Text('PEAK WINDOW', style: GoogleFonts.rajdhani(color: AppColors.background, fontWeight: FontWeight.bold, fontSize: 10))),
                    )),
                    Positioned(left: 280, width: 80, top: 4, bottom: 4, child: Container(decoration: BoxDecoration(color: AppColors.alert.withOpacity(0.15), borderRadius: BorderRadius.circular(8)))),
                    
                    // Current marker
                    Positioned(left: 260, top: 0, bottom: 0, child: Container(
                      width: 2, color: AppColors.alert,
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.surfaceHighlight, shape: BoxShape.circle),
                    child: Icon(Icons.auto_graph, color: AppColors.primary, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Upcoming peak window predicted at 14:00 - 16:30. Recommend scheduling deep work blocks.',
                      style: GoogleFonts.rajdhani(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
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
        const SizedBox(height: 20),
        _buildInsightCard(
          title: 'ALERT // CONTEXT_FRACTURE',
          description: 'Context switching velocity exceeds baseline by 40% when in proximity to [User_ID_X]. Focus integrity compromised.',
          time: '14:02:45',
          color: AppColors.alert,
          icon: Icons.warning_rounded,
          actions: ['ACKNOWLEDGE', 'IGNORE'],
        ),
        const SizedBox(height: 20),
        _buildInsightCard(
          title: 'PATTERN // DEEP_WORK',
          description: 'Sustained focus of 45m detected. Dopamine regulation appears stable.\n> RECOMMENDATION: Extend session by 15m.',
          time: '13:15:22',
          color: AppColors.primary,
          icon: Icons.check_circle_outline,
          actions: ['ACCEPT GOAL'],
        ),
        const SizedBox(height: 20),
        _buildInsightCard(
          title: 'ENV // NOISE_FLOOR',
          description: 'Ambient noise levels dropped below 40dB. Ideal conditions for cognitive tasks initiated.',
          time: '12:48:10',
          color: AppColors.secondary,
          icon: Icons.graphic_eq_rounded,
          actions: ['LOG ENTRY', 'DISMISS'],
        ),
        const SizedBox(height: 24),
        // Cursor
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Row(
            children: [
              Text('>', style: GoogleFonts.firaCode(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              FadeTransition(
                opacity: _cursorController,
                child: Container(
                  width: 10, 
                  height: 18, 
                  decoration: BoxDecoration(
                    color: AppColors.primary, 
                    boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 4)],
                  ),
                ),
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
      decoration: AppColors.neumorphicDecoration(radius: 20),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHighlight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(title, style: GoogleFonts.rajdhani(color: color, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.0), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(time, style: GoogleFonts.firaCode(color: AppColors.textMuted, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: GoogleFonts.rajdhani(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: actions.map((action) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: AppColors.neumorphicPressedDecoration(radius: 12),
              child: Text(action, style: GoogleFonts.firaCode(color: AppColors.textPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

