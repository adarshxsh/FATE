import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/telemetry_provider.dart';

class AttentionDashboard extends StatelessWidget {
  const AttentionDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final telemetry = context.watch<TelemetryProvider>();
    final theme = Theme.of(context);

    // Dynamic color for focus score
    Color focusColor = Colors.greenAccent;
    if (telemetry.focusScore < 50)
      focusColor = Colors.redAccent;
    else if (telemetry.focusScore < 80)
      focusColor = Colors.orangeAccent;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FATE Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Simulated update for UI testing
              context.read<TelemetryProvider>().updateMetrics(
                0.35,
                85.0,
                "Library",
                2,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                        'Cumulative Attention Score',
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
                              value: telemetry.focusScore / 100,
                              strokeWidth: 12,
                              backgroundColor: Colors.white10,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                focusColor,
                              ),
                            ),
                          ),
                          Text(
                            telemetry.focusScore.toStringAsFixed(0),
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
                ),
              ),
            ],
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
