import 'package:flutter/material.dart';

import 'dashboard/attention_dashboard.dart';
import 'dashboard/social_synergy_screen.dart';
import 'settings_screen.dart';
import 'theme.dart';
import 'timeline_screen.dart';

/// Four top-level destinations. Notifications and Data & Privacy are
/// secondary pages: the first opens from the Focus header, the second
/// from Settings.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  static const _screens = <Widget>[
    AttentionDashboard(),
    SocialSynergyScreen(),
    TimelineScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FateColors.bgDeep,
      // IndexedStack keeps each tab's scroll position and state.
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: FateColors.bgCard,
        indicatorColor: FateColors.primary.withAlpha(40),
        surfaceTintColor: Colors.transparent,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.center_focus_weak_outlined),
            selectedIcon: Icon(Icons.center_focus_strong_rounded),
            label: 'Focus',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'People',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_rounded),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Trends',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
