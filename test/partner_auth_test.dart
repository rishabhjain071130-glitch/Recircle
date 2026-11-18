import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recircle/features/requests/data/recircle_api.dart';
import 'package:recircle/providers/app_state.dart';
import 'package:recircle/screens/auth_screen.dart';
import 'package:recircle/screens/partner_application_screen.dart';
import 'package:recircle/screens/partner_dashboard_screen.dart';
import 'package:recircle/theme/app_theme.dart';

void main() {
  testWidgets(
    'partner application submits all required data and waits for approval',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = _PartnerApplicationApi();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: PartnerApplicationScreen(appState: AppState(api: api)),
        ),
      );

      const values = [
        'Casey Collector',
        'casey@example.test',
        '+911234567890',
        'safe-password-123',
        '42 Green Street',
        'Pune',
        '411001',
        'Pune and nearby areas',
      ];
      for (var i = 0; i < values.length - 1; i++) {
        final input = find.byKey(
          ValueKey(
            'partner-application-${['name', 'email', 'phone', 'password', 'address', 'city', 'pinCode', 'serviceArea'][i]}',
          ),
        );
        await tester.scrollUntilVisible(
          input,
          -300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.enterText(input, values[i]);
      }
      const serviceArea = ValueKey('partner-application-serviceArea');
      final lastInput = find.byKey(serviceArea);
      await tester.scrollUntilVisible(
        lastInput,
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(lastInput, values.last);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Submit application'),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Submit application'));
      await tester.pumpAndSettle();

      expect(api.path, '/auth/partner-register');
      expect(api.body?['city'], 'Pune');
      expect(api.body?['pinCode'], '411001');
      expect(find.text('Application submitted'), findsOneWidget);
      expect(
        find.textContaining('pending administrator review'),
        findsOneWidget,
      );
    },
  );

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

class _PartnerApplicationApi extends ReCircleApi {
  String? path;
  Map<String, dynamic>? body;

  @override
  Future<dynamic> post(
    String requestPath, [
    Map<String, dynamic>? requestBody,
  ]) async {
    path = requestPath;
    body = requestBody;
    return const {};
  }
}
