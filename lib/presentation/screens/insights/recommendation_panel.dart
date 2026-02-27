import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class RecommendationPanel extends StatelessWidget {
  const RecommendationPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Heuristic Insights'), backgroundColor: AppColors.background, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildInsightCard(
            type: 'CRITICAL',
            title: 'Distraction Loop Detected',
            description: 'You have switched between Instagram and WhatsApp 14 times in the last 10 minutes. Put the phone in DND mode to break the loop.',
            color: AppColors.error,
            icon: Icons.warning_amber_rounded,
          ),
          const SizedBox(height: 16),
          _buildInsightCard(
            type: 'SYNERGY',
            title: 'High Focus Environment',
            description: 'You are in the IITJ Library with 3 peers. Your collective CAS is averaging 88%. This is a peak productivity window.',
            color: AppColors.primary,
            icon: Icons.group_work,
          ),
          const SizedBox(height: 16),
          _buildInsightCard(
            type: 'OPTIMIZATION',
            title: 'Notification Penalty',
            description: 'Social notifications are reducing your focus score by 20%. Consider muting "com.whatsapp" during academic hours.',
            color: AppColors.warning,
            icon: Icons.notifications_off,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({required String type, required String title, required String description, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 20, spreadRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(type, style: TextStyle(color: color, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
        ],
      ),
    );
  }
}
