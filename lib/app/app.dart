import 'package:flutter/material.dart';

import '../providers/app_state.dart';
import '../screens/main_navigation_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/partner_dashboard_screen.dart';
import 'theme/app_theme.dart';

class ReCircleApp extends StatefulWidget {
  const ReCircleApp({super.key});

  @override
  State<ReCircleApp> createState() => _ReCircleAppState();
}

class _ReCircleAppState extends State<ReCircleApp> {
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    _appState.restoreSession();
  }

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ReCircle',
      theme: AppTheme.theme,
      home: ListenableBuilder(
        listenable: _appState,
        builder: (context, child) {
          if (!_appState.sessionReady) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (!_appState.isAuthenticated) {
            return AuthScreen(appState: _appState);
          }
          if (_appState.isPartner) {
            return PartnerDashboardScreen(appState: _appState);
          }
          return MainNavigationScreen(appState: _appState);
        },
      ),
    );
  }
}
