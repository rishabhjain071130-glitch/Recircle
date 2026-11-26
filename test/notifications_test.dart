import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recircle/features/requests/data/recircle_api.dart';
import 'package:recircle/models/app_notification.dart';
import 'package:recircle/providers/app_state.dart';
import 'package:recircle/screens/notifications_screen.dart';
import 'package:recircle/theme/app_theme.dart';

void main() {
  test('notification JSON parsing handles optional fields and request IDs', () {
    final notification = AppNotification.fromJson({
      '_id': 'n-1',
      'type': 'pickup_accepted',
      'title': 'Pickup accepted',
      'message': 'A partner accepted your request.',
      'relatedRequestId': 'pickup-1',
      'createdAt': '2026-11-26T08:30:00.000Z',
    });

    expect(notification.id, 'n-1');
    expect(notification.relatedPickupId, 'pickup-1');
    expect(notification.isRead, isFalse);
    expect(notification.createdAt, isNotNull);
    final sparse = AppNotification.fromJson({});
    expect(sparse.id, isEmpty);
    expect(sparse.relatedPickupId, isNull);
    expect(sparse.createdAt, isNull);
  });

  testWidgets('renders unread notices and marks one read when tapped', (
    tester,
  ) async {
    final api = _NotificationApi(items: [_notice()]);
    final state = _state(api);
    await tester.pumpWidget(_app(state));
    await tester.pumpAndSettle();

    expect(find.text('Pickup accepted'), findsOneWidget);
    expect(
      find.text('A partner accepted your pickup request.'),
      findsOneWidget,
    );
    expect(state.unreadNotificationCount, 1);
    expect(find.text('Mark all read'), findsOneWidget);
    final tile = tester.widget<Material>(
      find
          .ancestor(
            of: find.text('A partner accepted your pickup request.'),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(tile.color, AppTheme.accentLightGreen);

    await tester.tap(find.text('Pickup accepted'));
    await tester.pumpAndSettle();
    expect(api.markedIds, ['notice-1']);
    expect(state.unreadNotificationCount, 0);
  });

  testWidgets('mark all read clears the unread badge count', (tester) async {
    final state = _state(_NotificationApi(items: [_notice()]));
    await tester.pumpWidget(_app(state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mark all read'));
    await tester.pumpAndSettle();
    expect(state.unreadNotificationCount, 0);
    expect(state.notifications.single.isRead, isTrue);
  });

  testWidgets(
    'related pickup notification opens the existing tracking screen',
    (tester) async {
      final api = _NotificationApi(items: [_notice()]);
      final state = _state(api);
      await tester.pumpWidget(_app(state));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pickup accepted'));
      await tester.pumpAndSettle();

      expect(api.requestedPickupIds, ['pickup-1']);
      expect(find.text('Request #pickup-1'), findsOneWidget);
      expect(find.text('Tracking Timeline'), findsOneWidget);
    },
  );

  testWidgets('shows an empty state when the account has no notices', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_state(_NotificationApi(items: []))));
    await tester.pumpAndSettle();
    expect(find.text('You’re all caught up'), findsOneWidget);
  });

  testWidgets('shows loading and error states', (tester) async {
    final pending = Completer<dynamic>();
    final loadingApi = _NotificationApi(pending: pending);
    await tester.pumpWidget(_app(_state(loadingApi)));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pending.completeError(
      const ApiException('Notification service unavailable'),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Notification service unavailable'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}

MaterialApp _app(AppState state) => MaterialApp(
  theme: AppTheme.theme,
  home: NotificationsScreen(appState: state),
);

AppState _state(_NotificationApi api) =>
    AppState(api: api)..currentRole = 'customer';

AppNotification _notice() => const AppNotification(
  id: 'notice-1',
  type: 'pickup_accepted',
  title: 'Pickup accepted',
  message: 'A partner accepted your pickup request.',
  relatedPickupId: 'pickup-1',
  isRead: false,
  createdAt: null,
);

Map<String, dynamic> _pickupJson() => {
  '_id': 'pickup-1',
  'item': {'name': 'Laptop', 'category': 'E-Waste', 'condition': 'Used'},
  'pickup': {'address': '12 Green Street'},
  'status': 'Accepted',
  'createdAt': '2026-11-26T08:00:00.000Z',
  'history': [
    {'to': 'Submitted', 'at': '2026-11-26T08:00:00.000Z', 'note': ''},
    {'to': 'Accepted', 'at': '2026-11-26T08:05:00.000Z', 'note': ''},
  ],
};

class _NotificationApi extends ReCircleApi {
  _NotificationApi({this.items = const [], this.pending});

  final List<AppNotification> items;
  final Completer<dynamic>? pending;
  final List<String> markedIds = [];
  final List<String> requestedPickupIds = [];

  @override
  Future<dynamic> getNotifications({int page = 1, int limit = 50}) {
    if (pending != null) return pending!.future;
    return Future.value({
      'items': items
          .map(
            (notification) => {
              'id': notification.id,
              'type': notification.type,
              'title': notification.title,
              'message': notification.message,
              'relatedPickupId': notification.relatedPickupId,
              'isRead': notification.isRead,
              'createdAt': notification.createdAt?.toIso8601String(),
            },
          )
          .toList(),
      'unreadCount': items.where((notification) => !notification.isRead).length,
    });
  }

  @override
  Future<dynamic> markNotificationRead(String id) async {
    markedIds.add(id);
    return {'isRead': true};
  }

  @override
  Future<dynamic> markAllNotificationsRead() async => {'modifiedCount': 1};

  @override
  Future<dynamic> getRequest(String id) async {
    requestedPickupIds.add(id);
    return _pickupJson();
  }

  @override
  Future<dynamic> get(String path) async =>
      throw StateError('Unexpected GET $path');
}
