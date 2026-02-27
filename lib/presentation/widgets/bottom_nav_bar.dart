import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../screens/dashboard/attention_dashboard.dart';
import '../screens/timeline/activity_timeline.dart';
import '../screens/context/proximity_panel.dart';
import '../screens/insights/recommendation_panel.dart';
import '../screens/permissions/permission_control_screen.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({Key? key}) : super(key: key);

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const AttentionDashboard(),
    const ActivityTimeline(),
    const ProximityPanel(),
    const RecommendationPanel(),
    const PermissionControlScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.surfaceHighlight, width: 1)),
        ),
        child: BottomNavigationBar(
          backgroundColor: AppColors.surface,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Focus'),
            BottomNavigationBarItem(icon: Icon(Icons.timeline), label: 'Timeline'),
            BottomNavigationBarItem(icon: Icon(Icons.radar), label: 'Context'),
            BottomNavigationBarItem(icon: Icon(Icons.lightbulb), label: 'Insights'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
