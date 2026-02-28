import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/score_history_service.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<ScoreHistoryService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Fetch Now',
            onPressed: () {
              history.fetchAndStore();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fetching fresh analysis...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Live CAS Score Card ──
          _buildLiveScoreCard(context, history),
          const SizedBox(height: 16),

          // ── Sub-Score Breakdown ──
          _buildSubScoreRow(context, history),
          const SizedBox(height: 24),

          // ── Today's Snapshots ──
          _buildSectionTitle(
            context,
            'Today\'s Snapshots',
            '${history.todaySnapshots.length} readings',
          ),
          const SizedBox(height: 8),
          if (history.todaySnapshots.isEmpty)
            _buildEmptyState('No snapshots yet. First one arrives in ~5 min.')
          else
            _buildSnapshotList(context, history.todaySnapshots),
          const SizedBox(height: 24),

          // ── Daily Averages ──
          _buildSectionTitle(
            context,
            'Daily Averages',
            '${history.dailyAverages.length} days',
          ),
          const SizedBox(height: 8),
          if (history.dailyAverages.isEmpty)
            _buildEmptyState('Daily averages appear after a full day.')
          else
            _buildDailyList(context, history.dailyAverages),
          const SizedBox(height: 24),

          // ── Weekly Averages ──
          _buildSectionTitle(
            context,
            'Weekly Averages',
            '${history.weeklyAverages.length} weeks',
          ),
          const SizedBox(height: 8),
          if (history.weeklyAverages.isEmpty)
            _buildEmptyState('Weekly averages appear after 7 daily records.')
          else
            _buildWeeklyList(context, history.weeklyAverages),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Live Score Card ──
  Widget _buildLiveScoreCard(BuildContext context, ScoreHistoryService h) {
    final casColor = h.currentCAS >= 70
        ? Colors.greenAccent
        : h.currentCAS >= 40
        ? Colors.amberAccent
        : Colors.redAccent;

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Contextual Attention Score',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white54),
            ),
            const SizedBox(height: 8),
            Text(
              h.currentCAS.toStringAsFixed(1),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: casColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              h.currentCAS >= 70
                  ? '🔥 Deep Focus'
                  : h.currentCAS >= 40
                  ? '⚡ Moderate'
                  : '⚠️ Distracted',
              style: TextStyle(color: casColor, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Updates every 5 minutes',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sub-Score Breakdown Row ──
  Widget _buildSubScoreRow(BuildContext context, ScoreHistoryService h) {
    return Row(
      children: [
        _buildSubScoreChip(
          context,
          'Spatial',
          h.currentSLoc,
          Icons.location_on,
        ),
        const SizedBox(width: 8),
        _buildSubScoreChip(context, 'Social', h.currentSSoc, Icons.people),
        const SizedBox(width: 8),
        _buildSubScoreChip(
          context,
          'Digital',
          h.currentSDig,
          Icons.phone_android,
        ),
      ],
    );
  }

  Widget _buildSubScoreChip(
    BuildContext context,
    String label,
    double value,
    IconData icon,
  ) {
    final isPositive = value >= 0;
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, size: 20, color: Colors.white54),
              const SizedBox(height: 6),
              Text(
                '${isPositive ? '+' : ''}${value.toStringAsFixed(1)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isPositive ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section Titles ──
  Widget _buildSectionTitle(BuildContext context, String title, String badge) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            badge,
            style: const TextStyle(fontSize: 11, color: Colors.white54),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white38, fontSize: 13),
      ),
    );
  }

  // ── Today's Snapshot List (most recent first, max 12 shown) ──
  Widget _buildSnapshotList(
    BuildContext context,
    List<Map<String, dynamic>> snapshots,
  ) {
    final display = snapshots.reversed.take(12).toList();
    return Column(
      children: display.map((s) {
        final ts = DateTime.parse(s['ts']);
        final time =
            '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';
        final cas = (s['CAS'] as num).toDouble();

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              SizedBox(
                width: 50,
                child: Text(
                  time,
                  style: const TextStyle(fontSize: 13, color: Colors.white54),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (cas / 100).clamp(0, 1),
                    minHeight: 18,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      cas >= 70
                          ? Colors.greenAccent
                          : cas >= 40
                          ? Colors.amberAccent
                          : Colors.redAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                child: Text(
                  cas.toStringAsFixed(0),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Daily Averages ──
  Widget _buildDailyList(
    BuildContext context,
    List<Map<String, dynamic>> dailies,
  ) {
    return Column(
      children: dailies.map((d) {
        final date = d['date'] ?? '?';
        final cas = (d['CAS'] as num).toDouble();

        return Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.calendar_today, size: 18),
            title: Text(
              date,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              cas.toStringAsFixed(1),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: cas >= 70
                    ? Colors.greenAccent
                    : cas >= 40
                    ? Colors.amberAccent
                    : Colors.redAccent,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Weekly Averages ──
  Widget _buildWeeklyList(
    BuildContext context,
    List<Map<String, dynamic>> weeks,
  ) {
    return Column(
      children: weeks.map((w) {
        final weekEnd = w['week_ending'] ?? '?';
        final cas = (w['CAS'] as num).toDouble();

        return Card(
          margin: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.date_range, size: 18),
            title: Text(
              'Week ending $weekEnd',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              cas.toStringAsFixed(1),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: cas >= 70
                    ? Colors.greenAccent
                    : cas >= 40
                    ? Colors.amberAccent
                    : Colors.redAccent,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
