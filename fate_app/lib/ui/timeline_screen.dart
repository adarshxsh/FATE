import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../logic/score_history_service.dart';
import 'theme.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<ScoreHistoryService>();

    return Scaffold(
      backgroundColor: FateColors.bgDeep,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            floating: true,
            pinned: false,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'Analysis',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
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
                    Icons.refresh_rounded,
                    color: FateColors.primary,
                  ),
                  tooltip: 'Fetch Now',
                  onPressed: () {
                    history.fetchAndStore();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Fetching fresh analysis...',
                          style: GoogleFonts.outfit(),
                        ),
                        backgroundColor: FateColors.bgCard,
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Live CAS Score Card ──
                _buildLiveScoreCard(context, history),
                const SizedBox(height: 16),

                // ── Sub-Score Breakdown ──
                _buildSubScoreRow(context, history),
                const SizedBox(height: 28),

                // ── Today's Snapshots ──
                SectionHeader(
                  title: "Today's Snapshots",
                  badge: '${history.todaySnapshots.length} readings',
                  icon: Icons.timeline_rounded,
                ),
                if (history.todaySnapshots.isEmpty)
                  _buildEmptyState(
                    'No snapshots yet. First one arrives in ~5 min.',
                  )
                else
                  _buildSnapshotList(context, history.todaySnapshots),
                const SizedBox(height: 28),

                // ── Daily Averages ──
                SectionHeader(
                  title: 'Daily Averages',
                  badge: '${history.dailyAverages.length} days',
                  icon: Icons.calendar_today_rounded,
                ),
                if (history.dailyAverages.isEmpty)
                  _buildEmptyState('Daily averages appear after a full day.')
                else
                  _buildDailyList(context, history.dailyAverages),
                const SizedBox(height: 28),

                // ── Weekly Averages ──
                SectionHeader(
                  title: 'Weekly Averages',
                  badge: '${history.weeklyAverages.length} weeks',
                  icon: Icons.date_range_rounded,
                ),
                if (history.weeklyAverages.isEmpty)
                  _buildEmptyState(
                    'Weekly averages appear after 7 daily records.',
                  )
                else
                  _buildWeeklyList(context, history.weeklyAverages),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Live Score Card ──
  Widget _buildLiveScoreCard(BuildContext context, ScoreHistoryService h) {
    final casColor = FateColors.scoreColor(h.currentCAS);
    String statusLabel;
    if (h.currentCAS >= 70) {
      statusLabel = '🔥 Deep Focus';
    } else if (h.currentCAS >= 40) {
      statusLabel = '⚡ Moderate';
    } else {
      statusLabel = '⚠️ Distracted';
    }

    return GlassCard(
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [casColor.withAlpha(100), casColor.withAlpha(20)],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'CONTEXTUAL ATTENTION SCORE',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: FateColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: h.currentCAS),
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return Text(
                value.toStringAsFixed(1),
                style: GoogleFonts.outfit(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  color: casColor,
                  height: 1,
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            statusLabel,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: casColor.withAlpha(200),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Updates every 5 minutes',
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: FateColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ── Sub-Score Breakdown Row ──
  Widget _buildSubScoreRow(BuildContext context, ScoreHistoryService h) {
    return Row(
      children: [
        Expanded(
          child: _buildSubScoreChip(
            'Spatial',
            h.currentSLoc,
            Icons.location_on_rounded,
            FateColors.coolGradient,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSubScoreChip(
            'Social',
            h.currentSSoc,
            Icons.people_rounded,
            FateColors.purpleGradient,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSubScoreChip(
            'Digital',
            h.currentSDig,
            Icons.phone_android_rounded,
            FateColors.warmGradient,
          ),
        ),
      ],
    );
  }

  Widget _buildSubScoreChip(
    String label,
    double value,
    IconData icon,
    LinearGradient gradient,
  ) {
    final isPositive = value >= 0;
    final color = isPositive
        ? const Color(0xFF00E676)
        : const Color(0xFFFF5252);

    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Column(
        children: [
          GradientIcon(icon: icon, size: 18, gradient: gradient),
          const SizedBox(height: 8),
          Text(
            '${isPositive ? '+' : ''}${value.toStringAsFixed(1)}',
            style: GoogleFonts.jetBrainsMono(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: FateColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.hourglass_empty_rounded,
              color: FateColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.outfit(
                  color: FateColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Today's Snapshot List ──
  Widget _buildSnapshotList(
    BuildContext context,
    List<Map<String, dynamic>> snapshots,
  ) {
    final display = snapshots.reversed.take(12).toList();
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: display.length,
      itemBuilder: (context, index) {
        final s = display[index];
        final ts = DateTime.parse(s['ts']);
        final time =
            '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';
        final cas = (s['CAS'] as num).toDouble();
        final scoreColor = FateColors.scoreColor(cas);

        String deltaText = '';
        if (index + 1 < display.length) {
          final prev = display[index + 1];
          final prevCas = (prev['CAS'] as num).toDouble();
          final diff = cas - prevCas;

          if (diff.abs() >= 0.1) {
            final locDiff =
                (s['S_loc'] as num).toDouble() -
                (prev['S_loc'] as num).toDouble();
            final socDiff =
                (s['S_soc'] as num).toDouble() -
                (prev['S_soc'] as num).toDouble();
            final digDiff =
                (s['S_dig'] as num).toDouble() -
                (prev['S_dig'] as num).toDouble();

            String mainFactor = 'Spatial';
            double maxDiff = locDiff.abs();
            if (socDiff.abs() > maxDiff) {
              mainFactor = 'Social';
              maxDiff = socDiff.abs();
            }
            if (digDiff.abs() > maxDiff) {
              mainFactor = 'Digital';
            }

            deltaText = diff > 0
                ? '↑ Increase due to $mainFactor'
                : '↓ Decrease due to $mainFactor';
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            borderRadius: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time + Bar + Score — all on ONE line
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Time badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: FateColors.bgElevated,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        time,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: FateColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Progress bar & Delta Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(
                                begin: 0,
                                end: (cas / 100).clamp(0, 1),
                              ),
                              duration: const Duration(milliseconds: 150),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, _) {
                                return LinearProgressIndicator(
                                  value: value,
                                  minHeight: 6,
                                  backgroundColor: Colors.white.withAlpha(8),
                                  valueColor: AlwaysStoppedAnimation(
                                    scoreColor,
                                  ),
                                );
                              },
                            ),
                          ),
                          if (deltaText.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              deltaText,
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                color: FateColors.textPrimary.withAlpha(150),
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Score value
                    Text(
                      cas.toStringAsFixed(0),
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: scoreColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Daily Averages ──
  Widget _buildDailyList(
    BuildContext context,
    List<Map<String, dynamic>> dailies,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: dailies.length,
      itemBuilder: (context, index) {
        final d = dailies[index];
        final date = d['date'] ?? '?';
        final cas = (d['CAS'] as num).toDouble();
        final scoreColor = FateColors.scoreColor(cas);

        String deltaText = '';
        if (index + 1 < dailies.length) {
          final prev = dailies[index + 1];
          final prevCas = (prev['CAS'] as num).toDouble();
          final diff = cas - prevCas;

          if (diff.abs() >= 0.5) {
            final locDiff =
                (d['S_loc'] as num).toDouble() -
                (prev['S_loc'] as num).toDouble();
            final socDiff =
                (d['S_soc'] as num).toDouble() -
                (prev['S_soc'] as num).toDouble();
            final digDiff =
                (d['S_dig'] as num).toDouble() -
                (prev['S_dig'] as num).toDouble();

            String mainFactor = 'Spatial';
            double maxDiff = locDiff.abs();
            if (socDiff.abs() > maxDiff) {
              mainFactor = 'Social';
              maxDiff = socDiff.abs();
            }
            if (digDiff.abs() > maxDiff) {
              mainFactor = 'Digital';
            }

            deltaText = diff > 0
                ? '↑ Better $mainFactor'
                : '↓ Weaker $mainFactor';
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            borderRadius: 14,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: FateColors.subtleGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    size: 18,
                    color: FateColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        date,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: FateColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (deltaText.isNotEmpty)
                        Text(
                          deltaText,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: FateColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Text(
                  cas.toStringAsFixed(1),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: scoreColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Weekly Averages ──
  Widget _buildWeeklyList(
    BuildContext context,
    List<Map<String, dynamic>> weeks,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: weeks.length,
      itemBuilder: (context, index) {
        final w = weeks[index];
        final weekEnd = w['week_ending'] ?? '?';
        final cas = (w['CAS'] as num).toDouble();
        final scoreColor = FateColors.scoreColor(cas);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            borderRadius: 14,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: FateColors.heroGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.date_range_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Week ending $weekEnd',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: FateColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  cas.toStringAsFixed(1),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: scoreColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
