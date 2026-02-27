import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../screens/dashboard/attention_dashboard.dart';
import '../screens/timeline/timeline_screen.dart';
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
    const TimelineScreen(),
    const ProximityPanel(),
    const RecommendationPanel(),
    const PermissionControlScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(bottom: 12),
        decoration: const BoxDecoration(
          color: Color(0xFF0F1110),
          border: Border(top: BorderSide(color: Color(0xFF1A2220), width: 1)),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          currentIndex: _currentIndex,
          selectedLabelStyle: GoogleFonts.rajdhani(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
          unselectedLabelStyle: GoogleFonts.rajdhani(fontSize: 10, letterSpacing: 1),
          onTap: (index) => setState(() => _currentIndex = index),
          items: [
            _buildNavItem(Icons.computer, 'FOCUS', 0),
            _buildNavItem(Icons.bar_chart, 'TIMELINE', 1),
            _buildNavItem(Icons.radar, 'CONTEXT', 2),
            _buildNavItem(Icons.smart_toy, 'INSIGHTS', 3),
            _buildNavItem(Icons.admin_panel_settings, 'PROTOCOLS', 4),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = _currentIndex == index;
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.only(top: 8),
        child: Icon(
          icon,
          shadows: isSelected ? [const Shadow(color: AppColors.primary, blurRadius: 10)] : null,
        ),
      ),
      label: label,
    );
  }
}
