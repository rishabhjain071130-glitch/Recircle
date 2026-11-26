import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:recircle/features/requests/data/recircle_api.dart';
import 'package:recircle/models/pickup.dart';
import 'package:recircle/providers/app_state.dart';
import 'package:recircle/screens/pickup_tracking_screen.dart';

void main() {
  testWidgets(
    'cancellation confirmation updates the pickup and removes the action',
    (tester) async {
      var cancelCalls = 0;
      final api = ReCircleApi(
        client: MockClient((request) async {
          if (request.url.path.endsWith('/cancel')) {
            cancelCalls++;
            final response = _pickupJson('Cancelled');
            (response['data'] as Map<String, dynamic>)['history'] = [
              {
                'from': null,
                'to': 'Submitted',
                'note': '',
                'at': '2026-11-26T12:00:00Z',
              },
              {
                'from': 'Submitted',
                'to': 'Cancelled',
                'note': 'Plans changed',
                'at': '2026-11-26T12:01:00Z',
              },
            ];
            return http.Response(jsonEncode(response), 200, request: request);
          }
          if (request.url.path.endsWith('/notifications')) {
            return http.Response(
              '{"success":true,"data":{"items":[],"unreadCount":0}}',
              200,
              request: request,
            );
          }
          return http.Response('{}', 404, request: request);
        }),
      );
      final state = AppState(api: api)..currentRole = 'customer';
      await tester.pumpWidget(
        MaterialApp(
          home: PickupTrackingScreen(
            pickup: _pickup(PickupStatus.booked),
            appState: state,
          ),
        ),
      );

      expect(find.text('Cancel Pickup'), findsOneWidget);
      await tester.tap(find.text('Cancel Pickup'));
      await tester.pumpAndSettle();
      expect(find.text('Cancel this pickup?'), findsOneWidget);
      expect(find.text('Keep Pickup'), findsOneWidget);
      await tester.tap(find.text('Cancel Pickup').last);
      await tester.pumpAndSettle();

      expect(cancelCalls, 1);
      expect(state.pickups.single.status, PickupStatus.cancelled);
      expect(find.text('Cancelled'), findsNWidgets(2));
      expect(find.text('Cancel Pickup'), findsNothing);
    },
  );

  testWidgets(
    'cancellation action is hidden once pickup is collected or later',
    (tester) async {
      for (final status in [
        PickupStatus.collected,
        PickupStatus.processing,
        PickupStatus.completed,
        PickupStatus.cancelled,
      ]) {
        final state = AppState();
        await tester.pumpWidget(
          MaterialApp(
            home: PickupTrackingScreen(
              pickup: _pickup(status),
              appState: state,
            ),
          ),
        );
        expect(find.text('Cancel Pickup'), findsNothing, reason: status.name);
      }
    },
  );
}

Pickup _pickup(PickupStatus status) => Pickup(
  id: 'pickup-1',
  itemName: 'Old laptop',
  category: 'E-Waste',
  quantity: '1',
  pickupAddress: '12 Green Street',
  preferredDate: 'Tomorrow',
  preferredTime: 'Morning',
  status: status,
  createdAt: DateTime.utc(2026, 11, 26),
);

Map<String, dynamic> _pickupJson(String status) => {
  'success': true,
  'data': {
    '_id': 'pickup-1',
    'status': status,
    'createdAt': '2026-11-26T12:00:00Z',
    'item': {
      'name': 'Old laptop',
      'category': 'E-Waste',
      'condition': 'Used',
      'quantity': 1,
    },
    'pickup': {
      'address': '12 Green Street',
      'contactName': 'Customer',
      'contactPhone': '1234567890',
    },
    'history': [],
  },
};
