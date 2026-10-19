import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recircle/features/requests/data/recircle_api.dart';
import 'package:recircle/providers/app_state.dart';
import 'package:recircle/screens/auth_screen.dart';
import 'package:recircle/screens/partner_dashboard_screen.dart';
import 'package:recircle/theme/app_theme.dart';

void main() {
  testWidgets('sign-in form validates credentials before sending a request', (
    tester,
  ) async {
    final api = _FakeApi();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: AuthScreen(appState: AppState(api: api)),
      ),
    );

    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('Use at least 8 characters'), findsOneWidget);
    expect(api.loginCalls, 0);
  });

  testWidgets('partner dashboard shows retry-safe empty request states', (
    tester,
  ) async {
    final state = AppState(api: _FakeApi());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: PartnerDashboardScreen(appState: state),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No eligible requests right now'), findsOneWidget);
    await tester.tap(find.text('Assigned (0)'));
    await tester.pumpAndSettle();
    expect(find.text('No assigned requests yet'), findsOneWidget);
  });
}

class _FakeApi extends ReCircleApi {
  int loginCalls = 0;

  @override
  Future<dynamic> login(String email, String password) async {
    loginCalls++;
    throw const ApiException('Invalid test credentials');
  }

  @override
  Future<dynamic> get(String path) async => <dynamic>[];
}
