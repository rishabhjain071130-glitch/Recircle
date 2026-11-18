import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recircle/features/requests/data/recircle_api.dart';
import 'package:recircle/providers/app_state.dart';
import 'package:recircle/screens/admin_dashboard_screen.dart';
import 'package:recircle/theme/app_theme.dart';

void main() {
  testWidgets(
    'admin dashboard loads totals and allows audited partner status updates',
    (tester) async {
      final api = _AdminApi();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.theme,
          home: AdminDashboardScreen(appState: AppState(api: api)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Admin Dashboard'), findsOneWidget);
      expect(find.text('Customers: 4'), findsOneWidget);
      await tester.tap(find.text('Partners'));
      await tester.pumpAndSettle();
      expect(find.text('Pending Partner'), findsOneWidget);
      await tester.tap(find.byTooltip('Change partner status'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();
      expect(api.patchedPath, '/admin/partners/partner-1/status');
      expect(api.patchedBody, {'status': 'approved'});

      await tester.tap(find.text('Market rates'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Admin-managed indicative rates · not guaranteed live market prices.',
        ),
        findsOneWidget,
      );
    },
  );
}

class _AdminApi extends ReCircleApi {
  String? patchedPath;
  Map<String, dynamic>? patchedBody;

  @override
  Future<dynamic> get(String path) async => switch (path) {
    '/admin/dashboard/stats' => {
      'customers': 4,
      'partners': 1,
      'pendingPartners': 1,
      'pickups': 3,
      'completedPickups': 1,
    },
    '/admin/partners' => [
      {
        '_id': 'partner-1',
        'name': 'Pending Partner',
        'email': 'partner@example.test',
        'partnerStatus': 'pending',
      },
    ],
    '/admin/customers?page=1&limit=50' => {'items': []},
    '/admin/pickups?page=1&limit=50' => {'items': []},
    '/admin/market-rates?page=1&limit=50' => {'items': []},
    _ => throw ApiException('Unexpected GET $path'),
  };

  @override
  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    patchedPath = path;
    patchedBody = body;
    return const {};
  }
}
