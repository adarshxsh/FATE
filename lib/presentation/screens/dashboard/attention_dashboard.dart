import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../state/dashboard_bloc.dart';

class AttentionDashboard extends StatelessWidget {
  const AttentionDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Live Attention State', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 32),
                  Center(child: _FocusRing(casScore: state.metrics.currentCAS)),
                  const SizedBox(height: 48),
                  Row(
                    children: [
                      Expanded(child: _MetricCard(title: 'Context Switches', value: state.metrics.contextSwitches.toString(), icon: Icons.swap_horiz, color: AppColors.secondary)),
                      const SizedBox(width: 16),
                      Expanded(child: _MetricCard(title: 'Notif. Burst Rate', value: state.metrics.notificationBurstRate.toString(), icon: Icons.notifications_active, color: AppColors.tertiary)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.surfaceHighlight)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Dominant Application', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                        const SizedBox(height: 8),
                        Text(state.metrics.dominantApp, style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FocusRing extends StatelessWidget {
  final double casScore;
  const _FocusRing({Key? key, required this.casScore}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(casScore / 200), blurRadius: 40, spreadRadius: 10),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 250,
            height: 250,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: casScore / 100),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return CircularProgressIndicator(
                  value: value,
                  strokeWidth: 12,
                  backgroundColor: AppColors.surfaceHighlight,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color.lerp(AppColors.tertiary, AppColors.primary, value)!,
                  ),
                );
              },
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(casScore.toInt().toString(), style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const Text('CAS SCORE', style: TextStyle(fontSize: 14, letterSpacing: 2, color: AppColors.textSecondary)),
            ],
          )
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({Key? key, required this.title, required this.value, required this.icon, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.surfaceHighlight)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
