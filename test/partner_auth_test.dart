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

    await tester.ensureVisible(find.text('Sign in').last);
    await tester.tap(find.text('Sign in').last);
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('Use at least 8 characters'), findsOneWidget);
    expect(api.loginCalls, 0);
  });

  testWidgets(
    'registration validates fields and visibility preserves password',
    (tester) async {
      final api = _FakeApi();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: AuthScreen(appState: AppState(api: api)),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.ensureVisible(
        find.textContaining('Create a customer account'),
      );
      await tester.tap(find.textContaining('Create a customer account'));
      await tester.pump(const Duration(seconds: 1));

      await tester.ensureVisible(find.text('Create my account'));
      await tester.tap(find.text('Create my account'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Enter your name'), findsOneWidget);
      expect(find.text('Enter a valid email'), findsOneWidget);
      expect(api.registerCalls, 0);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Sam Recycler');
      await tester.enterText(fields.at(1), 'not-an-email');
      await tester.ensureVisible(find.text('Create my account'));
      await tester.tap(find.text('Create my account'));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Enter a valid email'), findsOneWidget);
      expect(api.registerCalls, 0);
      await tester.enterText(fields.at(1), 'sam@example.com');
      await tester.ensureVisible(fields.at(2));
      await tester.enterText(fields.at(2), 'password123');
      await tester.pump(const Duration(seconds: 1));
      expect(
        (tester.widget<EditableText>(find.byType(EditableText).at(2)))
            .obscureText,
        isTrue,
      );

      await tester.ensureVisible(find.byTooltip('Show password'));
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump(const Duration(seconds: 1));
      expect(
        (tester.widget<EditableText>(find.byType(EditableText).at(2)))
            .obscureText,
        isFalse,
      );
      expect(find.text('password123'), findsOneWidget);
      expect(api.registerCalls, 0);
    },
  );

  testWidgets('valid registration uses existing app state auth flow', (
    tester,
  ) async {
    final api = _FakeApi();
    final state = AppState(api: api);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: AuthScreen(appState: state),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.ensureVisible(
      find.textContaining('Create a customer account'),
    );
    await tester.tap(find.textContaining('Create a customer account'));
    await tester.pump(const Duration(seconds: 1));

    final fields = find.byType(TextFormField);
    await tester.ensureVisible(fields.at(0));
    await tester.enterText(fields.at(0), 'Sam Recycler');
    await tester.ensureVisible(fields.at(1));
    await tester.enterText(fields.at(1), 'sam@example.com');
    await tester.ensureVisible(fields.at(2));
    await tester.enterText(fields.at(2), 'password123');
    await tester.ensureVisible(find.text('Create my account'));
    await tester.tap(find.text('Create my account'));
    await tester.pump(const Duration(seconds: 1));

    expect(api.registerCalls, 1);
    expect(api.registeredName, 'Sam Recycler');
    expect(api.registeredEmail, 'sam@example.com');
    expect(state.isAuthenticated, isTrue);
    expect(state.isPartner, isFalse);
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
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('No eligible requests right now'), findsOneWidget);
    await tester.tap(find.text('Assigned (0)'));
    await tester.pumpAndSettle();
    expect(find.text('No assigned requests yet'), findsOneWidget);
  });
}

class _FakeApi extends ReCircleApi {
  int loginCalls = 0;
  int registerCalls = 0;
  String? registeredName;
  String? registeredEmail;

  @override
  Future<dynamic> login(String email, String password) async {
    loginCalls++;
    throw const ApiException('Invalid test credentials');
  }

  @override
  Future<dynamic> register(String name, String email, String password) async {
    registerCalls++;
    registeredName = name;
    registeredEmail = email;
    return {
      'token': 'test-token',
      'user': {'role': 'customer', 'name': name, 'email': email},
    };
  }

  @override
  Future<void> saveToken(String token) async {}

  @override
  Future<dynamic> get(String path) async => <dynamic>[];
}
