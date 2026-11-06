import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../logic/telemetry_provider.dart';
import '../../logic/score_history_service.dart';
import '../theme.dart';
import '../notification_log_screen.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

class AttentionDashboard extends StatefulWidget {
  const AttentionDashboard({super.key});

  @override
  State<AttentionDashboard> createState() => _AttentionDashboardState();
}

class _AttentionDashboardState extends State<AttentionDashboard> {
  bool _showTotalDailyUsage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TelemetryProvider>().fetchTotalDailyUsage();
      }
    });
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
          FateSliverHeader(
            title: 'Focus',
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                tooltip: 'Notification log',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationLogScreen(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Recalculate now',
                onPressed: () {
                  context.read<ScoreHistoryService>().triggerManualAnalysis();
                },
              ),
              const SizedBox(width: 8),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ─── Hero Score Card ───
                _buildHeroScoreCard(score, scoreColor, scoreService),
                const SizedBox(height: 12),

                // ─── Metric Tiles ───
                _buildMetricTiles(telemetry, scoreService),
                const SizedBox(height: 20),

                // ─── Score Trend Graph ───
                if (scoreService.todaySnapshots.length > 1) ...[
                  _buildTrendCard(scoreService),
                  const SizedBox(height: 20),
                ],

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
  // HERO SCORE CARD
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHeroScoreCard(
    double score,
    Color scoreColor,
    ScoreHistoryService scoreService,
  ) {
    final telemetry = context.read<TelemetryProvider>();
    final last = scoreService.todaySnapshots.isNotEmpty
        ? DateTime.tryParse('${scoreService.todaySnapshots.last['ts']}')
        : null;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: score),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Text(
                  value.toStringAsFixed(0),
                  style: GoogleFonts.outfit(
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                    color: FateColors.textPrimary,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusDot(color: scoreColor),
                          const SizedBox(width: 6),
                          Text(
                            FateColors.scoreLabel(score),
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: scoreColor,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Attention score today',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: FateColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (score / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: FateColors.bgElevated,
              valueColor: AlwaysStoppedAnimation(scoreColor),
            ),
          ),
          const SizedBox(height: 18),
          _componentRow(
            'Place',
            'Where you spend time',
            telemetry.sLoc,
            signed: true,
          ),
          _componentRow(
            'People',
            'Who is around you',
            telemetry.sSoc,
            signed: true,
          ),
          _componentRow('Phone', 'App use & notifications', telemetry.sDig),
          if (scoreService.todaySnapshots.length > 1) ...[
            const SizedBox(height: 8),
            Text(
              _getDeltaText(
                scoreService.todaySnapshots,
              ).replaceAll(RegExp(r'^[^A-Za-z0-9+-]+'), ''),
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: FateColors.textSecondary,
              ),
            ),
          ],
          if (last != null) ...[
            const SizedBox(height: 4),
            Text(
              'Updated ${_ago(last)}',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: FateColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// One sub-score line. Place/People are signed contributions (around 0);
  /// Phone is already 0-100.
  Widget _componentRow(
    String title,
    String hint,
    double v, {
    bool signed = false,
  }) {
    final text = signed
        ? '${v >= 0 ? '+' : ''}${v.toStringAsFixed(1)}'
        : v.toStringAsFixed(0);
    final color = signed
        ? (v > 0.05
              ? FateColors.scoreColor(80)
              : v < -0.05
              ? FateColors.scoreColor(10)
              : FateColors.textSecondary)
        : FateColors.scoreColor(v);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: FateColors.textPrimary,
                  ),
                ),
                Text(
                  hint,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: FateColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            text,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inSeconds < 60) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    return '${d.inHours} h ago';
  }

  // ═══════════════════════════════════════════════════════════════
  // METRIC TILES (2×2 grid)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildMetricTiles(
    TelemetryProvider telemetry,
    ScoreHistoryService scoreService,
  ) {
    final fragPercent = (telemetry.fragmentationScore * 100).toStringAsFixed(0);
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            icon: Icons.place_outlined,
            label: 'Zone',
            value: telemetry.currentContext,
            gradient: FateColors.coolGradient,
            subtitle: '',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricTile(
            icon: Icons.people_outline_rounded,
            label: 'Nearby',
            value: '${telemetry.nearbyPeers}',
            gradient: FateColors.purpleGradient,
            subtitle: '',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricTile(
            icon: Icons.swap_horiz_rounded,
            label: 'Switching',
            value: '$fragPercent%',
            gradient: FateColors.warmGradient,
            subtitle: '',
          ),
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
            const Expanded(child: SectionHeader(title: 'App activity')),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: FateColors.textMuted),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: FateColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: FateColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
      barColor = const Color(0xFFF87171); // Heavy usage
    } else if (widget.durationSecs > 180) {
      barColor = const Color(0xFFFFAB40); // Moderate
    } else {
      barColor = const Color(0xFF4ADE80); // Light
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
