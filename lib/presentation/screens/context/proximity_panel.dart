import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../state/dashboard_bloc.dart';

class ProximityPanel extends StatelessWidget {
  const ProximityPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Context Intelligence'), backgroundColor: AppColors.background, elevation: 0),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          final contextData = state.context;
          return ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              _buildContextCard(
                title: 'Current Location Geofence',
                value: contextData.locationTag,
                icon: Icons.location_on,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              _buildContextCard(
                title: 'Social Synergy',
                value: '${contextData.peerCount} Peers Nearby',
                icon: Icons.bluetooth_connected,
                color: AppColors.secondary,
              ),
              const SizedBox(height: 32),
              const Text('Nearby FATE Devices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (contextData.nearbyPeers.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('No peers detected in Bluetooth range.', style: TextStyle(color: AppColors.textSecondary))))
              else
                ...contextData.nearbyPeers.map((peerMac) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: AppColors.secondary),
                      const SizedBox(width: 16),
                      Text('Device: ${peerMac.substring(0, 8)}...', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      const Text('~2m', style: TextStyle(color: AppColors.primary)),
                    ],
                  ),
                )).toList()
            ],
          );
        },
      ),
    );
  }

  Widget _buildContextCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.surfaceHighlight)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
