import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app/router.dart';
import '../providers/app_state.dart';
import '../features/scan/data/image_capture_service.dart';
import 'ai_screen.dart';
import 'analysis_history_screen.dart';
import 'home_screen.dart';
import 'impact_screen.dart';
import 'pickups_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final AppState appState;
  final ImageCaptureService? imageCaptureService;

  const MainNavigationScreen({
    super.key,
    required this.appState,
    this.imageCaptureService,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = AppTab.home.index;
  String? _aiActionMode;
  late final ImageCaptureService _imageCaptureService =
      widget.imageCaptureService ?? PlatformImageCaptureService();
  XFile? _recoveredImage;
  String? _recoveryError;

  @override
  void initState() {
    super.initState();
    _restoreLostImage();
  }

  Future<void> _restoreLostImage() async {
    try {
      final image = await _imageCaptureService.retrieveLostImage();
      if (!mounted || image == null) return;
      setState(() {
        _recoveredImage = image;
        _recoveryError = null;
        _currentIndex = AppTab.scan.index;
      });
    } on ImageSelectionException catch (error) {
      if (!mounted) return;
      setState(() {
        _recoveredImage = null;
        _recoveryError = error.message;
        _currentIndex = AppTab.scan.index;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recoveredImage = null;
        _recoveryError = 'The interrupted image could not be restored. Please choose it again.';
        _currentIndex = AppTab.scan.index;
      });
    }
  }

  void _navigateToTab(int index, {String? actionMode}) {
    setState(() {
      _currentIndex = index;
      _aiActionMode = actionMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(appState: widget.appState, onNavigateToTab: _navigateToTab),
      AIScreen(
        appState: widget.appState,
        initialActionMode: _aiActionMode,
        imageCaptureService: _imageCaptureService,
        initialImage: _recoveredImage,
        initialError: _recoveryError,
      ),
      PickupsScreen(appState: widget.appState),
      ImpactScreen(appState: widget.appState),
      AnalysisHistoryScreen(appState: widget.appState),
      ProfileScreen(appState: widget.appState),
    ];

    return PopScope(
      canPop: _currentIndex == AppTab.home.index,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != AppTab.home.index) {
          setState(() {
            _currentIndex = AppTab.home.index;
            _aiActionMode = null;
          });
        }
      },
      child: Scaffold(
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
                color: Colors.black.withValues(alpha: 0.06),
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
                label: 'Scan',
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
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: 'History',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
