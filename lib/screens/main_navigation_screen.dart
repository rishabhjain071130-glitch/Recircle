import 'package:flutter/material.dart';
import '../providers/app_state.dart';
import 'ai_screen.dart';
import 'home_screen.dart';
import 'impact_screen.dart';
import 'pickups_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final AppState appState;

  const MainNavigationScreen({
    super.key,
    required this.appState,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  String? _aiActionMode;

  void _navigateToTab(int index, {String? actionMode}) {
    setState(() {
      _currentIndex = index;
      _aiActionMode = actionMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        appState: widget.appState,
        onNavigateToTab: _navigateToTab,
      ),
      AIScreen(
        appState: widget.appState,
        initialActionMode: _aiActionMode,
      ),
      PickupsScreen(
        appState: widget.appState,
      ),
      ImpactScreen(
        appState: widget.appState,
      ),
      ProfileScreen(
        appState: widget.appState,
      ),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: IndexedStack(
          key: ValueKey<int>(_currentIndex),
          index: _currentIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _currentIndex = index;
              _aiActionMode = null;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome),
              label: 'AI Assistant',
            ),
            NavigationDestination(
              icon: Icon(Icons.local_shipping_outlined),
              selectedIcon: Icon(Icons.local_shipping),
              label: 'Pickups',
            ),
            NavigationDestination(
              icon: Icon(Icons.eco_outlined),
              selectedIcon: Icon(Icons.eco),
              label: 'Impact',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
