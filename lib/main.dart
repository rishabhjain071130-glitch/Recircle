import 'package:flutter/material.dart';
import 'providers/app_state.dart';
import 'screens/main_navigation_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ReCircleApp());
}

class ReCircleApp extends StatefulWidget {
  const ReCircleApp({super.key});

  @override
  State<ReCircleApp> createState() => _ReCircleAppState();
}

class _ReCircleAppState extends State<ReCircleApp> {
  final AppState _appState = AppState();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appState,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ReCircle',
          theme: AppTheme.theme,
          home: MainNavigationScreen(appState: _appState),
        );
      },
    );
  }
}
