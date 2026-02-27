import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/telemetry_provider.dart';

class SocialSynergyScreen extends StatelessWidget {
  const SocialSynergyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final telemetry = context.watch<TelemetryProvider>();
    final peers = telemetry.connectedPeers;

    return Scaffold(
      appBar: AppBar(title: const Text('Social Synergy')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero section
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.people_alt_rounded,
                      size: 64,
                      color: Colors.purpleAccent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${telemetry.nearbyPeers}',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'High-Focus Peers Nearby',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Connected Devices List
            Text(
              'Discovered Devices',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: peers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bluetooth_searching,
                            size: 48,
                            color: Colors.white54,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Scanning for FATE users...',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: peers.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.purpleAccent.withAlpha(
                                50,
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.purpleAccent,
                              ),
                            ),
                            title: Text(
                              peers[index],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: const Text('Status: Syncing Context'),
                            trailing: const Icon(
                              Icons.wifi_tethering,
                              color: Colors.greenAccent,
                            ),
                          ),
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
