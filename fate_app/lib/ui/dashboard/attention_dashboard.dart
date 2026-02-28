import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/telemetry_provider.dart';
import '../../logic/score_history_service.dart';
import 'social_synergy_screen.dart';

class AttentionDashboard extends StatelessWidget {
  const AttentionDashboard({super.key});

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
                        telemetry.currentContext,
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

                // Recent App Activity Tracker
                const Padding(
                  padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
                  child: Text(
                    'Recent App Activity',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                if (telemetry.appUsageStats.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No app usage logged since last poll.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  )
                else
                  ...telemetry.appUsageStats.entries.map((entry) {
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
                          style: const TextStyle(fontWeight: FontWeight.w500),
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
