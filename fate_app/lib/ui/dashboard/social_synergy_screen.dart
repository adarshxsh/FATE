import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/telemetry_provider.dart';

class SocialSynergyScreen extends StatelessWidget {
  const SocialSynergyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final telemetry = context.watch<TelemetryProvider>();
    final devices = telemetry.nearbyDevicesMap;
    final distances = telemetry.peerDistances;

    return Scaffold(
      appBar: AppBar(title: const Text('Social Synergy')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Hero Card — compact
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  const Icon(
                    Icons.people_alt_rounded,
                    size: 48,
                    color: Colors.purpleAccent,
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${telemetry.nearbyPeers} Peers Nearby',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${telemetry.closeFriends.length} excluded from scoring',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Info text
          Text(
            'Discovered Users',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'High-focus peers at 1-2m improve your attention score.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 12),

          // Peer List
          if (devices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  const Icon(
                    Icons.bluetooth_searching,
                    size: 48,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Scanning for FATE users...',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            )
          else
            ...devices.entries.map((entry) {
              final endpointId = entry.key;
              final peerName = entry.value;
              final isExcluded = telemetry.isFriend(endpointId);
              final distance = distances[endpointId] ?? 5.0;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: distance < 2.0
                      ? BorderSide(
                          color: Colors.purpleAccent.withOpacity(0.5),
                          width: 1.5,
                        )
                      : BorderSide.none,
                ),
                child: SwitchListTile(
                  secondary: CircleAvatar(
                    backgroundColor: isExcluded
                        ? Colors.grey.withAlpha(40)
                        : Colors.purpleAccent.withAlpha(50),
                    child: Icon(
                      isExcluded ? Icons.person_off : Icons.person,
                      color: isExcluded ? Colors.grey : Colors.purpleAccent,
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        peerName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (distance < 2.0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purpleAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'CLOSE',
                            style: TextStyle(
                              color: Colors.purpleAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    'Approx. ${distance.toStringAsFixed(1)}m · ${isExcluded ? "Excluded" : "Active"}',
                    style: TextStyle(
                      color: isExcluded ? Colors.grey : Colors.greenAccent,
                      fontSize: 12,
                    ),
                  ),
                  value: !isExcluded, // ON = counts, OFF = excluded
                  activeColor: Colors.greenAccent,
                  onChanged: (countThisPeer) {
                    if (countThisPeer) {
                      telemetry.removeFriend(endpointId);
                    } else {
                      telemetry.addFriend(endpointId);
                    }
                  },
                ),
              );
            }),
        ],
      ),
    );
  }
}
