import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../logic/telemetry_provider.dart';
import '../../logic/score_history_service.dart';
import '../theme.dart';
import 'social_synergy_screen.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

class AttentionDashboard extends StatefulWidget {
  const AttentionDashboard({super.key});

  @override
  State<AttentionDashboard> createState() => _AttentionDashboardState();
}

class _AttentionDashboardState extends State<AttentionDashboard>
    with SingleTickerProviderStateMixin {
  bool _showTotalDailyUsage = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TelemetryProvider>().fetchTotalDailyUsage();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final telemetry = context.watch<TelemetryProvider>();
    final scoreService = context.watch<ScoreHistoryService>();
    final score = telemetry.focusScore;
    final scoreColor = FateColors.scoreColor(score);

    return Scaffold(
      backgroundColor: FateColors.bgDeep,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── Premium App Bar ───
          SliverAppBar(
            expandedHeight: 100,
            floating: true,
            pinned: false,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'FATE',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: FateColors.bgCard.withAlpha(200),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withAlpha(10)),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.bolt_rounded,
                    color: FateColors.primary,
                  ),
                  tooltip: 'Analyse Right Now',
                  onPressed: () {
                    context.read<ScoreHistoryService>().triggerManualAnalysis();
                    context.read<TelemetryProvider>().resetAppUsageStats();
                  },
                ),
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ─── Timer Pill ───
                _buildTimerPill(scoreService),
                const SizedBox(height: 20),

                // ─── Hero Score Card ───
                _buildHeroScoreCard(score, scoreColor, scoreService),
                const SizedBox(height: 20),

                // ─── Metric Tiles (2x2 Grid) ───
                _buildMetricTiles(telemetry, scoreService),
                const SizedBox(height: 20),

                // ─── Score Trend Graph ───
                if (scoreService.todaySnapshots.length > 1) ...[
                  _buildTrendCard(scoreService),
                  const SizedBox(height: 20),
                ],

                // ─── Social Synergy Card ───
                _buildSocialCard(telemetry),
                const SizedBox(height: 24),

                // ─── App Activity Section ───
                _buildAppActivitySection(telemetry),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TIMER PILL
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTimerPill(ScoreHistoryService scoreService) {
    final min = scoreService.secondsUntilNextAnalysis ~/ 60;
    final sec = scoreService.secondsUntilNextAnalysis % 60;

    return Center(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: FateColors.bgCard.withAlpha(200),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: FateColors.primary.withAlpha(
                  (40 + 30 * _pulseController.value).toInt(),
                ),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: FateColors.primary.withAlpha(10),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.radar_rounded, color: FateColors.primary, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Next scan in ',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: FateColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: FateColors.primary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HERO SCORE CARD
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHeroScoreCard(
    double score,
    Color scoreColor,
    ScoreHistoryService scoreService,
  ) {
    String label;
    String emoji;
    if (score >= 70) {
      label = 'Deep Focus';
      emoji = '🔥';
    } else if (score >= 40) {
      label = 'Moderate';
      emoji = '⚡';
    } else {
      label = 'Distracted';
      emoji = '⚠️';
    }

    return GlassCard(
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [scoreColor.withAlpha(120), scoreColor.withAlpha(30)],
      ),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          Text(
            'Contextual Attention Score',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: FateColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          // Score Ring
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background ring
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 10,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation(
                      Colors.white.withAlpha(8),
                    ),
                  ),
                ),
                // Score ring
                SizedBox(
                  width: 160,
                  height: 160,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: (score / 100).clamp(0, 1)),
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return CircularProgressIndicator(
                        value: value,
                        strokeWidth: 10,
                        strokeCap: StrokeCap.round,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation(scoreColor),
                      );
                    },
                  ),
                ),
                // Score number
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: score),
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: GoogleFonts.outfit(
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                            color: scoreColor,
                            height: 1,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$emoji $label',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scoreColor.withAlpha(200),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Delta text
          if (scoreService.todaySnapshots.length > 1) ...[
            const SizedBox(height: 20),
            _buildDeltaChip(scoreService.todaySnapshots),
          ],
        ],
      ),
    );
  }

  Widget _buildDeltaChip(List<Map<String, dynamic>> snapshots) {
    final text = _getDeltaText(snapshots);
    if (text.isEmpty) return const SizedBox.shrink();

    final isUp = text.startsWith('📈');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: (isUp ? const Color(0xFF00E676) : const Color(0xFFFF5252))
            .withAlpha(15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isUp ? const Color(0xFF00E676) : const Color(0xFFFF5252))
              .withAlpha(40),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isUp ? const Color(0xFF00E676) : const Color(0xFFFF5252),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // METRIC TILES (2×2 grid)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildMetricTiles(
    TelemetryProvider telemetry,
    ScoreHistoryService scoreService,
  ) {
    final location = telemetry.currentContext;
    final fragPercent = (telemetry.fragmentationScore * 100).toStringAsFixed(0);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.broken_image_rounded,
                label: 'Fragmentation',
                value: '$fragPercent%',
                gradient: FateColors.warmGradient,
                subtitle: telemetry.fragmentationScore > 0.5
                    ? 'High switching'
                    : 'Focused usage',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                icon: Icons.location_on_rounded,
                label: 'Location',
                value: location,
                gradient: FateColors.coolGradient,
                subtitle: location == 'Off Campus'
                    ? 'Not on campus'
                    : 'On campus zone',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricTile(
                icon: Icons.people_alt_rounded,
                label: 'Peers',
                value: '${telemetry.nearbyPeers}',
                gradient: FateColors.purpleGradient,
                subtitle: telemetry.nearbyPeers > 0
                    ? 'Focus peers nearby'
                    : 'No peers detected',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricTile(
                icon: Icons.speed_rounded,
                label: 'Sub-Scores',
                value:
                    '${telemetry.sLoc.toStringAsFixed(0)}/${telemetry.sSoc.toStringAsFixed(0)}/${telemetry.sDig.toStringAsFixed(0)}',
                gradient: FateColors.heroGradient,
                subtitle: 'Loc / Soc / Dig',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TREND GRAPH CARD
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTrendCard(ScoreHistoryService scoreService) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GradientIcon(
                icon: Icons.show_chart_rounded,
                size: 20,
                gradient: FateColors.coolGradient,
              ),
              const SizedBox(width: 8),
              Text(
                'Score Trend',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: FateColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'Last ${scoreService.todaySnapshots.length} polls',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: FateColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildScoreHistoryGraph(scoreService.todaySnapshots),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SOCIAL SYNERGY CARD
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSocialCard(TelemetryProvider telemetry) {
    return GlassCard(
      borderGradient: const LinearGradient(
        colors: [Color(0xFFB721FF), Color(0xFF21D4FD)],
      ),
      padding: EdgeInsets.zero,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SocialSynergyScreen()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: FateColors.purpleGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.people_alt_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Social Synergy',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: FateColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${telemetry.nearbyPeers} high-focus peers nearby',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: FateColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: FateColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // APP ACTIVITY SECTION
  // ═══════════════════════════════════════════════════════════════
  Widget _buildAppActivitySection(TelemetryProvider telemetry) {
    final entries =
        (_showTotalDailyUsage
              ? telemetry.totalDailyUsage.entries.toList()
              : telemetry.appUsageStats.entries.toList())
          ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const GradientIcon(
              icon: Icons.apps_rounded,
              size: 20,
              gradient: FateColors.warmGradient,
            ),
            const SizedBox(width: 8),
            Text(
              'App Activity',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: FateColors.textPrimary,
              ),
            ),
            const Spacer(),
            _buildTogglePill(),
          ],
        ),
        const SizedBox(height: 14),

        // Content
        if (entries.isEmpty)
          _buildEmptyActivity(telemetry)
        else
          _buildAppGrid(entries),
      ],
    );
  }

  Widget _buildTogglePill() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: FateColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleOption('Session', !_showTotalDailyUsage),
          _buildToggleOption('Total', _showTotalDailyUsage),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String label, bool selected) {
    return GestureDetector(
      onTap: () {
        setState(() => _showTotalDailyUsage = label == 'Total');
        if (_showTotalDailyUsage) {
          context.read<TelemetryProvider>().fetchTotalDailyUsage();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? FateColors.primary.withAlpha(30)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? FateColors.primary : FateColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyActivity(TelemetryProvider telemetry) {
    if (_showTotalDailyUsage && telemetry.totalDailyUsage.isEmpty) {
      return GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.app_blocking_rounded,
              size: 40,
              color: FateColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'Grant App Usage permission to see total daily stats',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: FateColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                gradient: FateColors.heroGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => telemetry.requestUsagePermission(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.settings_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Grant Permission',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.hourglass_empty_rounded,
            size: 36,
            color: FateColors.textMuted,
          ),
          const SizedBox(height: 8),
          Text(
            'No app usage logged since last poll.',
            style: GoogleFonts.outfit(
              color: FateColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppGrid(List<MapEntry<String, int>> entries) {
    // Find max for relative bar width
    final maxVal = entries.fold<int>(0, (prev, e) => max(prev, e.value));

    return Column(
      children: entries.take(10).map((entry) {
        return PremiumAppActivityTile(
          packageName: entry.key,
          durationSecs: entry.value,
          maxDurationSecs: maxVal,
        );
      }).toList(),
    );
  }

  // ─── HELPER: Delta Text ───
  String _getDeltaText(List<Map<String, dynamic>> snapshots) {
    if (snapshots.length < 2) return '';
    final current = snapshots.last;
    final prev = snapshots[snapshots.length - 2];

    final cas = (current['CAS'] as num).toDouble();
    final prevCas = (prev['CAS'] as num).toDouble();
    final diff = cas - prevCas;

    if (diff.abs() < 0.1) return '';

    final locDiff =
        (current['S_loc'] as num).toDouble() -
        (prev['S_loc'] as num).toDouble();
    final socDiff =
        (current['S_soc'] as num).toDouble() -
        (prev['S_soc'] as num).toDouble();
    final digDiff =
        (current['S_dig'] as num).toDouble() -
        (prev['S_dig'] as num).toDouble();

    String mainFactor = 'Spatial Activity';
    double maxDiff = locDiff.abs();
    if (socDiff.abs() > maxDiff) {
      mainFactor = 'Social Engagement';
      maxDiff = socDiff.abs();
    }
    if (digDiff.abs() > maxDiff) {
      mainFactor = 'Digital Distractions';
    }

    if (diff > 0) {
      return '📈 Increase of ${diff.abs().toStringAsFixed(1)} (mainly due to $mainFactor)';
    } else {
      return '📉 Decrease of ${diff.abs().toStringAsFixed(1)} (mainly due to $mainFactor)';
    }
  }

  // ─── HELPER: Score History Graph ───
  Widget _buildScoreHistoryGraph(List<Map<String, dynamic>> snapshots) {
    if (snapshots.isEmpty) return const SizedBox.shrink();

    final spots = <FlSpot>[];
    for (int i = 0; i < snapshots.length; i++) {
      final cas = (snapshots[i]['CAS'] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), cas));
    }

    return AspectRatio(
      aspectRatio: 2.0,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.white.withAlpha(8), strokeWidth: 1),
          ),
          titlesData: const FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (snapshots.length - 1).toDouble() > 0
              ? (snapshots.length - 1).toDouble()
              : 1.0,
          minY: 0,
          maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: FateColors.primary,
                    strokeWidth: 2,
                    strokeColor: Colors.white.withAlpha(80),
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    FateColors.primary.withAlpha(40),
                    FateColors.primary.withAlpha(0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// METRIC TILE WIDGET
// ═══════════════════════════════════════════════════════════════
class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final LinearGradient gradient;
  final String? subtitle;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: FateColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: FateColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: FateColors.textMuted.withAlpha(170),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class PremiumAppActivityTile extends StatefulWidget {
  final String packageName;
  final int durationSecs;
  final int maxDurationSecs;

  const PremiumAppActivityTile({
    super.key,
    required this.packageName,
    required this.durationSecs,
    required this.maxDurationSecs,
  });

  @override
  State<PremiumAppActivityTile> createState() => _PremiumAppActivityTileState();
}

class _PremiumAppActivityTileState extends State<PremiumAppActivityTile> {
  AppInfo? _appInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      final info = await InstalledApps.getAppInfo(widget.packageName);
      if (mounted) {
        setState(() {
          _appInfo = info;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    // Ignore known system apps or apps explicitly marked as system
    final knownSystemApps = [
      'com.android.systemui',
      'com.miui.home',
      'com.sec.android.app.launcher',
      'android',
      'com.android.settings',
    ];

    if (_appInfo?.isSystemApp == true ||
        knownSystemApps.contains(widget.packageName)) {
      return const SizedBox.shrink();
    }

    final appName = _appInfo?.name ?? widget.packageName.split('.').last;
    final minutes = widget.durationSecs ~/ 60;
    final seconds = widget.durationSecs % 60;
    final durationStr = minutes > 0 ? '${minutes}m ${seconds}s' : '${seconds}s';
    final fraction = widget.maxDurationSecs > 0
        ? widget.durationSecs / widget.maxDurationSecs
        : 0.0;

    // Color based on usage severity
    Color barColor;
    if (widget.durationSecs > 600) {
      barColor = const Color(0xFFFF5252); // Heavy usage
    } else if (widget.durationSecs > 180) {
      barColor = const Color(0xFFFFAB40); // Moderate
    } else {
      barColor = const Color(0xFF00E676); // Light
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        borderRadius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _appInfo?.icon == null
                        ? barColor.withAlpha(20)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _appInfo?.icon != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(_appInfo!.icon!),
                        )
                      : Icon(Icons.apps_rounded, color: barColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appName.length > 1
                            ? appName[0].toUpperCase() + appName.substring(1)
                            : appName.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: FateColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  durationStr,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: barColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Usage bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fraction),
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 4,
                    backgroundColor: Colors.white.withAlpha(8),
                    valueColor: AlwaysStoppedAnimation(barColor.withAlpha(180)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
