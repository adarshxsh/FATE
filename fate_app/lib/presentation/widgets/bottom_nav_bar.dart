import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../screens/dashboard/attention_dashboard.dart';
import '../screens/timeline/timeline_screen.dart';
import '../screens/context/proximity_panel.dart';
import '../screens/insights/recommendation_panel.dart';
import '../screens/permissions/permission_control_screen.dart';
import 'log_overlay.dart';
import 'package:google_fonts/google_fonts.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({Key? key}) : super(key: key);

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;
  bool _showLogs = false;
  
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
      body: Stack(
        children: [
          _screens[_currentIndex],
          if (_showLogs)
            const Positioned(
              top: 100,
              left: 20,
              child: LogOverlay(),
            ),
          // Top Left Log Toggle
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () => setState(() => _showLogs = !_showLogs),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    border: Border.all(
                      color: _showLogs ? AppColors.primary : AppColors.gridLines,
                      width: 1,
                    ),
                    boxShadow: _showLogs ? [
                      BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10)
                    ] : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.terminal,
                        color: _showLogs ? AppColors.primary : AppColors.textMuted,
                        size: 16,
                      ),
                      if (_showLogs) ...[
                        const SizedBox(width: 8),
                        Text(
                          'LOGS_ACTIVE',
                          style: GoogleFonts.firaCode(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(bottom: 12),
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.gridLines, width: 1)),
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
