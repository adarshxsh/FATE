import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/telemetry_provider.dart';
import '../../logic/score_history_service.dart';
import 'social_synergy_screen.dart';
import 'package:fl_chart/fl_chart.dart';

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
    // Fetch absolute total daily usage when dashboard opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TelemetryProvider>().fetchTotalDailyUsage();
      }
    });
  }

  // --- Location Data & Logic ---
  final List<Map<String, dynamic>> _buildings = [
    {"name": "LHC", "lat": 26.473123, "lng": 73.114013, "radius": 150.0},
    {"name": "Shamiana", "lat": 26.4768079, "lng": 73.1142273, "radius": 150.0},
    {"name": "New Mess", "lat": 26.4728026, "lng": 73.1173692, "radius": 150.0},
    {
      "name": "Akash Complex",
      "lat": 26.4768229,
      "lng": 73.1197027,
      "radius": 150.0,
    },
    {"name": "KT", "lat": 26.4693031, "lng": 73.1141130, "radius": 150.0},
    {"name": "FNG", "lat": 26.4662537, "lng": 73.1119672, "radius": 150.0},
    {"name": "Hostel Area", "lat": 26.4730, "lng": 73.1100, "radius": 300.0},
  ];

  String _getClosestLocation(double? lat, double? lng) {
    if (lat == null || lng == null) return "Unknown Area";

    String nearestName = "Unknown Area";
    double minDist = double.infinity;
    double nearestRadius = 150.0;

    // Quick inline Haversine
    double toRad(double val) => val * 3.141592653589793 / 180;

    for (var b in _buildings) {
      final double bLat = b['lat'];
      final double bLng = b['lng'];

      final dLat = toRad(bLat - lat);
      final dLon = toRad(bLng - lng);

      // We'll just do a very simple equirectangular approximation since distances are so small
      final x =
          dLon *
          3.141592653589793 /
          180 *
          6371000 *
          0.89; // Cosine of lat ~0.89 for 26 deg
      final y = dLat * 6371000;
      final distSq = x * x + y * y;

      if (distSq < minDist) {
        minDist = distSq;
        nearestName = b['name'];
        nearestRadius = (b['radius'] as num).toDouble();
      }
    }

    return minDist < (nearestRadius * nearestRadius)
        ? nearestName
        : "Off Campus";
  }

  @override
  Widget build(BuildContext context) {
    final telemetry = context.watch<TelemetryProvider>();
    final scoreService = context.watch<ScoreHistoryService>();
    final theme = Theme.of(context);

    // Dynamic color for focus score
    Color focusColor = Colors.greenAccent;
    if (scoreService.currentCAS < 50) {
      focusColor = Colors.redAccent;
    } else if (scoreService.currentCAS < 80) {
      focusColor = Colors.orangeAccent;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('FATE Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Analyse Right Now',
            onPressed: () {
              // Trigger manual fetch from server
              context.read<ScoreHistoryService>().triggerManualAnalysis();
              context.read<TelemetryProvider>().resetAppUsageStats();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Next Analysis Timer Warning / Tracker
                Card(
                  color: Colors.white10,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.timer,
                              color: Colors.blueAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Next Analysis in',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${(scoreService.secondsUntilNextAnalysis ~/ 60).toString().padLeft(2, '0')}:${(scoreService.secondsUntilNextAnalysis % 60).toString().padLeft(2, '0')}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Main Focus Score Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 32.0,
                      horizontal: 16.0,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Contextual Attention Score',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 150,
                              height: 150,
                              child: CircularProgressIndicator(
                                value: scoreService.currentCAS / 100,
                                strokeWidth: 12,
                                backgroundColor: Colors.white10,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  focusColor,
                                ),
                              ),
                            ),
                            Text(
                              scoreService.currentCAS.toStringAsFixed(0),
                              style: theme.textTheme.displayLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: focusColor,
                              ),
                            ),
                          ],
                        ),
                        if (scoreService.todaySnapshots.length > 1) ...[
                          const SizedBox(height: 32),
                          const Text(
                            'Trend (Last 10 Polls)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white54,
                            ),
                          ),
                          if (_getDeltaText(
                            scoreService.todaySnapshots,
                          ).isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              _getDeltaText(scoreService.todaySnapshots),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 16),
                          _buildScoreHistoryGraph(scoreService.todaySnapshots),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Context Intelligence Panel
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        context,
                        'Fragmentation',
                        '${(telemetry.fragmentationScore * 100).toStringAsFixed(0)}%',
                        Icons.broken_image_rounded,
                        Colors.orangeAccent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricCard(
                        context,
                        'Location',
                        _getClosestLocation(
                          telemetry.lastLat,
                          telemetry.lastLng,
                        ),
                        Icons.location_on_rounded,
                        Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Proximity Card
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: const Icon(
                      Icons.people_alt_rounded,
                      color: Colors.purpleAccent,
                      size: 32,
                    ),
                    title: const Text('Social Synergy'),
                    subtitle: Text(
                      '${telemetry.nearbyPeers} high-focus peers nearby',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SocialSynergyScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // App Activity Tracker (Toggleable)
                Padding(
                  padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'App Activity',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          const Text(
                            'Session',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white54,
                            ),
                          ),
                          Switch(
                            value: _showTotalDailyUsage,
                            onChanged: (val) {
                              setState(() {
                                _showTotalDailyUsage = val;
                              });
                              if (val) {
                                context
                                    .read<TelemetryProvider>()
                                    .fetchTotalDailyUsage();
                              }
                            },
                            activeColor: Colors.blueAccent,
                          ),
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!_showTotalDailyUsage && telemetry.appUsageStats.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No app usage logged since last poll.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  )
                else if (_showTotalDailyUsage &&
                    telemetry.totalDailyUsage.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Unable to retrieve total daily OS usage. You must grant the App Usage permission.',
                            style: TextStyle(color: Colors.white54),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.settings),
                            label: const Text('Grant Permission'),
                            onPressed: () {
                              telemetry.requestUsagePermission();
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...(_showTotalDailyUsage
                          ? telemetry.totalDailyUsage.entries.toList()
                          : telemetry.appUsageStats.entries.toList())
                      .map((entry) {
                        final minutes = entry.value ~/ 60;
                        final seconds = entry.value % 60;
                        final durationStr = minutes > 0
                            ? '${minutes}m ${seconds}s'
                            : '${seconds}s';
                        return Card(
                          color: Colors.white10,
                          child: ListTile(
                            leading: const Icon(
                              Icons.apps,
                              color: Colors.blueAccent,
                            ),
                            title: Text(
                              entry.key.split('.').last.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white54,
                              ),
                            ),
                            trailing: Text(
                              durationStr,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orangeAccent,
                              ),
                            ),
                          ),
                        );
                      }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDeltaText(List<Map<String, dynamic>> snapshots) {
    if (snapshots.length < 2) return '';
    // snapshots[0] is the newest, snapshots[1] is the previous one (they are ordered newest first in ScoreHistoryService normally if inserted at index 0, BUT WAIT: ScoreHistoryService appends via `add()`. So the NEWEST is at the END.)
    // Let's verify: In ScoreHistoryService, `_todaySnapshots.add(snapshot)` -> newest is at length-1.
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
      return '📈 Rose by ${diff.abs().toStringAsFixed(1)} (mainly due to better $mainFactor)';
    } else {
      return '📉 Dropped by ${diff.abs().toStringAsFixed(1)} (mainly due to $mainFactor)';
    }
  }

  Widget _buildScoreHistoryGraph(List<Map<String, dynamic>> snapshots) {
    if (snapshots.isEmpty) return const SizedBox.shrink();

    // The snapshots list limit is max 10.
    final spots = <FlSpot>[];
    for (int i = 0; i < snapshots.length; i++) {
      // x = chronological order (0 is oldest, length-1 is latest)
      // y = CAS score
      // We will just read the list. The list appends to the end, so order is oldest to newest.
      final cas = (snapshots[i]['CAS'] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), cas));
    }

    return AspectRatio(
      aspectRatio: 2.0,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
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
              color: Colors.greenAccent,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.greenAccent.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
