import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/channels/native_telemetry_bridge.dart';
import '../../state/auth_bloc.dart';

class PermissionControlScreen extends StatelessWidget {
  const PermissionControlScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final NativeTelemetryBridge bridge = NativeTelemetryBridge();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Telemetry Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            onPressed: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildPermissionTile(
            title: 'Usage Access',
            subtitle: 'Required to track context switching.',
            icon: Icons.app_settings_alt,
            onTap: () => bridge.requestUsagePermissions(),
          ),
          const SizedBox(height: 16),
          _buildPermissionTile(
            title: 'Notification Listener',
            subtitle: 'Required to measure interruption severity.',
            icon: Icons.notifications_active,
            onTap: () => bridge.requestNotificationPermissions(),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile({required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary))),
        trailing: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.background),
          child: const Text('Grant'),
        ),
      ),
    );
  }
}
